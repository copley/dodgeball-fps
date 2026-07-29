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

The pilot uses one stylized indoor court, one player, one ball, and one stationary target or simple bot. It excludes multiplayer, polished art, progression, complex AI, menus, and production release work.

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

Implementation tasks T1–T5 are complete.

## Controls

- `WASD`: move
- Mouse: look
- `E`: pick up an available ball
- Left mouse: hold to charge, release to throw
- Right mouse: open the catch window
- `Esc`: release the mouse cursor
