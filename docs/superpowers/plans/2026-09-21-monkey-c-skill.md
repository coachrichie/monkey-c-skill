# Monkey C Skill GitHub Showcase Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build and publicly publish a tested `monkey-c` Codex skill and GitHub showcase that generates a local, untracked Garmin documentation cache.

**Architecture:** Keep original skill guidance, routing indexes, tests, and showcase documentation in Git. A transactional PowerShell synchronizer downloads Garmin pages into `references/.generated/`, validates the staged cache, and replaces the prior cache only after success. A separate installer copies tracked skill files into a Codex skills directory without overwriting unrelated installations.

**Tech Stack:** Markdown, YAML, PowerShell 7+, JSON, SVG, GitHub Actions, GitHub CLI

**Spec:** `docs/superpowers/specs/2026-09-21-monkey-c-skill-design.md`

## Global Constraints

- Repository name: `monkey-c-skill`; skill identifier: `monkey-c`; display name: `Monkey C`.
- Public Git history must contain no Garmin-authored downloaded pages, assets, PDFs, SDK files, or logos.
- Generated documentation belongs only in ignored `references/.generated/`.
- Approved download prefixes are `https://developer.garmin.com/connect-iq/monkey-c/`, `https://developer.garmin.com/connect-iq/core-topics/`, and `https://developer.garmin.com/connect-iq/api-docs/`.
- Original repository content uses MIT; Garmin materials remain governed by Garmin's terms.
- The README is the showcase surface; GitHub Pages and marketplace publication are out of scope.
- PowerShell commands must work on Windows PowerShell 7+ without third-party modules.
- Development is test-first; each behavior test must be observed failing before its implementation is added.

## Review Focus

- A redirected or discovered URL outside the approved Garmin prefixes must be rejected and never written.
- A failed or incomplete synchronization must leave the previous valid cache byte-for-byte intact.
- Paths containing `..`, encoded traversal, query strings, or fragments must not escape or duplicate cache targets.
- Installation over an unrelated existing `monkey-c` directory must fail without changing that directory.
- A clean clone with no generated cache must remain a valid skill and explain how to generate local references.

---

## File map

- `SKILL.md`: compact runtime routing instructions.
- `agents/openai.yaml`: display metadata only.
- `references/*.md`: original topic maps and fallback URLs.
- `scripts/sync-docs.ps1`: download orchestration and atomic cache replacement.
- `scripts/validate-docs.ps1`: cache manifest, link, duplicate, and coverage validation.
- `scripts/install.ps1`: safe local installation/update.
- `tests/TestHelpers.ps1`: dependency-free assertions and fixtures.
- `tests/expected-pages.json`: authoritative page seeds and titles.
- `tests/validate-repository.ps1`: offline repository and installer tests.
- `tests/validate-sync.ps1`: local HTTP fixture tests for the synchronizer.
- `README.md` and `docs/*.md`: showcase, user, maintainer, legal, and case-study documentation.
- `assets/*.svg`: original accessible diagrams.
- `.github/workflows/validate.yml`: offline pull-request validation.

### Task 1: Lock the public-content and source-coverage contracts

**Files:**
- Create: `.gitignore`
- Create: `tests/TestHelpers.ps1`
- Create: `tests/expected-pages.json`
- Create: `tests/validate-repository.ps1`

**Interfaces:**
- Produces: `Assert-True([bool]$Condition, [string]$Message)` and `Assert-Equal($Expected, $Actual, [string]$Message)`.
- Produces: JSON groups `monkeyC`, `coreTopics`, and `apiDocs`, each containing `baseUrl` and unique `pages` entries with `path`, `title`, and `keywords`.

- [ ] **Step 1: Write failing repository-contract tests**

Create the assertion helpers and tests that require `.gitignore` to ignore `references/.generated/`, require the three source groups, require 9 Monkey C paths and 45 Core Topics paths, reject duplicate paths, and fail if `git ls-files` contains the generated directory:

