# Rana 🐸

![Rana](rana.png)

Mine public keys that can be used with nostr.

This is based on [nip13](https://github.com/nostr-protocol/nips/blob/master/13.md) example.

Provide the desired difficulty or the vanity prefix as arguments. See below.

## Requirements:

0. You need Rust version 1.64 or higher to compile.

## Install

Using Cargo to install (requires ~/.cargo/bin to be in PATH)

```bash
cargo install rana
```

### Compile and execute it:

To compile on Ubuntu/Pop!\_OS/Debian, please install [cargo](https://www.rust-lang.org/tools/install), then run the following commands:

```bash
sudo apt update
sudo apt install -y cmake build-essential
```

Then clone the repo, build and run:

```bash
git clone https://github.com/grunch/rana.git
cd rana
cargo run --release
```

By default it will generate a public key with a difficulty of `10` but you can customize its difficulty or vanity prefix with the proper parameters.

Usage:

```
Options:
  -d, --difficulty <DIFFICULTY>
          Enter the number of starting bits that should be 0. [default: 10]
  -v, --vanity <VANITY_PREFIX>
          Enter the prefix your public key should have when expressed
          as hexadecimal.
  -n, --vanity-n-prefix <VANITY_NPUB_PREFIXES_RAW_INPUT>
          Enter the prefix your public key should have when expressed
          in npub format (Bech32 encoding). Specify multiple vanity
          targets as a comma-separated list.
  -s, --vanity-n-suffix <VANITY_NPUB_SUFFIXES_RAW_INPUT>
          Enter the suffix your public key should have when expressed
          in npub format (Bech32 encoding). Specify multiple vanity
          targets as a comma-separated list.
  -e, --entropy-threshold <ENTROPY_THRESHOLD>
          Mine for low-entropy npubs instead of a named vanity prefix.
          Accepts the maximum Shannon entropy (bits/char) of the bech32
          data portion; lower values are more ordered/repetitive. Range
          0.0-5.0. Mutually exclusive with difficulty/vanity options.
  -c, --cores <NUM_CORES>
          Number of processor cores to use
  -r, --restore <MNEMONIC_PHRASE>
          Restore from mnemonic to public private key
  -g, --generate <WORD_COUNT>
          Word count of mnemonic to be generated. Should be either 12,18 or 24
  -p, --passphrase <WORD_COUNT>
          Passphrase used for restoring mnemonic to keypair
  -q, --qr
          Print QR code of the private key
  -w, --verbose_output
          Print verbose ouput of non-matching public keys
```

Examples:

```bash
cargo run --release -- --difficulty=20

# Vanity only accepts hexadecimal values. DEAD corresponds to https://www.hexdictionary.com/hex/DEAD, not an example username string.
cargo run --release -- --vanity=dead

cargo run --release -- --vanity-n-prefix=rana

cargo run --release -- --vanity-n-prefix=rana,h0dl,n0strfan

cargo run --release -- -n=rana,h0dl,n0strfan

cargo run --release -- --vanity-n-suffix=ranaend

# You can combine prefix and suffix
cargo run --release -- -n=rana,h0dl,n0strfan -s theend,end

# Mine for a low-entropy npub (Shannon entropy <= 3.0 bits/char)
cargo run --release -- --entropy-threshold=3.0

# Generate key pair with 12 words mnemonic
cargo run --release -- -g 12

# Restore key pair from mnemonic. Use quotes and separate each word with a space
cargo run --release -- -r "congress evoke onion donate fantasy soccer project fiction envelope body faith mean"
```

If you have it installed with `cargo install`:

```bash
rana --difficulty=20

rana --vanity=dead

rana --vanity-n-prefix=rana

rana -n=rana,h0dl,n0strfan

rana -n=rana,h0dl,n0strfan -s theend,end

rana --entropy-threshold=3.0
```

Keep in mind that you cannot specify a difficulty and a vanity prefix at the same time.
Entropy threshold (`-e`/`--entropy-threshold`) is a fourth, mutually exclusive mode: pick
exactly one of difficulty, hex vanity, npub vanity, or entropy threshold.
Also, the more requirements you have, the longer it will take to reach a satisfactory public key.

### Entropy mining

Classic vanity npubs (e.g. `npub1rana…`) are forgeable: an attacker can mine a
look-alike prefix at the same cost the original holder paid (the *Zucos triangle*
problem). The vanity property is symmetric, so it provides no lasting identity
guarantee.

`--entropy-threshold` flips this into an **asymmetric** defense. Instead of a
target name, rana mines for a target **Shannon entropy** in the npub's bech32
data portion:

- The holder picks npubs with unusually low entropy (high character repetition /
  visual order).
- An attacker can reproduce the *property* "low entropy" at similar cost, but the
  residual randomness in the bech32 encoding forces the forged npub to look
  recognisably *different* from the original.
- Pattern-imitation is not identity-imitation: the holder keeps a visual edge.

The threshold is expressed in bits/char and must be within `[0.0, 5.0]` (the
bech32 alphabet has 32 symbols, so `log2(32) == 5.0` is the theoretical maximum).
Lower thresholds are more ordered and harder to find. Rana runs continuously and
prints a milestone whenever it finds a new best that meets the threshold; stop it
with `Ctrl+C` once you are happy with a result.

```bash
# Easy: ~4.0 bits/char is found quickly
cargo run --release -- -e 4.0

# Harder: 2.5 bits/char is highly repetitive and takes noticeably longer
cargo run --release -- -e 2.5
```

### Searching for multiple vanity targets at once

Specifying multiple `vanity-n-*` targets allows you to leverage the work you've already done to generate each new `npub` candidate. Searching a candidate `npub` for additional targets is incredibly fast because it's just a trivial string compare.

Statistically speaking, searching for `rana,h0dl` should take half the time that searching for `rana` and then doing a second, separate search for `hodl` would take.
