# Case study: building Monkey C, Built with AI, for AI

This repository began with a practical goal: make Garmin Connect IQ development questions answerable through a focused local skill. The owner selected the three source families—Monkey C, Core Topics, and the Toybox API—and chose a public repository so the construction process could be inspected.

The work was deliberately test-first. A page manifest and repository contracts came before the routing guides. The implementation then added a deterministic synchronizer, staged replacement, link validation, and an installer that preserves generated references. A live synchronization verified 391 files, 384 HTML pages, zero missing pages, zero broken local links, and zero duplicate paths at the time of the build.

The AI contribution was implementation speed, synthesis, and documentation. Human decisions remained visible: scope, source boundaries, licensing posture, acceptance criteria, and publication approval were owner decisions. That separation is the point of the showcase: AI assisted the build, while the repository records how it can be checked.

See [the AI workflow](ai-workflow.md), [reference routing](reference-routing.md), and [maintenance](maintenance.md) for the repeatable details.