```powershell
. "$PSScriptRoot/TestHelpers.ps1"
$root = Split-Path $PSScriptRoot -Parent
$ignore = Get-Content (Join-Path $root '.gitignore') -Raw
Assert-True ($ignore -match '(?m)^references/\.generated/$') 'generated Garmin cache must be ignored'
$expected = Get-Content (Join-Path $PSScriptRoot 'expected-pages.json') -Raw | ConvertFrom-Json
Assert-Equal 9 @($expected.monkeyC.pages).Count 'Monkey C page count'
Assert-Equal 45 @($expected.coreTopics.pages).Count 'Core Topics page count'
$paths = @($expected.monkeyC.pages.path) + @($expected.coreTopics.pages.path)
Assert-Equal $paths.Count @($paths | Sort-Object -Unique).Count 'source paths must be unique'
$tracked = @(git -C $root ls-files 'references/.generated/**')
Assert-Equal 0 $tracked.Count 'generated Garmin files must not be tracked'
```

- [ ] **Step 2: Run the test and verify RED**

Run: `pwsh -NoProfile -File tests/validate-repository.ps1`

Expected: FAIL because `.gitignore` and `expected-pages.json` do not exist.

- [ ] **Step 3: Add the minimal contracts**

Create `.gitignore` with `references/.generated/`, `.staging-*`, and common editor/OS noise. Populate `expected-pages.json` from the live index paths recorded in the design research: root plus eight Monkey C child pages, root plus forty-four Core Topics child pages, and the three API index seeds `index.html`, `class_list.html`, and `method_list.html`. Use original one-line titles and routing keywords; do not copy page prose.

Implement helpers as:

```powershell
function Assert-True([bool]$Condition, [string]$Message) {
    if (-not $Condition) { throw "ASSERT TRUE FAILED: $Message" }
}
function Assert-Equal($Expected, $Actual, [string]$Message) {
    if ($Expected -ne $Actual) { throw "ASSERT EQUAL FAILED: $Message; expected=$Expected actual=$Actual" }
}
```

- [ ] **Step 4: Run the test and verify GREEN**

Run: `pwsh -NoProfile -File tests/validate-repository.ps1`

Expected: PASS with `Repository contracts passed`.

- [ ] **Step 5: Commit**

```powershell
git add .gitignore tests
git commit -m "test: define Garmin source and public-content contracts"
```

### Task 2: Create the valid, progressively disclosed skill

**Files:**
- Create: `SKILL.md`
- Create: `agents/openai.yaml`
- Create: `references/index.md`
- Create: `references/monkey-c-topics.md`
- Create: `references/core-topics.md`
- Create: `references/api-routing.md`
- Modify: `tests/validate-repository.ps1`

**Interfaces:**
- Produces: automatic skill `monkey-c` with display name `Monkey C`.
- Consumes: `tests/expected-pages.json` to generate or check every routing row.

- [ ] **Step 1: Extend the test with failing skill assertions**

Require valid frontmatter, a description beginning `Use when`, matching UI metadata, all three routing references, official fallback URLs, and useful behavior when `.generated` is absent:

```powershell
$skill = Get-Content (Join-Path $root 'SKILL.md') -Raw
Assert-True ($skill -match '(?ms)^---\s*name:\s*monkey-c\s*description:\s*Use when') 'valid skill identity'
foreach ($reference in 'monkey-c-topics.md','core-topics.md','api-routing.md') {
    Assert-True ($skill -match [regex]::Escape($reference)) "SKILL routes to $reference"
}
Assert-True ($skill -match 'If the generated cache is absent') 'clean-clone fallback is explicit'
```

- [ ] **Step 2: Run and verify RED**

Run: `pwsh -NoProfile -File tests/validate-repository.ps1`

Expected: FAIL because `SKILL.md` is missing.

- [ ] **Step 3: Write the minimal skill and indexes**

Keep `SKILL.md` under 500 words. Route syntax/language questions to `monkey-c-topics.md`, platform questions to `core-topics.md`, and symbol/API-level/device questions to `api-routing.md`. Tell the agent to search generated references first, cite the exact source page, and use the official URL when the cache is absent. `agents/openai.yaml` must contain:

```yaml
interface:
  display_name: "Monkey C"
  short_description: "Build and debug Garmin Connect IQ apps with source-grounded Monkey C guidance"
  default_prompt: "Use $monkey-c to help with this Garmin Connect IQ or Monkey C task."
```

Generate each checked-in topic table from `expected-pages.json` with columns Topic, Use when, Local path, and Official source.

- [ ] **Step 4: Validate GREEN**

Run both:

```powershell
pwsh -NoProfile -File tests/validate-repository.ps1
python "$env:CODEX_HOME/skills/.system/skill-creator/scripts/quick_validate.py" .
```

