# Testing

This document owns automated correctness validation. Subjective interactive
evaluation is defined in [PLAYTESTING.md](PLAYTESTING.md), with evidence
recorded using [playtests/TEMPLATE.md](playtests/TEMPLATE.md). Headless success
does not establish fun, fairness, usability, audio quality, visual quality in
motion, M5.2 completion or M8 completion.

## Automated validation

Run from the repository root after Godot project files exist:

```bash
godot --headless --path . --editor --quit
```

When a runnable main scene exists:

```bash
godot --headless --path . --quit-after 2
```

Run every focused regression script:

```bash
for test_script in tests/*.gd; do
	godot --headless --path . --script "$test_script"
done
```

Any parser error, missing resource, invalid node path, or non-zero exit status blocks completion.

The focused complete-round-loop suite is:

```bash
godot --headless --path . --script tests/test_complete_round_loop.gd
```

It covers both winners, invalid ball states, one-result acceptance, gameplay
locking, pause-aware timing, both manual cancellation paths, five manual resets,
twenty automatic completions, entity counts, clean state restoration, and the
bot resuming retrieval and throwing.

## Manual pilot checklist

These observations are interactive evidence, not automated acceptance. Use the
play-testing guide and template when performing M8.

- [ ] Project opens directly into the court.
- [ ] Mouse capture and release behave predictably.
- [ ] WASD movement and collisions are stable.
- [ ] Shift sprint preserves diagonal normalization and collision.
- [ ] Space jumps only while grounded.
- [ ] Ctrl crouches and refuses to stand under an obstruction.
- [ ] Player picks up only the available ball.
- [ ] Quick and charged throws produce different speeds.
- [ ] Ball collides with floor, walls, player, and bot.
- [ ] One valid hit produces one elimination.
- [ ] A newly released throw is live until its first valid collision.
- [ ] Direct live hits make the ball dead and cannot emit duplicate eliminations.
- [ ] Floor, ceiling, left, right, near, and far wall contacts make the ball dead.
- [ ] A bounced or otherwise dead ball can still move physically but cannot eliminate.
- [ ] Dead and available balls cannot be caught.
- [ ] A sleeping or slow dead ball becomes available after the pickup grace period.
- [ ] Picking up an available ball clears velocity and the next throw is live.
- [ ] Catch succeeds only inside the intended timing window.
- [ ] Successful catch grants possession.
- [ ] Dodge moves laterally and respects its cooldown.
- [ ] Escape pauses gameplay, releases the mouse, and opens all menu panels.
- [ ] Menu clicks do not throw, catch, pick up, dodge, jump, or restart through
	  the overlay.
- [ ] Resume recaptures the mouse; menu Restart Round resets and resumes.
- [ ] Bot spawns at TargetSpawn facing the player.
- [ ] Bot retrieves only an AVAILABLE ball with collision-safe movement.
- [ ] Bot waits through its aim delay and throws toward the player with bot identity.
- [ ] A bot throw can be caught or dodged and a catch transfers possession.
- [ ] Human and bot live throws eliminate only the other participant, exactly once.
- [ ] Bounced or dead throws eliminate neither participant.
- [ ] A missed bot throw becomes DEAD, then AVAILABLE, then is retrieved again.
- [ ] Ten retrieve-and-throw cycles retain one ball and valid ownership without
	  stuck states or duplicate throws.
- [ ] Pause freezes bot state/timers and elimination stops all bot actions.
- [ ] Reset restores one player, one ball, and one bot.
- [ ] Five consecutive resets create no duplicate entities or events.
- [ ] A direct human live throw displays PLAYER WINS exactly once.
- [ ] A direct bot live throw displays BOT WINS exactly once.
- [ ] Player controls and bot actions stop for the complete result delay.
- [ ] One automatic reset clears the result and restores active play.
- [ ] Pause during the result delay freezes its remaining time and resumes it safely.
- [ ] R during the result delay resets immediately without a later stale reset.
- [ ] Pause-menu Restart Round during the result delay has the same cancellation-safe result.
- [ ] Ten consecutive interactive rounds retain one player, one bot, and one
	  ball without duplicate results, frozen controls, lost possession, or stale
	  delayed resets.
- [ ] Movement and ball motion appear smooth with physics interpolation enabled.
- [ ] F3 toggles FPS, frame time, physics time, draw-call, and object diagnostics.
- [ ] Restarted entities do not visibly interpolate from their previous position.
- [ ] At 1280×720, court lines do not shimmer or depth-flicker.
- [ ] 2× MSAA visibly reduces jagged court and entity edges.
- [ ] Ball, bot, crosshair, and markings remain readable on every floor zone.
- [ ] FPS remains approximately 60 and average frame time remains near 16.7 ms.
- [ ] Ordinary play produces no persistent frame-time spikes.
- [ ] Compare 2× MSAA (`msaa_3d=1`) with 4× (`msaa_3d=2`) using the same
	  one-minute movement and throwing route; retain 2× unless 4× holds baseline.

## Evidence expected in pull requests

Each implementation PR must include:

- Commands run and their exit status.
- Manual checks performed.
- Known limitations.
- Screenshots or a short capture when behaviour is visual and cannot be established by logs.

## M7 manual acceptance procedure

These checks require an interactive run and are not satisfied by headless tests:

1. Start a round and let the bot retrieve and throw.
2. Let a direct bot throw hit the player; confirm `BOT WINS` appears immediately.
3. Confirm controls and bot actions stop during the result delay.
4. Confirm one clean automatic reset occurs, the result clears, and the bot resumes play.
5. Reset and eliminate the bot with a direct live throw; confirm `PLAYER WINS` appears once.
6. Pause during the result delay and confirm reset waits for resume.
7. Press R during the result delay and confirm no second delayed reset occurs.
8. Repeat with pause-menu Restart Round.
9. Play at least ten consecutive rounds and confirm one player, one bot, one
   ball, no duplicated results, no frozen controls, no lost possession, and no
   stale delayed reset.
10. Confirm F3 diagnostics and court rendering remain unchanged.
