# Pilot Specification

## Objective

Deliver a playable Godot 4 proof of concept demonstrating first-person dodgeball mechanics within a six-hour implementation budget.

## Required player actions

- Move with WASD.
- Aim with mouse look.
- Sprint while Shift is held.
- Jump from the ground.
- Crouch while Ctrl is held, without standing into an obstruction.
- Pick up the available ball when close enough.
- Hold the throw input to charge throw strength.
- Release to launch a physical projectile.
- Open a short catch window.
- Perform a short lateral dodge with a cooldown.

## Required game loop

- One grey-box indoor court.
- One player spawn.
- One ball spawn.
- One deliberately simple ball-playing bot at `TargetSpawn`.
- The bot retrieves only the single `AVAILABLE` ball with collision-safe
  `CharacterBody3D` movement, aims after a short configurable delay, throws
  toward the human, and repeats when that same ball becomes available.
- A newly released throw is live until its first collision with the floor,
  ceiling, a wall, or a valid participant.
- A direct live-ball hit from the other participant eliminates the bot or player
  exactly once and makes
  the ball dead.
- A dead ball remains physical and may bounce or roll, but cannot eliminate or
  be caught. After the pickup grace period, a sleeping or sufficiently slow
  dead ball becomes available again.
- A successful catch prevents elimination and gives possession.
- After elimination, the round can reset to its initial state.

## Pilot controls

- `WASD`: move
- Mouse: look
- `Shift`: hold to sprint
- `Ctrl`: hold to crouch
- `Space`: grounded jump
- Left mouse: hold to charge, release to throw
- Right mouse: catch attempt
- `E`: pick up/interact
- `Q`: dodge left
- `F`: dodge right
- `R`: restart the current round
- `F3`: toggle performance diagnostics
- `Escape`: toggle the pause menu

## Movement, restart, and pause

- Normal movement preserves the existing speed and collision handling; sprint,
  acceleration, jump, air control, crouch dimensions, and lateral dodge timing
  are configurable.
- Jump is grounded-only. Crouch changes both camera and collision height, and
  standing is refused while overhead space is obstructed.
- Dodge is orientation-relative, collision-safe, and cooldown-limited, with
  minimal HUD feedback while unavailable.
- Restart restores the existing player to `PlayerSpawn`, ball to `BallSpawn` in
  `AVAILABLE`, and bot to `TargetSpawn` active. It clears movement, camera
  pitch, crouch, dodge, catch, elimination, and feedback state without creating
  replacement entities.
- Escape is handled before gameplay input. The pause overlay releases the mouse,
  pauses gameplay physics, timers, movement, and actions, and continues
  processing while paused.
- The pause menu offers Resume, Restart Round, Controls, and Quit Game. Controls
  lists the fixed keyboard/mouse bindings and Back returns to the main panel.
  Menu restart performs the clean reset, resumes, and recaptures the mouse.
- Physics interpolation smooths rendered transforms between fixed physics
  updates. A diagnostic overlay may report FPS, frame time, physics time, draw
  calls, and rendered objects without changing gameplay or court presentation.

## Bot and throw ownership

- Bot states are explicit and mutually exclusive: `SEEK_BALL`, `MOVE_TO_BALL`,
  `HOLD_BALL`, `AIM`, `THROW`, `WAIT_FOR_BALL`, and `ELIMINATED`.
- Movement speed, acceleration, pickup range, aim delay, throw speed, recovery
  delay, target height offset, and deterministic aim error are configurable.
- Each live throw records `HUMAN` or `BOT`; a throw cannot eliminate its owner.
- Pickup, catch, dead-ball transition, availability, and reset clear thrower identity.
- Bot elimination stops all bot behaviour. Player elimination stops bot active play.

## Acceptance criteria

1. The project starts directly in the court.
2. The player can traverse the court and look freely without leaving valid bounds.
3. The player can pick up exactly one ball.
4. Throw speed visibly changes between a quick release and a full charge.
5. A thrown ball follows physical projectile motion and collides with court geometry.
6. A valid hit triggers an elimination state once, without duplicate scoring.
7. Floor, ceiling, or wall contact makes a live ball dead before any later hit,
	and bounced or dead balls cannot eliminate.
8. Catching succeeds only during a clearly bounded timing window and only for a
	live thrown ball.
9. A successful catch transfers the incoming ball to the player.
10. Dodging produces a short lateral displacement and cannot be spammed continuously.
11. Reset restores player, ball, bot, and round state.
12. Sprint, grounded jump, and obstruction-safe crouch preserve collision and
	diagonal movement behavior.
13. Pausing stops gameplay and prevents mouse or keyboard actions from passing
	through the overlay.
14. Five consecutive restarts leave exactly one player, one ball, and one bot.
15. Ten bot retrieve-and-throw cycles complete without duplicate balls, lost
	ownership, stuck states, or duplicate throws.

## Explicit exclusions

- Online or local multiplayer.
- Full netball mechanics.
- More than one functional opponent.
- Production-quality character models or animation sets.
- Economy, inventory, progression, campaign, achievements, or monetisation.
- Steam integration.
- Mobile or console builds.