Expected: repository tests PASS and `Skill is valid!`.

- [ ] **Step 5: Commit**

```powershell
git add SKILL.md agents references tests/validate-repository.ps1
git commit -m "feat: add Monkey C skill and reference routing"
```

### Task 3: Implement transactional documentation synchronization

**Files:**
- Create: `scripts/sync-docs.ps1`
- Create: `scripts/validate-docs.ps1`
- Create: `tests/validate-sync.ps1`

**Interfaces:**
- `sync-docs.ps1 [-Destination <string>] [-BaseUrlMap <hashtable>] [-SkipApiDocs]` returns a summary object and exits non-zero on failure.
- `validate-docs.ps1 -CacheRoot <string> -ExpectedPages <string>` returns a validation summary and exits non-zero for missing pages, broken local targets, unexpected duplicate hashes, or out-of-root paths.
- Manifest schema: `{ generatedAt, sources[], files[{sourceUrl,path,sha256,bytes}] }`.

- [ ] **Step 1: Write failing synchronizer tests with a local HTTP fixture**

Use `System.Net.HttpListener` on an ephemeral localhost port to serve: a valid index and child page, an outside-prefix link, a `../escape` link, duplicate fragments, and a forced 500 response. Assert that only allowed pages are staged, traversal is rejected, and a sentinel in the prior cache survives the 500 response.

```powershell
$sentinel = Join-Path $cache 'sentinel.txt'
Set-Content $sentinel 'keep-me'
& $sync -Destination $cache -BaseUrlMap $fixtureMap
Assert-True (Test-Path (Join-Path $cache 'monkey-c/index.html')) 'valid page downloaded'
Assert-True (-not (Test-Path (Join-Path $temp 'escape'))) 'traversal did not escape cache'
$fixture.FailNext = $true
try { & $sync -Destination $cache -BaseUrlMap $fixtureMap; throw 'expected sync failure' } catch {}
Assert-Equal 'keep-me' (Get-Content $sentinel -Raw).Trim() 'failed sync preserved cache'
```

- [ ] **Step 2: Run and verify RED**

Run: `pwsh -NoProfile -File tests/validate-sync.ps1`

Expected: FAIL because the synchronization scripts are missing.

- [ ] **Step 3: Implement the minimal transactional synchronizer**

Use `System.Net.Http.HttpClient`, a queue, a case-insensitive hash set, and URI resolution. Map every approved URL to a canonical relative path, strip query/fragment components, reject any URL whose host or prefix is not allow-listed, and verify the resolved filesystem target starts with the staging root. Download to `references/.staging-<guid>`, call `validate-docs.ps1`, rename the old cache to a backup, rename staging to `.generated`, then remove the backup. On any exception, remove staging and keep the old cache.

- [ ] **Step 4: Implement cache validation**

Parse every HTML `href` and `src`; resolve local targets; verify expected pages from JSON; group SHA-256 hashes; allow identical content only when the manifest records the same canonical source URL. Emit counts for files, HTML pages, bytes, broken links, duplicates, and missing expected pages.

- [ ] **Step 5: Run tests and a real synchronization**

```powershell
pwsh -NoProfile -File tests/validate-sync.ps1
pwsh -NoProfile -File scripts/sync-docs.ps1
pwsh -NoProfile -File scripts/validate-docs.ps1 -CacheRoot references/.generated -ExpectedPages tests/expected-pages.json
```

Expected: fixture tests PASS; real synchronization reports zero broken links, duplicates, and missing expected pages.

- [ ] **Step 6: Verify idempotency and Git exclusion**

Hash all generated files, synchronize again, hash again, and require zero differences. Run `git status --short` and require no generated paths.

- [ ] **Step 7: Commit**

```powershell
git add scripts tests
git commit -m "feat: add validated local Garmin documentation sync"
```

### Task 4: Add safe installation and update behavior

**Files:**
- Create: `scripts/install.ps1`
- Modify: `tests/validate-repository.ps1`

**Interfaces:**
- `install.ps1 [-CodexHome <string>] [-Sync] [-Force]` installs to `<CodexHome>/skills/monkey-c`.
- Installation marker: `.monkey-c-skill-install.json` with repository URL and schema version `1`.

- [ ] **Step 1: Add failing temporary-home tests**

