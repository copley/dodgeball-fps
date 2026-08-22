# Dodgeball FPS

## 2v2 browser multiplayer branch

The `feature/2v2-browser-multiplayer-slice` branch is now the approved product-expansion path. Its default scene is a 2v2 team match with four fixed slots, three balls, bot fill, a three-minute score clock, respawns, first-person movement, pickup, charged throws, catching and lateral dodges.

The browser/client transport is Godot high-level multiplayer over WebSockets. A native/headless Godot process is authoritative for player simulation, possession, ball physics, catches, hits, score and match time. Human connections replace bots; disconnecting returns that slot to bot control.

See `docs/MULTIPLAYER_SLICE.md` for server/client commands, browser export instructions, validation steps and known limitations.

The original M7 one-human-versus-one-bot prototype remains available as `scenes/main.tscn` and is retained as a regression/reference implementation.

## Original pilot goal

Prove the core loop:

1. Move and look in first person.
2. Pick up a ball.
3. Charge and throw it with projectile physics.
4. Exchange the same ball with a computer-controlled opponent.
5. Catch an incoming ball during a short timing window.
6. Dodge laterally.
7. Resolve an elimination and automatically start the next round.

## Original prototype scope

The completed pilot uses one stylized indoor court, one player, one ball, and one simple ball-playing bot. It excludes multiplayer, polished art, progression, complex AI, complex menus, and production release work. A basic pause overlay provides resume, clean round restart, controls, and quit actions.

## Visual style

The court uses a clean painted-gym palette: bright blue for the player half, coral red for the opponent half, court green for the centre strip and perimeter, and warm-white lines. Dove-grey walls, dark-navy lower trim, a light-grey ceiling, and charcoal accents keep the ball, bot, crosshair, and boundaries easy to distinguish.

## Project controls

- `AGENTS.md` — current branch rules for AI coding agents.
- `docs/MULTIPLAYER_SLICE.md` — current 2v2 networking scope and validation.
- `docs/SPEC.md` — original pilot behaviour and acceptance criteria.
- `docs/ARCHITECTURE.md` — original prototype architecture.
- `docs/TASKS.md` — original implementation queue.
- `docs/TESTING.md` — original automated correctness validation.
- `docs/MILESTONES.md` — prototype implementation history and status.
- `docs/GAME_DESIGN.md` — long-term product intent and experience.
- `docs/GAMEPLAY_RULES.md` — current-versus-future rules and variations.
- `docs/STATE_MACHINES.md` — implemented and future state definitions.
- `docs/FUTURE_ARCHITECTURE.md` — conditional scalable architecture.
- `docs/DECISIONS.md` — major product and architecture decisions.
- `docs/ROADMAP.md` — conditional post-prototype sequence.
- `docs/KNOWN_LIMITATIONS.md` — limitations and unresolved questions.
- `docs/PLAYTESTING.md` — interactive validation strategy.

Implementation through M7 of the original prototype is complete, including the live/dead-ball lifecycle, basic bot exchange loop, and automatic round resolution/reset. Final prototype validation (M8) and the separately pending manual render-quality comparison (M5.2) remain historical validation gates for that path.

## Controls

- `WASD`: move
- Mouse: aim/look
- `Shift`: hold to sprint
- `Ctrl`: crouch in the legacy prototype
- `Space`: jump
- Left mouse: hold to charge, release to throw
- Right mouse: timed catch
- `E`: pick up/interact
- `Q`: dodge left
- `F`: dodge right

## Legacy prototype behaviour

The original bot retrieves the single available ball, faces the player, waits briefly, and throws. Catch with right mouse, dodge with Q/F, or retrieve a miss and throw it back. Only a direct live throw can eliminate the other participant; the first court-surface collision makes a throw dead, so later bounces cannot eliminate or be caught. A valid elimination displays the winner, locks gameplay briefly, then resets the existing player, bot, and ball in place and begins the next round automatically.

## Current multiplayer limitations

The new 2v2 branch is a first networking pass, not a production service. It has no account system, matchmaking backend, persistence, ranked ladder, progression, cosmetics or regional fleet. WAN interpolation, anti-cheat, browser deployment, TLS/WSS termination and real public-server load still require validation and iteration.
