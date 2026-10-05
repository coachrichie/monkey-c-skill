# Maintenance

Refresh the cache with `pwsh -File scripts/sync-docs.ps1`, then validate it with `pwsh -File scripts/validate-docs.ps1`. The expected-page manifest is reviewed when Garmin adds or removes source pages. Run the repository suite before committing changes.

The generated cache is ignored by Git to avoid duplicating upstream documentation in the public repository. A clean clone can always recreate it from the official URLs.