Test clean install, refusal over an unmarked directory, forced update over a marked installation, omission of `.git`, tests, specs, and `.generated`, plus preservation of a target's generated cache during update.

- [ ] **Step 2: Run and verify RED**

Run: `pwsh -NoProfile -File tests/validate-repository.ps1`

Expected: FAIL because `scripts/install.ps1` is missing.

- [ ] **Step 3: Implement minimal installer**

Resolve `CodexHome` from the parameter, then `$env:CODEX_HOME`, then `$HOME/.codex`. Copy only `SKILL.md`, `agents`, `references/*.md`, and runtime scripts. Refuse an existing unmarked destination. With `-Force`, replace tracked installation files but preserve `references/.generated`. With `-Sync`, invoke the installed synchronizer only after a successful install.

- [ ] **Step 4: Run and verify GREEN**

Run: `pwsh -NoProfile -File tests/validate-repository.ps1`

Expected: PASS including clean-install and safe-update cases.

- [ ] **Step 5: Commit**

```powershell
git add scripts/install.ps1 tests/validate-repository.ps1
git commit -m "feat: add safe Monkey C skill installer"
```

### Task 5: Build the “Built with AI, for AI” showcase

**Files:**
- Create: `README.md`
- Create: `assets/architecture.svg`
- Create: `assets/workflow.svg`
- Create: `docs/installation.md`
- Create: `docs/usage.md`
- Create: `docs/case-study.md`
- Create: `docs/ai-workflow.md`
- Create: `docs/reference-routing.md`
- Create: `docs/maintenance.md`
- Create: `docs/troubleshooting.md`
- Create: `docs/legal.md`
- Modify: `tests/validate-repository.ps1`

**Interfaces:**
- README sections appear in this order: hero, live value, architecture, creation timeline, evidence, try it, learn from it.
- SVGs contain `<title>` and `<desc>` and use no Garmin logos.

- [ ] **Step 1: Add failing showcase tests**

Require every document and diagram, verify every relative Markdown link resolves, require `<title>`/`<desc>` in SVGs, require three representative prompts, and require the exact disclosure concepts “AI assisted” and “owner selected the goals.”

- [ ] **Step 2: Run and verify RED**

Run: `pwsh -NoProfile -File tests/validate-repository.ps1`

Expected: FAIL because the showcase files are missing.

- [ ] **Step 3: Write the showcase README and diagrams**

Lead with `# Monkey C — Built with AI, for AI`. Demonstrate one language prompt, one Core Topics prompt, and one Toybox API prompt. Use Mermaid-free original SVGs so GitHub renders deterministically. Report only measured evidence from the final test output; use a generated `<!-- validation-summary:start/end -->` block so numbers cannot drift.

- [ ] **Step 4: Write the detailed documentation**

Document installation/update/uninstall, generated cache behavior, prompt examples, routing logic, maintenance and refresh, common failures, legal boundary, non-affiliation, AI/human responsibility, the chronological case study, and a reusable source-grounded skill-authoring recipe. Link the approved spec and plan as inspectable process evidence.

- [ ] **Step 5: Run and verify GREEN**

Run: `pwsh -NoProfile -File tests/validate-repository.ps1`

Expected: PASS with zero broken Markdown links or accessibility failures.

- [ ] **Step 6: Commit**

```powershell
git add README.md assets docs tests/validate-repository.ps1
git commit -m "docs: create AI-built skill showcase"
```

### Task 6: Add governance, license, and continuous integration

**Files:**
- Create: `CONTRIBUTING.md`
- Create: `SECURITY.md`
- Create: `LICENSE`
- Create: `.github/workflows/validate.yml`
- Modify: `tests/validate-repository.ps1`

**Interfaces:**
- CI runs the offline repository suite on `windows-latest` for pushes and pull requests.
- Scheduled/network synchronization is not part of required pull-request status.

- [ ] **Step 1: Add failing governance and workflow tests**

Require an MIT license naming Richard Haimerl, a private security-reporting instruction, contributor test commands, a Windows workflow, least-privilege `contents: read`, and no required network sync step.

- [ ] **Step 2: Run and verify RED**

Run: `pwsh -NoProfile -File tests/validate-repository.ps1`

Expected: FAIL because governance files are absent.

- [ ] **Step 3: Add minimal governance and CI files**

