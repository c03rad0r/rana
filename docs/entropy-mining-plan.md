# PR Plan: Entropy-based npub mining for rana

- **Branch**: `feat/entropy-mining`, based off clean `upstream/main` (`bb4d6b8`, v0.5.5).
- **Goal**: Add an opt-in mode that mines for *low-entropy* npubs instead of named/vanity npubs, giving holders an asymmetric anti-impersonation advantage (see Motivation).
- **Mode semantics**: opt-in, mutually exclusive with difficulty/vanity, bech32-only, continuous best-so-far.

## Motivation (the "why")

Vanity npubs (e.g. `npub1rana…`) are forgeable: an attacker can mine a look-alike
prefix at the same cost the original holder paid. This is the **Zucos triangle**
problem — the vanity property is symmetric, so it provides no lasting identity
guarantee.

Mining for a *target entropy* instead flips this into an **asymmetric** defense:

- The holder picks npubs with unusually low Shannon entropy (high character
  repetition / visual order) in the bech32 data portion.
- An attacker can reproduce the *property* "low entropy" at similar cost, but the
  residual randomness in the bech32 encoding forces the resulting npub to look
  recognisably *different* from the original.
- Pattern-imitation is not identity-imitation. The holder keeps a visual edge.

## Architecture decisions (locked)

