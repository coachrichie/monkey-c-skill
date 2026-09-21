---
name: monkey-c
description: Use when developing, explaining, reviewing, or debugging Garmin Connect IQ apps in Monkey C, including language syntax, app lifecycle, UI, sensors, communications, testing, and Toybox API usage.
---

# Monkey C

Ground Connect IQ guidance in Garmin's documentation. Identify the question type, load only the matching reference, and cite the exact Garmin source page used.

## Route the question

- For syntax, functions, objects, memory, containers, types, exceptions, annotations, conventions, or compiler options, read [Monkey C topics](references/monkey-c-topics.md).
- For manifests, lifecycle, storage, backgrounding, UI, communications, sensors, testing, debugging, or publishing, read [Core Topics](references/core-topics.md).
- For Toybox modules, classes, methods, API levels, permissions, deprecations, or device availability, read [API routing](references/api-routing.md).
- Start with [the reference index](references/index.md) when the question crosses these boundaries.

Search the matching directory under `references/.generated/` before relying on memory. Preserve version, API-level, permission, supported-device, and deprecation constraints in proposed code.

If the generated cache is absent, use the official source URL in the matching reference and explain that `pwsh -File scripts/sync-docs.ps1` creates the local cache. Do not present the checked-in topic maps as copied Garmin documentation.

