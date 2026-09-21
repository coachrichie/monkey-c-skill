# Monkey C Skill Repository Design

## Purpose

Build a public GitHub repository named `monkey-c-skill` that contains a reusable Codex skill for developing, explaining, and debugging Garmin Connect IQ applications written in Monkey C. The skill will cover the Monkey C language, Garmin's Connect IQ Core Topics, and routing to Toybox API documentation.

The repository will also serve as a polished case study: a transparent, reproducible example of using AI to create a skill for another AI system. It should be understandable to people who want to learn how skills are researched, designed, tested, and maintained.

The repository must be useful to skill users and maintainers without redistributing Garmin-authored documentation in Git.

## Success criteria

- The repository installs as a valid Codex skill named `monkey-c` and displays as “Monkey C.”
- The skill routes language, platform, and API questions to the appropriate reference source.
- A deterministic synchronization command downloads Garmin documentation into an ignored local cache.
- The cache covers the Monkey C guide, every page listed under Core Topics, and the Connect IQ API documentation needed for Toybox symbol lookup.
- Public Git history contains no downloaded Garmin pages or assets.
- User, contributor, maintenance, troubleshooting, security, and licensing documentation is complete.
- The GitHub landing page clearly demonstrates what the skill does, how AI helped create it, how its quality was verified, and how another person can reproduce the process.
- The showcase distinguishes AI-generated assistance from human decisions and does not imply that Garmin participated in or endorsed the project.
- Automated validation catches malformed skill metadata, missing routes, broken generated links, incomplete downloads, duplicate content, and accidental inclusion of cached Garmin files.
- The repository is committed, published publicly on GitHub, and usable from a clean clone.

## Legal and attribution boundary

Garmin's Connect IQ agreement restricts uploading, hosting, and redistributing program materials. Therefore:

- The repository will contain original instructions, indexes, manifests, tests, and automation only.
- Garmin-authored HTML, images, stylesheets, scripts, PDFs, and other downloaded materials will be excluded by `.gitignore`.
- The synchronization command will fetch material directly from Garmin for the user's local use.
- Documentation will identify Garmin as the source and link to the applicable Garmin pages and agreement.
- The repository will not use Garmin logos or imply Garmin sponsorship, certification, or endorsement.
- An MIT license will cover only original repository content and code. It will explicitly exclude Garmin materials.

## Repository structure

```text
monkey-c-skill/
├── SKILL.md
├── agents/
│   └── openai.yaml
├── references/
│   ├── index.md
│   ├── monkey-c-topics.md
│   ├── core-topics.md
│   └── api-routing.md
├── scripts/
│   ├── sync-docs.ps1
│   ├── validate-docs.ps1
│   └── install.ps1
├── tests/
│   ├── validate-repository.ps1
│   └── expected-pages.json
├── docs/
│   ├── installation.md
│   ├── usage.md
│   ├── case-study.md
│   ├── ai-workflow.md
│   ├── reference-routing.md
│   ├── maintenance.md
│   ├── troubleshooting.md
│   ├── legal.md
│   └── superpowers/
│       └── specs/
├── .github/
│   └── workflows/
│       └── validate.yml
├── assets/
│   ├── architecture.svg
│   └── workflow.svg
├── .gitignore
├── CONTRIBUTING.md
├── SECURITY.md
├── LICENSE
└── README.md
```

The generated local cache will live under `references/.generated/` and will never be committed.

## Skill behavior

`SKILL.md` will remain concise and route work by question type:

| Question type | Primary local source after sync | Fallback |
|---|---|---|
| Monkey C syntax, types, functions, memory, containers, exceptions, annotations, conventions, compiler options | `references/.generated/monkey-c/` | Original Garmin Monkey C URL |
| Manifest, lifecycle, UI, storage, communications, sensors, testing, debugging, publishing, and other platform concepts | `references/.generated/core-topics/` | Original Garmin Core Topics URL |
| Toybox modules, classes, methods, API levels, permissions, and device availability | `references/.generated/api-docs/` | `garmin-connect-iq` skill when installed, then Garmin API URL |

The checked-in Markdown indexes will provide topic names, keywords, source URLs, and generated-cache paths. They will be original navigation aids rather than copies of Garmin prose.

## Synchronization design

`scripts/sync-docs.ps1` will:

1. Start from the official Monkey C, Core Topics, and API documentation indexes.
2. Restrict downloads to the approved Garmin URL prefixes.
3. Discover same-site pages and required page assets.
4. Normalize URLs and deduplicate each target path.
5. Write into a staging directory under `references/.generated/`.
6. Validate HTTP status, required seed pages, local page targets, and file counts.
7. Replace the previous generated cache only after validation succeeds.
8. Write a local manifest containing source URL, relative path, content hash, byte size, and synchronization time.

Failures will preserve the last valid cache and return a non-zero exit status with the failing URL and reason. Redirects outside approved Garmin hosts will be rejected.

## Installation design

`scripts/install.ps1` will install the repository into the user's Codex skills directory. It will:

