# cat-flap-opener

A small standalone device that opens our cat flap for OMalley (an orange cat who hates pushing the flap with his head).

A time-of-flight distance sensor watches the shelf on each side of the flap.
When he hops up, a tiny low-torque stepper motor on the window frame winds a short cord to lift the flap.
It holds the flap open while he makes up his mind and for 20 s after he's gone, then lowers it gently.

- **Standalone:** an ESP32-S3 with no cloud, Home Assistant or Frigate dependency.
- **Cat-safe:** 5V only, a motor too weak to hurt a paw, gravity closing, and it reopens if he reappears.
- **Minimal:** one USB cable down the wall.

## Docs

- [Design spec](docs/superpowers/specs/2026-09-28-cat-flap-opener-design.md): the full design, behaviour, safety, firmware structure and parts
- [Future: cameras](docs/future-cameras.md): notes for a later build adding live-stream and Frigate cameras on both sides
- [Initial prompt](docs/initial-prompt.md): the original request that started the project

## Status

Design approved. Next steps: buy the parts, build the firmware, bench test, then install.
