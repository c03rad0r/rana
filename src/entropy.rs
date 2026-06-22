//! Shannon entropy helpers for the entropy-mining mode.
//!
//! Mining for low-entropy npubs (instead of named vanity prefixes) gives the
//! holder an asymmetric anti-impersonation advantage: an attacker can reproduce
//! the *property* of low entropy, but the residual randomness forces the forged
//! npub to look recognisably different. See `docs/entropy-mining-plan.md`.

/// Compute the Shannon entropy (in bits per character) of an arbitrary string.
///
/// Uses a fixed stack `[usize; 256]` histogram — no heap allocations — so it is
/// cheap to call inside the hot mining loop. The `log2` pass touches at most 256
/// buckets regardless of input length.
#[inline]
pub fn shannon_entropy(s: &str) -> f64 {
    if s.is_empty() {
        return 0.0;
    }

    let mut counts = [0usize; 256];
    let mut len = 0usize;
    for &byte in s.as_bytes() {
        counts[byte as usize] += 1;
        len += 1;
    }

    let n = len as f64;
    let mut entropy = 0.0;
    for &count in counts.iter() {
        if count > 0 {
            let p = count as f64 / n;
            entropy -= p * p.log2();
        }
    }
    entropy
}

/// Compute the Shannon entropy of the **data portion** of a bech32 npub.
///
/// The `npub1` human-readable prefix is constant across every key and therefore
/// contributes zero discriminative entropy while biasing the histogram. We strip
/// it so the result reflects only the visually variable part of the npub — which
/// is exactly what the Zucos-triangle recognisability argument relies on.
///
/// For a 59-character bech32 data portion drawn from the 32-symbol alphabet, the
/// entropy ranges over `[0.0, 5.0]` (`log2(32) == 5.0`).
#[inline]
pub fn npub_entropy(npub_bech32: &str) -> f64 {
    let data = npub_bech32
        .strip_prefix(super::BECH32_PREFIX)
        .unwrap_or(npub_bech32);
    shannon_entropy(data)
}

#[cfg(test)]
mod tests {
    use super::*;

    const EPS: f64 = 1e-9;

    #[test]
    fn empty_is_zero() {
        assert_eq!(shannon_entropy(""), 0.0);
    }

    #[test]
    fn single_repeated_char_is_zero() {
        assert_eq!(shannon_entropy("aaaa"), 0.0);
    }

    #[test]
    fn two_distinct_chars() {
        // H = -(1/2 log2 1/2)*2 = 1.0
        assert!((shannon_entropy("ab") - 1.0).abs() < EPS);
    }

    #[test]
    fn four_distinct_chars() {
        // H = 2.0
        assert!((shannon_entropy("abcd") - 2.0).abs() < EPS);
    }

    #[test]
    fn bech32_alphabet_caps_at_five() {
        // All 32 distinct bech32 symbols once → log2(32) == 5.0
        assert!((shannon_entropy("qpzry9x8gf2tvdw0s3jn54khce6mua7l") - 5.0).abs() < EPS);
    }

    #[test]
    fn npub_strips_prefix() {
        // Highly repetitive data portion → low entropy regardless of "npub1".
        let h = npub_entropy("npub1aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa");
        assert!(h < 1.0, "expected < 1.0, got {h}");
    }

    #[test]
    fn npub_entropy_without_prefix_uses_full_string() {
        // If the prefix is absent we fall back to the whole string.
        assert!((npub_entropy("abcd") - 2.0).abs() < EPS);
    }

    #[test]
    fn bounded_for_any_input() {
        for s in [
            "",
            "a",
            "ab",
            "abc",
            "abcd",
            "qpzry9x8gf2tvdw0s3jn54khce6mua7l",
            "npub1qqqq",
        ] {
            let h = shannon_entropy(s);
            assert!((0.0..=5.0 + EPS).contains(&h), "{s:?} → {h} out of [0, 5]");
        }
    }

    #[test]
    fn repetition_lowers_entropy() {
        assert!(shannon_entropy("aab") < shannon_entropy("abc"));
        assert!(shannon_entropy("aaab") < shannon_entropy("aabc"));
    }

    #[test]
    fn symmetric_in_arg_order() {
        assert!((shannon_entropy("abba") - shannon_entropy("baab")).abs() < EPS);
    }
}
