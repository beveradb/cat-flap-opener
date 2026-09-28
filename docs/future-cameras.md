# Future follow-up: cameras on both sides of the flap

**Status:** idea only, not part of the v1 build.

## Goal

Add wide-angle or fisheye cameras on both sides of the catio entrance, so we can:
- watch a live stream,
- record into the existing Frigate NVR (see `home-servers-config`),
- optionally get a timeline of OMalley's trips in and out.

## Core principle: decoupled from the opener

The cameras are a **separate add-on**. The opener must keep working if the cameras, WiFi, Frigate or Home Assistant are down.
Cameras must never be in the opening path.

## Why not ESP32-S3 camera boards

ESP32-S3 camera boards (e.g. XIAO ESP32S3 Sense, OV2640/OV3660) *can* stream MJPEG into Frigate via go2rtc/ESPHome, and 160° fisheye OV2640 modules exist.
But they manage only about 10–15 fps at 640×480 MJPEG, have no H.264, and use 2.4 GHz WiFi, which is often flaky.
They're fine for a still, not good for a stream worth watching.
Putting streaming on the opener's own ESP32 would also risk its responsiveness.

## Recommended options

1. **Raspberry Pi Zero 2 W + Camera Module 3 Wide (120°), or a 160–200° fisheye CSI module, one per side**
   - Streams H.264 RTSP (e.g. via MediaMTX / `rpicam-vid`) straight into go2rtc/Frigate.
   - Small, runs on 5V USB. The outdoor unit needs a weatherproof housing (the catio roof leaks in storms).
2. **One Raspberry Pi 5 with two CSI camera ports** driving both cameras
   - One board to maintain. Needs camera cable runs to both sides (the outside one goes through or around the frame).
3. **Off-the-shelf Tapo camera(s)**
   - Easiest to set up, and matches the existing cameras in the house.
   - Less discreet, and not fisheye. Tapo outdoor models could cover the catio side.

## Optional integration with the opener

The opener could later publish MQTT events (`opened`, `closed`, `inside_triggered`, `outside_triggered`) to the existing broker on homefanless1.
HA/Frigate could then:
- mark events on the recordings,
- build stats on how often he goes out,
- send notifications.

This is strictly opt-in, fire-and-forget, and never required for the opener to work.

## Mounting provision in v1

The v1 install should leave room on the window frame for a small camera on each side of the flap.
Route the v1 cables so they don't block those spots.
