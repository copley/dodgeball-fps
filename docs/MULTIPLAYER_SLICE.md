# 2v2 Browser Multiplayer Vertical Slice

## Product target

This branch proves one narrow product question:

> Is first-person team dodgeball fun when two teams of two play a three-minute
> score match in a browser, with bots filling every empty slot?

It intentionally does not attempt accounts, matchmaking services, progression,
cosmetics, multiple maps or production art.

## Match rules

- Four fixed match slots: Blue 1, Blue 2, Red 1, Red 2.
- Three physical balls start on the centre line.
- Human connections replace bots one slot at a time.
- Disconnected humans immediately return to bot control.
- Players remain on their own half for this vertical slice.
- `E` picks up the nearest available ball in range.
- Hold left mouse to charge; release to throw.
- Right mouse opens a short catch window.
- `Q` / `F` dodge laterally.
- Opposing live-ball hits score one point and respawn the victim after 1.25 s.
- Friendly-fire hits do not score.
- The match clock is three minutes and then the score, players and balls reset.

## Authority model

The native/headless server owns:

- slot assignment and human/bot substitution;
- player simulation accepted from client intent;
- ball possession and physics;
- throw charge and release;
- catches and hit validation;
- eliminations, respawns, team score and match time.

Clients send intent dictionaries and receive authoritative snapshots at 20 Hz.
The local avatar performs lightweight movement prediction and is corrected toward
server snapshots. Remote avatars and balls consume server snapshots.

The WebSocket transport is deliberate. Godot Web exports can connect as
WebSocket clients while the public game server remains a native/headless Godot
process. For production hosting, terminate TLS at a reverse proxy and expose a
`wss://` endpoint.

## Files added by this slice

- `scenes/multiplayer_main.tscn` — multiplayer court and minimal HUD.
- `scenes/net_avatar.tscn` — shared human/bot physical avatar.
- `scenes/net_ball.tscn` — multiplayer physical ball.
- `scripts/multiplayer_main.gd` — connection, slot, bot, match and snapshot authority.
- `scripts/net_avatar.gd` — movement, local input, prediction and snapshots.
- `scripts/net_ball.gd` — authoritative ball possession, throws and hits.
- `scripts/server_authority_bootstrap.gd` — switches server balls to authoritative physics after startup.

The original `scenes/main.tscn`, `scripts/main.gd`, `scripts/player.gd`,
`scripts/bot.gd` and `scripts/ball.gd` remain as the completed M7 prototype
reference.

## Local server test

Run a dedicated server from the repository root:

```bash
godot --headless --path . -- --server --port=9080
```

Expected console output includes:

```text
2v2 dodgeball server listening on ws://0.0.0.0:9080
```

With no humans connected the server simulates four bots.

## Desktop client test

In separate terminals launch up to four clients:

```bash
godot --path . -- --url=ws://127.0.0.1:9080
```

Each client should receive the next free slot. The HUD identifies Blue or Red.
A fifth connection remains without a playable slot in this prototype.

## Browser export test

1. Install the matching Godot 4.7 Web export templates.
2. Export the project for Web to `build/web/index.html`.
3. Serve the build over HTTP using a real local web server, not `file://`.
4. Run the native/headless server on port 9080.
5. Open the web build in a current Chromium/Firefox browser.
6. For a remote deployment, change the client server URL to the deployed
   `wss://` endpoint before export.

Browser clients do not host the match.

## Required validation before calling the slice complete

Automated/parser checks:

```bash
godot --headless --path . --editor --quit
```

Legacy regressions should still be run explicitly against the legacy scene and
focused scripts where applicable.

Interactive network checks:

- [ ] Dedicated server starts with four bots and no parser/runtime errors.
- [ ] Client 1 becomes Blue 1 and replaces one bot.
- [ ] Client 2 becomes Blue 2.
- [ ] Client 3 becomes Red 1.
- [ ] Client 4 becomes Red 2.
- [ ] Disconnecting a client restores bot control for that slot.
- [ ] Human movement is responsive and corrected without severe rubber-banding.
- [ ] Three balls remain unique through repeated pickup/throw/catch cycles.
- [ ] Holding and releasing left mouse produces visibly different throw speeds.
- [ ] A valid opposing hit increments exactly one team point.
- [ ] Friendly fire does not increment score.
- [ ] Catching prevents the hit and transfers possession.
- [ ] Eliminated players respawn after approximately 1.25 seconds.
- [ ] Match timer and score agree on all connected clients.
- [ ] The Web export connects and plays from at least two browser windows.
- [ ] The game remains playable on an ordinary laptop at 1280x720.

## Known limitations of this first networking pass

- There is no matchmaking service; clients connect directly to one server URL.
- There is no lobby, account, persistence, reconnect identity or ranked state.
- The fifth and later connections are not actively kicked; they simply receive no slot.
- Snapshot interpolation is intentionally simple and will need tuning under real WAN latency.
- Input validation and anti-cheat are minimal beyond server ownership of outcomes.
- Production browser hosting still needs HTTPS/WSS, deployment automation and regional servers.
- The multiplayer branch has to be run through Godot parser/headless validation on a machine with Godot 4.7 installed before it should be merged.
