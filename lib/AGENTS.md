# lib/ (AGENTS.md)

The `hl_protocol` library: one module per Hyperliquid message family (primitives, exchange
endpoint, info endpoint, stats host, websocket messages) and their JSON codecs. About 100
files; every module has an `.mli`.

Build from the repository root with
`opam exec --switch 5.2.0+ox -- dune build --root .. @hl-protocol/all`.

Rules that matter here:

- Write the `.mli` first when you add a message type, then its codec, then a test.
- Each new field or constructor needs a test that decodes a sample and re-encodes it to
  the same JSON. Use a captured frame from `test/fixtures` when one exists.
- Encodings that are not obvious get a comment saying what and why. Examples: sides are
  `"B"` and `"A"`, client order ids are `0x` plus 32 hex digits.
- Read the pitfalls in the root `AGENTS.md` before deriving a codec.
