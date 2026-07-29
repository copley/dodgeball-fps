# Dodgeball FPS

A playable Godot 4 prototype for a first-person dodgeball game, built as a six-hour pilot.

## Pilot goal

Prove the core loop:

1. Move and look in first person.
2. Pick up a ball.
3. Charge and throw it with projectile physics.
4. Hit a target.
5. Catch an incoming ball during a short timing window.
6. Dodge laterally.
7. Reset the round.

## Scope

The pilot uses one stylized indoor court, one player, one ball, and one stationary
target or simple bot. It excludes multiplayer, polished art, progression,
complex AI, complex menus, and production release work. A basic pause overlay
provides resume, clean round restart, controls, and quit actions.

## Visual style

The court uses a clean painted-gym palette: bright blue for the player half,
coral red for the opponent half, court green for the centre strip and perimeter,
and warm-white lines. Dove-grey walls, dark-navy lower trim, a light-grey
ceiling, and charcoal accents keep the ball, target, crosshair, and boundaries
easy to distinguish.

## Project controls

- `AGENTS.md` — permanent rules for AI coding agents.
- `docs/SPEC.md` — required behaviour and acceptance criteria.
- `docs/ARCHITECTURE.md` — intended Godot structure.
- `docs/TASKS.md` — ordered implementation queue.
- `docs/TESTING.md` — validation and play-test checklist.
- `docs/MILESTONES.md` — current implementation milestones and roadmap.

Implementation tasks T1–T6 are complete.

## Controls

- `WASD`: move
- Mouse: aim/look
- `Shift`: hold to sprint
- `Ctrl`: hold to crouch
- `Space`: jump
- Left mouse: hold to charge, release to throw
- Right mouse: timed catch
- `E`: pick up/interact
- `Q`: dodge left
- `F`: dodge right
- `R`: restart the current round
- `F3`: toggle performance diagnostics
- `Escape`: toggle the pause menu

The pause menu releases the mouse and pauses gameplay. It includes Resume,
Restart Round, Controls, and Quit Game; restarting closes the menu and restores
the existing player, ball, and target without creating replacements.

## Performance diagnostics

Physics interpolation is enabled to smooth visual motion between fixed physics
updates. An F3 overlay shows FPS, current, rolling-average, and short-window
maximum frame time, physics-processing time, draw calls, and rendered object
count. It updates four times per second. Use a release/editor play session to
identify the limiting area before reducing visual quality:

- Low FPS with high frame time suggests rendering or general frame load.
- High physics time suggests collision or gameplay processing.
- High draw calls or object count suggests scene/render batching work.
- Stable metrics with visibly uneven movement suggests frame pacing, display
  synchronization, or hardware/driver configuration rather than court design.
