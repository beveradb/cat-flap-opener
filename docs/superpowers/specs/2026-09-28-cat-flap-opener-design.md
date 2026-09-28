# Cat Flap Opener — Design Spec

**Date:** 2026-09-28
**Status:** Approved design, pre-build
**Cat:** OMalley (orange, slow and deliberate, dislikes pushing the flap with his head)

## 1. Problem

OMalley hops up onto his shelf to go out through the cat flap, but he dislikes pushing the flap with his head.
So either he gives up and stays in, or a human walks over and holds the flap open until he sniffs the air and decides to go.
He also struggles coming back in, though less.

**Goal:** a small standalone device that lifts the flap open when he's on either shelf (inside or catio side), holds it while he decides and walks through, then gently lowers it.

## 2. Existing setup

- **Flap:** a SureFlap microchip flap with the batteries removed and the latch taped over, so it now works as a plain free-swinging flap.
- **Mounting:** the flap sits in a DIY acrylic panel in a living-room window. There's wooden window frame a few inches above the flap.
- **Inside:** a shelf in the living room that he hops onto to reach the flap.
- **Outside:** a catio (enclosed, with a roof that lets some rain in during storms). He steps out onto a wooden shelf that's part of the catio.
  No other animals can reach the outside shelf.

## 3. Key decisions