The workflow checks out the repository and runs `pwsh -NoProfile -File tests/validate-repository.ps1`. The license covers original content only; `docs/legal.md` explains the Garmin exclusion. CONTRIBUTING documents focused commits, test-first changes, source-index updates, and the prohibition on committing generated Garmin material.

- [ ] **Step 4: Run full offline validation**

```powershell
pwsh -NoProfile -File tests/validate-repository.ps1
git diff --check
git status --short
```

Expected: PASS, no whitespace errors, and only intended files staged/untracked.

- [ ] **Step 5: Commit**

```powershell
git add CONTRIBUTING.md SECURITY.md LICENSE .github tests/validate-repository.ps1 docs/legal.md
git commit -m "chore: add project governance and CI"
```

### Task 7: Forward-test the skill and finalize measured evidence

**Files:**
- Modify: `README.md`
- Modify: `docs/case-study.md`
- Create: `tests/forward-test.md`

**Interfaces:**
- Forward-test scenarios: Monkey C type/syntax retrieval, Core Topics manifest/permission guidance, Toybox API availability lookup, and clean-clone fallback.

- [ ] **Step 1: Record baseline retrieval failures without the skill**

Run the four scenarios in isolated fresh contexts without loading `monkey-c`. Record whether the response identifies the correct source and provides a verifiable citation. Do not score writing style.

- [ ] **Step 2: Run the same scenarios with the skill**

Install into a temporary Codex home, synchronize references, invoke `$monkey-c`, and record source selection, local retrieval, and citation correctness. A passing scenario selects the right reference family and cites the exact official page.

- [ ] **Step 3: Correct only demonstrated routing gaps**

If a scenario fails, update the smallest applicable topic index or `SKILL.md` route, re-run the failing scenario, then re-run all four.

- [ ] **Step 4: Update showcase evidence**

Add only measured repository counts and forward-test results to the README validation block and case study. Label the baseline and skill-assisted conditions.

- [ ] **Step 5: Run final local verification**

```powershell
pwsh -NoProfile -File tests/validate-repository.ps1
pwsh -NoProfile -File tests/validate-sync.ps1
pwsh -NoProfile -File scripts/validate-docs.ps1 -CacheRoot references/.generated -ExpectedPages tests/expected-pages.json
git diff --check
git status --short
```

Expected: all suites PASS, zero cache validation failures, no generated Garmin content tracked.

- [ ] **Step 6: Commit**

```powershell
git add SKILL.md references README.md docs/case-study.md tests/forward-test.md
git commit -m "test: document Monkey C skill forward validation"
```

### Task 8: Publish and verify the public GitHub showcase

**Files:**
- No repository file changes expected after final verification.

**Interfaces:**
- Produces: public `https://github.com/coachrichie/monkey-c-skill` repository with default branch `main`.

- [ ] **Step 1: Verify publication preconditions**

```powershell
git status --porcelain
git log --oneline --decorate -10
git ls-files 'references/.generated/**'
gh auth status
gh repo view coachrichie/monkey-c-skill
```

Expected: clean tree, focused commit history, no generated files, authenticated `coachrichie`; final command reports not found before creation.

- [ ] **Step 2: Create and push the public repository**

```powershell
gh repo create coachrichie/monkey-c-skill --public --source . --remote origin --push --description "A Monkey C skill built with AI, for AI—source-grounded guidance for Garmin Connect IQ development."
```

- [ ] **Step 3: Configure discoverability**

```powershell
gh repo edit coachrichie/monkey-c-skill --add-topic codex-skill --add-topic monkey-c --add-topic connect-iq --add-topic ai --add-topic developer-tools
```

- [ ] **Step 4: Verify the remote state**

```powershell
gh repo view coachrichie/monkey-c-skill --json url,visibility,defaultBranchRef,description,repositoryTopics
git remote -v
git ls-remote --heads origin main
```

Expected: public visibility, default branch `main`, expected description/topics, and matching remote main SHA.

- [ ] **Step 5: Verify GitHub Actions and rendered links**

Run `gh run list --repo coachrichie/monkey-c-skill --limit 5`, wait for the validation workflow, and require a successful conclusion. Open the repository README and verify the two SVGs and all relative documentation links render.

- [ ] **Step 6: Report completion**

Return the public repository URL, latest commit, validation totals, synchronization totals, and any limitations. Do not claim completion unless the workflow succeeded and the remote checks match local state.
