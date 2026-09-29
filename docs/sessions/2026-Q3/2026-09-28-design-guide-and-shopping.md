# Cat flap opener: design, build guide and shopping prep (2026-09-28)

**Project:** cat-flap-opener (public, github.com/beveradb/cat-flap-opener)
**Branch/commit:** main @ 67f119d
**Status:** paused before buying parts; firmware not started

## Summary

Andrew wants a standalone device that opens the cat flap for OMalley, an orange cat who dislikes pushing it with his head.

This session:
- Brainstormed and approved the design.
- Created the public repo.
- Wrote the design spec, a future-cameras note and an illustrated 26-page build guide (Markdown + PDF).
- Built shopping carts on Adafruit and Amazon via the Playwright browser, trimmed using Andrew's order history.
- Updated everything from Andrew's real window measurements and photos.

Andrew paused before purchasing so he can focus on day-job work.

## What changed

**Repo created** (`gh repo create beveradb/cat-flap-opener --public`). Docs:
- `docs/initial-prompt.md`: the original request, verbatim.
- `docs/superpowers/specs/2026-09-28-cat-flap-opener-design.md`: the design spec.
- `docs/future-cameras.md`: a possible later build adding fisheye cameras feeding Frigate, fully decoupled from the opener.
- `docs/guide/build-guide.md` and `build-guide.pdf`, which cover:
  - hand-drawn SVG diagrams (overview, wiring, mechanism, enclosures) plus a Mermaid state diagram
  - product photos
  - Andrew's EXIF-stripped window photos
  - a 12-step checklist build, troubleshooting, pin map, settings and costs
- `docs/guide/build-pdf.sh`: renders the PDF (US Letter) using a local `style.css`.

**Carts** (the Playwright chrome-1 profile was logged into both stores). Nothing was bought.
- **Adafruit, $77.25:**
  - 2× QT Py ESP32-S3 (PID 5426)
  - 3× VL53L1X (PID 3967)
  - STEMMA QT cables 400 mm ×2 (PID 5385) and 200 mm ×2 (PID 4401)
  - 2× STEMMA QT to male header (PID 4209)
- **Amazon, about $125:**
  - ELEGOO 28BYJ-48 + ULN2003 5-pack
  - GT2 60T pulley (B0FNDDCRM1), plus a 20T/40T set as fallback
  - 1 mm braided nylon cord
  - Zulkit 80×50×26 mm boxes
  - IP65 clear-lid box
  - 22 AWG 4-core cable
  - starter kit: ELEGOO Fun Kit, Dupont wires, 22 AWG hookup wire, heat-shrink, wire stripper, helping hands
  - Andrew later removed the VHB tape and **one other unrecorded item**.
- **Dropped because Andrew already owns them** (found by searching his Amazon order history): multimeter, soldering kit and consumables, USB chargers and cables, cable clips, Velcro, drill bits, caliper, cutters.

**Andrew's measurement photos:**
- The originals were deleted from the repo dir after he approved; a copy remains in `~/Downloads/omalley-cat-flap-photos`, with GPS.
- Stripped copies are in `docs/guide/photos/`.

## Decisions and rationale

- **Presence sensing (VL53L1X time-of-flight), not a camera plus classifier.** False triggers are harmless, so identifying the cat is unnecessary.
- **Fully standalone ESP32**, with no dependency on Home Assistant or Frigate (Andrew's HA/Frigate upkeep is unreliable). MQTT might be added later as an optional extra.
- **Stepper plus cord, slack when closed, with gravity closing.**
  - This keeps it cat-safe, and the flap works normally if the power fails.
  - The cord is braided, not monofilament (a hazard to cats).
- **Behaviour:**
  - opens after a 0.3 s debounce
  - holds while either sensor sees him **plus 20 s** (Andrew raised this from 5 s because he's slow)
  - reverses if a sensor triggers while closing
  - 2-minute maximum hold, with a latch-out for a stuck sensor
  - 3 s cooldown
- **QT Py ESP32-S3 instead of the XIAO:**
  - its STEMMA QT socket takes the inside sensor on `Wire1` with no soldering
  - the SDA/SCL pads take the outside sensor on `Wire`
  - two I²C buses avoid the shared 0x29 address
- **The controller box sits at the window** (a single USB cable goes down the wall). Putting it at the outlet would mean running about 12 conductors.
- **Cameras** will be a separate future build (Pi Zero 2 W or Pi 5 streaming RTSP into Frigate), not ESP32-CAM.

## Learnings and gotchas

- **Take-up is large.** The cord path from the mount point is 28 cm with the flap closed and 13 cm open, so 15 cm of take-up.
- **The motor is slow.** The 28BYJ-48 manages only about 12–15 rpm, so the pulley size decides opening time:
  - 60T: about 6–7 s
  - 40T: about 9–11 s
- **The pulling force needed is small** (about 40 g at worst), because the cord pulls nearly vertically near full open.
- **Mount the inside sensor beside the flap, not above it.** Otherwise the flap swinging up into the room passes through the beam and holds the flap open.
- **The outside sensor box mounts lid-down, with a hole cut in the lid.** Rain can't fall in, and there's no cover in front of the sensor to cause crosstalk.
- **Box size:** the ULN2003 board (about 31×35 mm) doesn't fit a 61×36 mm box, hence the 80×50×26 mm box.
- **ULN2003 header pins:** they must be snipped and soldered, because Dupont housings are too tall for a 26 mm box.
- **Window geometry:**
  - The motor mounts on the **lower sash's bottom rail**. That paint is flaky, so use screws.
  - It's an operable sash, so unhook the cord before moving it.
  - The cord must clear the SureFlap housing lip by at least 3 cm; use a spacer block if needed.
- **Andrew's phone photos embed home GPS.** Always strip with `magick -strip` and verify with `exiftool` before committing anything to this public repo.
- **md-to-pdf quirks:**
  - It hung intermittently on the theme's Google Fonts `@import`. The fix is a local `docs/guide/style.css` without the import.
  - Images outside the markdown's directory don't load, so keep them under `docs/guide/`.
- **Mermaid CLI** needs `-p` with a puppeteer config pointing at system Chrome.

## Open threads and next steps

1. **Buy the parts.** All product links are in guide §4. Compare against the Amazon cart first, because one removed item isn't recorded. Confirm with Andrew before paying.
2. **Write the firmware** in `firmware/` (PlatformIO, Arduino, QT Py ESP32-S3), following spec §7–8 and the guide's Step 3 and Step 11 console commands. It needs:
   - a pure `controller` state machine and `presence` logic, with native Unity tests
   - drivers for the sensors and motor
   - NVS calibration storage
   - the button: short press cycles; hold 3 s to calibrate
   - the NeoPixel status LED
   - a serial console: `u`/`d` to jog, `save`, `home`, `reverse`, `auto on`/`auto off`
3. **Build** following the guide, Steps 1–12.
4. **Optional later:** MQTT events and the cameras (`docs/future-cameras.md`).

## Related docs

- [Design spec](../../superpowers/specs/2026-09-28-cat-flap-opener-design.md)
- [Build guide](../../guide/build-guide.md) ([PDF](../../guide/build-guide.pdf))
- [Future cameras](../../future-cameras.md)
- [Initial prompt](../../initial-prompt.md)
