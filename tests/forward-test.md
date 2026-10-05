# Forward validation

These scenarios check the skill's intended retrieval behavior against the local routing contract. They are intentionally phrased as user questions rather than implementation checks.

| Prompt | Expected route | Evidence |
| --- | --- | --- |
| How do I declare a Monkey C class? | Monkey C guide | `references/monkey-c-topics.md` and the Monkey C source family |
| Which Core Topics explain app lifecycle? | Core Topics guide | `references/core-topics.md` and the Core Topics source family |
| Which Toybox API reads a sensor value? | API routing guide | `references/api-routing.md` and the API source family |
| The cache is absent; where should I look? | Official fallback | exact Garmin URLs in `SKILL.md` and the routing guides |

The checks are reproducible locally with the repository validator and synchronization fixture. A hosted model call is not required to validate the routing contract.