- resolve the target from `CODEX_HOME` when present and otherwise use the standard `.codex/skills` location;
- copy only version-controlled skill files;
- optionally run synchronization after installation;
- refuse to overwrite an unrelated existing `monkey-c` directory;
- support an explicit force/update option for an installation previously created by this repository.

The README will also document manual cloning and symbolic-link installation.

## Documentation design

The repository documentation will cover:

- project purpose, capabilities, prerequisites, and quick start;
- installation, updating, uninstalling, and local cache generation;
- example prompts and reference-routing behavior;
- the difference between Monkey C language guidance, Core Topics, and Toybox API reference;
- synchronization internals, cache lifecycle, and expected source coverage;
- troubleshooting for networking, moved pages, invalid caches, and PowerShell execution policy;
- contribution workflow, tests, release process, security reporting, license boundaries, attribution, and non-affiliation;
- a complete topic inventory generated from checked-in expected-page metadata.
- the AI-assisted creation journey, including the original goal, design choices, licensing discovery, reference architecture, test-first development, verification evidence, and lessons learned;
- a reusable recipe that shows others how to create their own source-grounded skill with AI.

Documentation will use plain language first and commands second. No Garmin branding assets will be embedded.

## GitHub showcase design

The README will function as the repository's showcase page. It will lead with the outcome rather than setup details and use this narrative order:

1. **Hero:** “Built with AI, for AI” with a one-sentence explanation of the Monkey C skill.
2. **Live value:** representative prompts and concise examples of the skill routing a language, platform, and Toybox API question.
3. **How it works:** an original architecture diagram showing the user, Codex, `SKILL.md`, checked-in routing indexes, locally synchronized Garmin sources, and validated answers.
4. **How it was made:** a short timeline from idea through source research, legal boundary, design, failing tests, implementation, verification, and public release.
5. **Evidence:** current validation results, coverage counts, clean-cache guarantees, and continuous-integration status.
6. **Try it:** a short installation and first-use path.
7. **Learn from it:** links to the detailed case study, AI workflow, design specification, tests, and contribution guide.

`docs/case-study.md` will tell the project story as an evidence-based engineering case study, not promotional fiction. `docs/ai-workflow.md` will extract the reusable method: define the intended AI behavior, separate authoritative sources from original guidance, test retrieval failures before authoring, keep proprietary source material out of Git, validate on a clean install, and publish the evidence.

The diagrams will be original SVGs stored in `assets/`, with accessible text alternatives in Markdown. No generated image will imitate Garmin branding. Badges will be limited to repository facts such as CI status, license, PowerShell support, and skill name.

The project will include a clear disclosure that AI assisted with research, architecture, writing, scripting, and testing while the repository owner selected the goals, approved design decisions, and owns publication responsibility. Commit history and the checked-in design documents will provide an inspectable record of the process.

## Testing strategy

Development will follow a failing-test-first workflow. Tests will verify observable behavior rather than generated wording.

Repository validation will check:

- required files and directories;
- valid `SKILL.md` frontmatter and skill name;
- consistency among `SKILL.md`, `agents/openai.yaml`, README, and repository name;
- presence and validity of showcase links, diagrams, example prompts, AI-assistance disclosure, and reproducibility documentation;
- presence and uniqueness of expected Monkey C and Core Topics routes;
- URL allow-list enforcement and path traversal rejection;
- synchronization failure preserving the prior cache;
- all downloaded relative links resolving within the cache;
- no duplicate downloaded files by content hash unless explicitly allowed;
- `.gitignore` coverage and absence of generated Garmin material from Git;
- installer behavior in a temporary Codex home;
- clean-clone operation without a pre-existing cache.

Continuous integration will run offline structural tests on every push and pull request. Network synchronization tests will be opt-in or scheduled so transient Garmin outages do not make normal pull requests unreliable.

## GitHub publication

The local repository will use `main` as its default branch. After implementation and verification:

1. Commit the finished repository with focused history.
2. Create the public GitHub repository `monkey-c-skill` under the authenticated user's account.
3. Push `main` and verify the remote default branch and public visibility.
4. Confirm the README renders correctly and no generated Garmin files are tracked.
5. Configure the repository description and topics to make the showcase discoverable without using Garmin trademarks as branding.
6. Return the repository URL to the user.

No release, package publication, GitHub Pages site, or marketplace submission is included unless requested separately. The repository README is the showcase surface.

## Out of scope

- Republishing Garmin documentation or assets.
- Replacing Garmin's authoritative documentation.
- Bundling the Connect IQ SDK, device files, sample applications, or proprietary tools.
- Claiming Garmin endorsement or compatibility certification.
- Building a Monkey C compiler, language server, or Connect IQ application.
- Automatic periodic refresh after installation.

## Completion criteria

The work is complete when the public repository exists, all version-controlled tests pass, a clean installation succeeds, local synchronization produces a validated and searchable cache, Git contains no Garmin-authored downloaded material, and the repository documentation explains installation, use, maintenance, contribution, security, legal boundaries, and the reproducible AI-assisted creation process. The GitHub README must operate as a self-contained showcase with working diagrams, examples, evidence, and links to the deeper case study.
