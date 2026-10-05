# Installation

From the repository root, run:

```powershell
pwsh -File scripts/install.ps1 -CodexHome "$HOME/.codex" -Sync
```

The installer copies the skill contract, routing guides, runtime scripts, and the expected-page manifest. Generated documentation is refreshed into `references/.generated/` and is preserved across forced updates. Use `-Force` only when replacing an installation managed by this repository.