| Decision | Choice | Why |
|---|---|---|
| Detection | **Presence sensing, not vision** | The only question is whether something is on a shelf. Occasional false triggers (a hand, a bag) are harmless: the flap just opens. No model, no lighting issues, no video. |
| Sensor | **VL53L1X time-of-flight distance sensor** above each shelf | Precise, small detection zone, works in the dark, about 1 cm square, ignores people walking past. It also works when he stays still, unlike PIR sensors. |
| Controller | **Seeed XIAO ESP32-S3** (plain, no camera) | Thumb-sized, cheap, two I²C buses, spare headroom and pins for future options. |
| Actuator | **28BYJ-48 5V geared stepper** plus a ULN2003 driver, winding a cord on a small spool | Moves to an exact position every time, so there's no timing to tune. It's deliberately low-torque (can't hurt a paw). The gearbox holds position without power. |
| Linkage | **Short braided cord** (about 1 mm, dark), spool to an eyelet on the flap's bottom edge | Pulling the flap's bottom edge up and into the room opens it for both directions. Braided cord replaces monofilament, which is a cat hazard. |
| Power | **5V USB** from a wall plug; one cable down the wall | A sensor-only design could run on battery, but USB means zero maintenance and leaves room for the future cameras. |
| Home Assistant/Frigate | **Not required** | Must work fully standalone. MQTT reporting is an optional future add-on and must never be needed for opening. |

Rejected alternatives:
- **Camera plus an on-device classifier:** unnecessary for this job. Cameras may be added later for viewing only; see [future-cameras.md](../../future-cameras.md).
- **Frigate → HA → ESP32:** depends on infrastructure that isn't reliably maintained.
- **Pressure pads:** they need false tops on the shelves, are hard to weatherproof, and only detect arrival, not approach.
- **mmWave radar:** its detection zone is too fuzzy.
- **Timed DC motor:** needs tuning and can over-wind.
- **Servo arm:** the range and geometry are awkward, and a rigid arm is more exposed to swipes.

## 4. Physical layout

```
          wooden window frame
   ┌───────────────────────────────────┐
   │ [controller box] [motor+spool] [ToF-in]   ← inside, screwed to frame
   │                      │ cord (slack when closed)
   │   ┌──────────────┐   │
   │   │   cat flap   │   │
   │   │              │   │
   │   └──────o───────┘ ◄─┘ eyelet on flap's bottom edge
   │   acrylic panel
   └───────────────────────────────────┘
      inside shelf ▼               outside (catio) shelf ▼
                         [ToF-out in sealed box with clear window,
                          4-core cable through/around the frame]

   controller box ── USB-C cable along and down the wall ── 5V USB plug
```

**Inside, on the window frame (the only visible tech):**
- A matchbox-sized box containing the XIAO ESP32-S3, the ULN2003 driver and a push button.
- The stepper with its spool.
- The inside VL53L1X, aimed down at the inside shelf.

**Outside (catio):**
- The second VL53L1X in a small sealed enclosure with a clear window, placed as sheltered as possible, aimed at the catio shelf.
- It connects to the controller through about 1 m of 4-core cable (3V3, GND, SDA, SCL).
- **Stretch option to try during install:** mount the outside sensor *indoors*, looking out through the acrylic. This removes all outdoor electronics. It needs a clear view of the catio shelf and the sensor's crosstalk calibration for the cover. Use it only if it works reliably.

**Why the controller is at the window:** putting it at the wall socket would mean running about 12 conductors (4 motor wires plus 2 × 4 sensor wires) down the wall, with I²C over roughly 2 m. Keeping it at the window turns all of that into one USB cable.

**Sensor wiring:** both VL53L1X sensors have the same default I²C address (0x29).
Put each sensor on its own I²C bus; the ESP32-S3 has two.
(Fallback: use XSHUT to reassign addresses at boot.)
The outside sensor's roughly 1 m cable runs at 100 kHz.

**Cord behaviour:** when the flap is closed, the cord hangs **slack** so the flap swings freely both ways, exactly as it does today.
The motor only ever *takes up* slack to lift the flap and *pays it out* to lower it. It never pushes.

## 5. Behaviour

The controller runs a state machine, polling both sensors at about 10 Hz.

1. **Idle (closed):** the cord is slack and the motor coils are de-energised.
2. **Trigger:** a sensor is **triggered** when it reads closer than its calibrated empty-shelf distance minus a margin (starting at 50 mm; tunable).
   Opening requires a trigger on either sensor for **about 300 ms continuously**. This debounce filters out rain and brief passes.
3. **Opening:** the motor winds the cord to the calibrated **open position** over about 2 s.
4. **Open / hold:** the flap stays open while either sensor is triggered, **plus 20 s after both are clear**.
   He's between the sensors (in the tunnel) while passing through, and he's often slow, so this generous grace period is the main safety rule.
   The outside is a gated catio, so a long hold carries no intruder risk.
5. **Closing:** the motor unwinds slowly (about 3 s) back to slack, so the flap lowers under its own weight.
   **If either sensor triggers during closing, it reverses immediately to Opening.**
6. **Max hold:** if the flap has been open continuously for **2 minutes**, it closes.
   The sensor that's still triggered is then **latched out**: it's ignored until its reading goes back to "clear".
   This handles a bag left on the shelf, or OMalley napping there.
7. **Cooldown:** after closing, triggers are ignored for **3 s** to prevent rapid flapping.

All the timings (debounce, grace, max hold, cooldown, margin) are named constants, tunable in one place.

### Calibration and controls

The controller box has a single button:
- **Long press (3 s), with both shelves empty:** takes several readings from each sensor and stores the empty-shelf distance for each in flash.
- **Short press:** runs one manual open, hold, close cycle, for testing.
- **Open position:** set as a step count in config and tuned on the window.
  Later option: a set-open-position mode using the button.

The closed position is "home" (step 0). At boot the motor assumes it's at home.
Because the cord is slack when closed, a small homing error only changes the amount of slack; it can't force the flap.

## 6. Safety

- **Only 5V on the window.** No mains voltage, no batteries with a high discharge rate.
- **Low-torque motor.** The 28BYJ-48 through its gearbox can easily lift a flap weighing tens of grams, but it can't pinch or trap a paw with meaningful force.
- **Gravity closing.** The flap closes under its own weight, the same way it does when he pushes through today.
  The motor only controls how fast it's allowed to lower.
- **Long grace period** (20 s after both sensors are clear), and **reopens during closing** if a sensor triggers.
- **Braided cord, short and taut when open**, slack but short when closed. No loose line he could chew or swallow.
  Check the cord's condition periodically.
- **Enclosed electronics.** No exposed boards on the window. Cables are clipped flat to the frame and wall.
- **Fail-safe behaviour:**
  - Power loss while closed: a normal flap.
  - Power loss while open: the gearbox probably holds it open. That's acceptable because the catio is enclosed; power-cycle to recover.
  - Sensor fault (I²C error or no reading): treat that sensor as clear and log it over serial. The other sensor keeps working.

## 7. Firmware structure

The firmware is a PlatformIO project (Arduino framework) for the XIAO ESP32-S3.

| Module | Responsibility | Depends on |
|---|---|---|
| `controller` (state machine) | Pure logic: `update(now_ms, inside_mm, outside_mm) → target_position`. Holds all the timing rules. | Nothing hardware-related; unit-tested on the host |
| `presence` | Converts raw distances plus calibration into debounced triggered/clear signals and handles the latch-out | Config only; unit-tested on the host |
| `sensors` | VL53L1X init on two I²C buses and non-blocking reads | VL53L1X library |
| `motor` | Non-blocking stepper moves to target steps at a given speed; de-energises coils when idle at home | AccelStepper (or equivalent) |
| `storage` | Saves and loads calibration in NVS flash | ESP32 Preferences |
| `ui` | Button (short/long press) and status LED | GPIO |
| `main` | Wiring: reads sensors, passes them to `presence` and `controller`, then drives `motor` | All of the above |

WiFi and MQTT are **out of scope** for v1. Adding them later should only mean adding an `events` publisher that `main` calls with state changes. The opening path must not depend on it.

## 8. Testing

1. **Host unit tests** (PlatformIO `native` environment, Unity) for `presence` and `controller`:
   - A rain blip shorter than 300 ms doesn't open.
   - A steady presence opens.
   - It holds while triggered, and for 20 s after both sensors are clear, then closes.
   - A trigger during closing reopens.
   - Max hold closes the flap and latches out the stuck sensor, which recovers once the reading clears.
   - Cooldown after closing works.
   - Either sensor alone opens the flap.
2. **Bench test:** motor, spool and both sensors on the desk. Wave a hand over them; check the timings and that the coils go cold when idle.
3. **Window install:**
   - Fit the eyelet and cord.
   - Tune the open-position step count so the flap opens fully without the cord straining.
   - Calibrate the empty-shelf distances.
4. **Supervised trial:** watch OMalley use it for a week. Tune the margin, grace and debounce. Watch for rain false-triggers on the catio side.

## 9. Parts (USD, approximate)

The specific products and vendors are chosen during purchasing and recorded in [`docs/bom.md`](../../bom.md).

| Part | Qty | ~USD |
|---|---|---|
| Seeed XIAO ESP32-S3 (plain) | 1 | $8 |
| 28BYJ-48 5V stepper + ULN2003 driver board | 1 (buy a 2-pack as a spare) | $6–10 |
| VL53L1X breakout (Pololu / Adafruit / SparkFun) | 2 | $30 |
| Small project enclosure + momentary push button | 1 | $8 |
| Small weatherproof enclosure with a clear lid (or a clear acrylic window) + cable gland | 1 | $8 |
| Thin 4-core cable (about 1–2 m); USB-C cable (about 3 m) | 1 each | $12 |
| Braided cord (about 1 mm, dark), small spool/pulley or 3D-printed spool, adhesive or screw eyelet | 1 | $8 |
| 5V ≥2A USB power supply | 1 | $8 (or reuse one) |
| Hookup wire, header pins, heat-shrink, cable clips | — | $10 (if not already owned) |

**Estimated total: about $80–100.**

## 10. Measurements needed before install

- Flap width and height, and where it's hinged.
- Vertical distance from the flap's bottom edge to the wooden frame above it (this determines cord length and spool size).
- Height of the inside and outside shelves relative to the frame (determines the sensor aim and angles).
- A photo of each side.

## 11. Out of scope for v1

- Cameras and live streaming: see [future-cameras.md](../../future-cameras.md).
- WiFi, MQTT and Home Assistant integration.
- Recognising which cat it is (there's only one cat, and the catio is gated).
- Battery power.
