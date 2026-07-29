# Pilot Specification

## Objective

Deliver a playable Godot 4 proof of concept demonstrating first-person dodgeball mechanics within a six-hour implementation budget.

## Required player actions

- Move with WASD.
- Aim with mouse look.
- Pick up the available ball when close enough.
- Hold the throw input to charge throw strength.
- Release to launch a physical projectile.
- Open a short catch window.
- Perform a short lateral dodge with a cooldown.

## Required game loop

- One grey-box indoor court.
- One player spawn.
- One ball spawn.
- One stationary target or deliberately simple opponent.
- A valid ball hit eliminates the target or player.
- A successful catch prevents elimination and gives possession.
- After elimination, the round can reset to its initial state.

## Pilot controls

- `WASD`: move
- Mouse: look
- `E`: pick up ball
- Left mouse: hold to charge, release to throw
- Right mouse: catch attempt
- `Q` / `E` or another documented pair: lateral dodge, provided pickup remains unambiguous
- `R`: reset round during development

Final bindings may change if recorded in the README and kept internally consistent.

## Acceptance criteria

1. The project starts directly in the court.
2. The player can traverse the court and look freely without leaving valid bounds.
3. The player can pick up exactly one ball.
4. Throw speed visibly changes between a quick release and a full charge.
5. A thrown ball follows physical projectile motion and collides with court geometry.
6. A valid hit triggers an elimination state once, without duplicate scoring.
7. Catching succeeds only during a clearly bounded timing window.
8. A successful catch transfers the incoming ball to the player.
9. Dodging produces a short lateral displacement and cannot be spammed continuously.
10. Reset restores player, ball, target, and round state.

## Explicit exclusions

- Online or local multiplayer.
- Full netball mechanics.
- More than one functional opponent.
- Production-quality character models or animation sets.
- Economy, inventory, progression, campaign, achievements, or monetisation.
- Steam integration.
- Mobile or console builds.
