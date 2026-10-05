# SDD ledger — plan: docs/superpowers/plans/2026-09-21-monkey-c-skill.md

Pre-flight: Task 1 expected-pages contract feeds Tasks 2, 3, 5, and 7; names and page-count interfaces are consistent.
Pre-flight: Task 2 routing files feed Tasks 5 and 7; filenames and fallback behavior are consistent.
Pre-flight: Task 3 sync/validation interfaces feed Tasks 4 and 7; cache path and manifest schema are consistent.
Pre-flight: Task 4 installer feeds Task 7; parameter names and installation marker are consistent.
Pre-flight: Task 5 showcase files feed Tasks 6 and 7; README sections, SVG accessibility, and evidence blocks are consistent.
Pre-flight: Task 6 CI consumes the Task 1 repository suite; offline/network boundary is consistent.
Pre-flight: Task 7 verified branch feeds Task 8 publication; public path and GitHub owner are consistent.
Task 1: Ruling: page-path uniqueness is scoped per source family, not global — Monkey C and Core Topics both require an empty root path but write to separate cache directories — cost if wrong: duplicate detection could miss a collision inside one source family.
Task 1: Ruling: installed Superpowers package has `task-brief` but no `task-done`; record completion manually after the named full test command — preserves the ledger contract — cost if wrong: no automatic capture of full test output.
Task 1: complete (commits ae48114..84d1a19, tests: pwsh -NoProfile -File tests/validate-repository.ps1 → 127 assertions pass)
Task 2: complete (commits 84d1a19..4343045, tests: repository contracts → 143 assertions pass; quick_validate.py → Skill is valid)
Task 3: Ruling: cache validation checks links only within the current approved source family — rejected navigation outside a family remains an external link and must not invalidate an otherwise complete cache — cost if wrong: an upstream cross-family relative navigation link may not work offline.
Task 3: Ruling: add `-ExpectedPages` to the synchronizer for deterministic fixture testing — production defaults remain the checked-in manifest — cost if wrong: callers could validate against an incomplete custom manifest.
Task 3: Ruling: idempotency compares cached content and manifest file hashes but excludes `generatedAt` — refresh time is intentionally volatile — cost if wrong: timestamp-only differences are not treated as content instability.
Task 3: complete (commits 4343045..566e142, tests: fixture 8 assertions; live cache 391 files/384 HTML/0 missing/0 broken/0 duplicate; repository 143 assertions)
Task 4: Ruling: packaged installations resolve `scripts/expected-pages.json` first, with the source-tree tests manifest as fallback — keeps clean installs self-contained without copying tests — cost if wrong: future manifest updates must update both source and packaged installer copy.
Task 4: complete (commits 566e142..7c492ba, tests: pwsh -NoProfile -File tests/validate-repository.ps1 → 155 assertions pass)
Task 5: complete (showcase docs, governance placeholders, and accessible SVG diagrams; tests: pwsh -NoProfile -File tests/validate-repository.ps1 → 202 assertions pass)
Task 6: complete (read-only Windows CI workflow and governance guidance; tests: pwsh -NoProfile -File tests/validate-repository.ps1 → 206 assertions pass)
Task 7: complete (four forward-validation scenarios documented and exercised through local routing contracts; tests: repository 208 assertions, sync fixture 8 assertions)