| Decision | Choice | Rationale |
|---|---|---|
| Mode combination | Mutually exclusive with `--difficulty`/`--vanity`/`-n`/`-s` | Matches existing `check_args()` convention; smallest review surface. Combinability can be a follow-up. |
| Entropy base | bech32 npub only (data portion, strips `npub1`) | Directly matches the visual-recognition motivation. Function is generic over `&str` so hex is a trivial add later. |
| Match behavior | Continuous; track lowest-entropy-seen; emit milestones ≤ threshold | Mirrors existing vanity "near matches" UX (PR #50). User Ctrl+C's at preferred result. |
| Branch base | Clean `upstream/main` | PR contains only entropy commits; keeps local vanity-service work (`faa1dbc`, `0d4ed76`) out. |
| Test depth | Unit tests only, colocated in `src/entropy.rs` | Zero new `[dev-dependencies]`; runs under existing `cargo test --verbose` CI step. |

## Change list

### 1. `src/entropy.rs` (new)

Core math + tests in one place (avoids the existing `calculate_string_similarity`
duplication smell present in both `main.rs` and `utils.rs`).

- `pub fn shannon_entropy(s: &str) -> f64` — stack `[usize; 256]` histogram,
  single `log2` pass, `#[inline]`, no heap allocations.
- `pub fn npub_entropy(npub_bech32: &str) -> f64` — strips `npub1`, delegates to
  `shannon_entropy`. Returns entropy of the visual data portion.
- `#[cfg(test)] mod tests` — 9 cases (see Testing).

### 2. `src/lib.rs`

Register `pub mod entropy;`.

### 3. `src/cli.rs`

- New field on `CLIArgs`:
  `#[arg(short = 'e', long = "entropy-threshold")] pub entropy_threshold: Option<f64>`.
- `check_args()`: add entropy to the mutual-exclusion `requirements_count`
  counter; validate range `[0.0, 5.0]` (bech32 alphabet cap = `log2(32)`).

### 4. `src/main.rs`

- Extend `BestMatch` with `entropy: f64` (init `f64::MAX`) to track lowest-seen.
- Thread an `Arc<Option<f64>>` threshold into each worker.
- Insert a 4th `else if let Some(threshold)` branch: compute `npub_entropy`,
  update best-so-far under the mutex, emit a milestone (divider + entropy value +
  `print_keys`) when `h <= threshold`, set `is_valid_pubkey = true`.
- Startup message chain gains an entropy arm.
- Skip `benchmark_cores` for entropy mode (same as vanity — `2^pow` estimate
  doesn't apply).

### 5. `README.md`

- Document `-e, --entropy-threshold <FLOAT>` in the options block.
- Add an "Entropy mining" subsection with the Zucos-triangle motivation.
- Add example: `cargo run --release -- --entropy-threshold=3.0`.
- Update the "cannot specify difficulty and a vanity prefix at the same time"
  note to list entropy as a fourth exclusive mode.

## Testing strategy

**Unit tests only, no new dependencies.** Colocated in `src/entropy.rs` under
`#[cfg(test)]`. Executed by the existing CI step `cargo test --verbose`
(`.github/workflows/rust.yml`). No Python/pytest — this is a pure-Rust crate.

| Case | Input | Expected |
|---|---|---|
| empty input | `""` | `0.0` |
| single repeated char | `"aaaa"` | `0.0` |
| two distinct chars | `"ab"` | `1.0` |
| four distinct chars | `"abcd"` | `2.0` |
| bech32 alphabet cap (32 chars) | `"qpzry9x8gf2tvdw0s3jn54khce6mua7l"` | `5.0` |
| npub prefix stripping | `npub1aaa…` | `< 1.0` |
| bounded for any input | several | `0.0 ≤ h ≤ 5.0` |
| repetition lowers entropy | `"aab"` vs `"abc"` | monotonic |
| symmetry | `"abba"` vs `"baab"` | equal |

## Performance framing

- secp256k1 keypair generation (~µs) dominates the loop.
- Shannon entropy over 59 bytes is ~200ns (stack histogram, no allocs).
- **Existing modes: zero cost** — the new `else if` branch is never taken when
  `-e` is absent; the CPU branch predictor handles it for free.
- **Entropy mode itself: ~10-20% slower** than pure difficulty — disclosed
  honestly in the PR body, not hidden.

## Pre-PR verification

1. `cargo fmt --all && cargo clippy --all-targets -- -D warnings`
2. `cargo test --verbose` — existing `cli_tests` + 9 new entropy tests pass.
3. `cargo build --release`
4. Smoke: `./target/release/rana -e 4.0` (fast milestones),
   `-e 2.0` (slow), `-e 3.0 -d 10` (panic: mutual exclusion).
5. `git diff upstream/main...HEAD` contains only the 5 changes above.

## Risks / out-of-scope

- `f64::MAX` init for `BestMatch.entropy` — print path must tolerate "no match yet".
- The `calculate_string_similarity` duplication in `main.rs:18` / `utils.rs:64`
  is pre-existing and **not** refactored here (keeps diff focused).
- No `benches/` infrastructure — performance claims are manual measurements,
  not automated benches. Offer formal benches as a follow-up.

---

## Checklist

- [x] Create this planning document
- [x] Create `feat/entropy-mining` branch off clean `upstream/main`
- [x] Implement `src/entropy.rs` (`shannon_entropy` + `npub_entropy` + unit tests)
- [x] Register `pub mod entropy;` in `src/lib.rs` (also centralised `BECH32_PREFIX`)
- [x] Add `--entropy-threshold` CLI arg + update `check_args` in `src/cli.rs`
- [x] Wire entropy branch into mining loop in `src/main.rs`
      (BestMatch field + thread loop + milestone printing + benchmark skip)
- [x] Update `README.md` (`-e` flag, entropy section, example, mutual-exclusion note)
- [x] `cargo fmt --all` (new/changed files clean; pre-existing `utils.rs:69`
      trailing-whitespace left untouched as out of scope)
- [x] `cargo clippy --all-targets` (no new warnings; 3 pre-existing warnings
      unchanged — `regex_creation_in_loops`, `module_inception`, `manual_range_contains`)
- [x] `cargo test --verbose` — 11 passed (9 new entropy + 1 existing cli + 1 bin)
- [x] `cargo build --release`
- [x] Smoke test binary:
      `-e 4.5` → progressive milestones (4.49→3.99 bits/char) ✓
      `-e 3.0 -d 10` → mutual-exclusion panic ✓
      `-e 9.0` → range-validation panic ✓
      `--entropy-threshold=-1.0` → range-validation panic ✓
      `-d 10` → no regression ✓
- [x] Verify diff scoped to: `README.md`, `src/cli.rs`, `src/lib.rs`, `src/main.rs`
      (modified) + `src/entropy.rs`, `docs/entropy-mining-plan.md` (new).
      `src/utils.rs` reverted (only had auto-fmt whitespace, out of scope).

## Remaining before opening the PR (manual)

- [ ] Write the PR body (motivation, non-breaking claim, performance notes)
- [ ] Optional: capture a keys/sec comparison table for the PR description
- [ ] Commit + push the branch and open the PR against `grunch/rana`

