## 1.0.0

* Initial release.
* **Emulator / Simulator Detection** — multi-heuristic detection using build properties, hardware fingerprints, and compile-time checks.
* **Root / Jailbreak Detection** — checks for su binary, Magisk, BusyBox, Cydia, sandbox escapes, and 30+ jailbreak indicators.
* **Developer Options Detection** — detects enabled developer settings and USB debugging (Android).
* **Screen Protection** — blocks screenshots and screen recordings using `FLAG_SECURE` (Android) and secure text field overlay (iOS). Content appears black when captured.
