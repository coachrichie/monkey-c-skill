# Connect IQ Core Topics

Official source: https://developer.garmin.com/connect-iq/core-topics/

After synchronization, pages are under `.generated/core-topics/`. Search by these routing groups:

| Group | Topics and search terms |
|---|---|
| Application | manifest, permissions, application/system modules, properties, settings, intents, build configuration, security |
| Lifecycle and storage | persistence, backgrounding, glances, complications, watch-face editing |
| Interface | UI, layouts, graphics, input, native controls, resources, Monkey Style, user attention |
| Web and mobile | HTTPS, authenticated services, mobile communication, downloads, Android SDK, iOS SDK |
| Wireless | ANT/ANT+, Bluetooth Low Energy, pairing wireless devices |
| Sensors and activity | sensors, positioning, activity recording/control/prompts, user metrics |
| Engineering | shareable libraries, debugging, unit testing, exception reports, profiling |
| Distribution | publishing, beta apps, trial apps, requesting reviews |

The exact expected page paths and titles are maintained in `tests/expected-pages.json`; use the corresponding slug under `.generated/core-topics/`.

