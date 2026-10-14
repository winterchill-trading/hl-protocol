# .github/ (AGENTS.md)

`workflows/ci.yml` builds and tests this repository with the shared `ox-setup` action and
calls the `obj-magic` reusable workflow from `infra`.

Rules that matter here:

- The sibling pins (`fixed-decimal`, then `exchange-core`) must match the org dependencies
  in `dune-project`. When `dune-project` gains an org dependency, add its pin in the same
  commit.
- Keep the `concurrency` block: a new push cancels the older run on the same ref.
- Check a run with one `gh run list --limit 1`, and at most one `gh run watch <id> --exit-status`.
