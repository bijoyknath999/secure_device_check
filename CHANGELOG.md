## 1.0.3

* **Documentation** — Updated README dependency constraints to use the latest fixes (`^1.0.2`).

## 1.0.2

* **iOS Screen Protection — Universal iOS version support** — Fixed secure text field approach to work across all iOS versions (15-18+) by searching for the internal `_UITextLayoutCanvasView` by class name instead of relying on a fixed subview index. Includes a layer-based fallback for edge cases.
* **iOS Screen Protection — Touch interaction fix** — Fixed app becoming unresponsive after enabling protection by correctly setting `isUserInteractionEnabled` on the secure container.
* **Cleanup** — Removed debug logging and unused screenshot detection UI from the example app.

## 1.0.1

* **iOS Screen Protection fix** — Rewrote the secure text field implementation to reparent Flutter views into the secure container, fixing screenshot and screen recording prevention on iOS.
* **iOS Developer Options Detection** — Added real developer mode detection on iOS using `sysctl` `P_TRACED` debugger check and `embedded.mobileprovision` provisioning profile analysis.

## 1.0.0

* Initial release.
* **Emulator / Simulator Detection** — multi-heuristic detection using build properties, hardware fingerprints, and compile-time checks.
* **Root / Jailbreak Detection** — checks for su binary, Magisk, BusyBox, Cydia, sandbox escapes, and 30+ jailbreak indicators.
* **Developer Options Detection** — detects enabled developer settings and USB debugging (Android).
* **Screen Protection** — blocks screenshots and screen recordings using `FLAG_SECURE` (Android) and secure text field overlay (iOS). Content appears black when captured.
