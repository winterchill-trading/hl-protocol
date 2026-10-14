# test/ (AGENTS.md)

Expect tests (ppx_expect), property tests (Base_quickcheck) and the captured fixtures in
`test/fixtures/`.

Run from the repository root with
`opam exec --switch 5.2.0+ox -- dune build --root .. @hl-protocol/runtest`.

Rules that matter here:

- Fixtures are captures from the public API, trimmed. Name a new fixture directory with its
  capture date.
- Promote expect output with `dune promote` only after reading each diff. A changed
  expectation in a codec test is usually a wire change, not a formatting change.
- Mainnet coverage claims in `README.md` must match the fixtures this directory holds.
