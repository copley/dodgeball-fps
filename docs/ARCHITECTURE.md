# Architecture

## Intended structure

```text
dodgeball-fps/
├── project.godot
├── AGENTS.md
├── README.md
├── docs/
│   ├── SPEC.md
│   ├── ARCHITECTURE.md
│   ├── TASKS.md
│   └── TESTING.md
├── scenes/
│   ├── main.tscn
│   ├── court.tscn
│   ├── player.tscn
│   ├── ball.tscn
│   ├── target.tscn
│   └── ui.tscn
├── scripts/
│   ├── main.gd
│   ├── player.gd
│   ├── ball.gd
│   ├── target.gd
│   └── ui.gd
└── assets/
	├── materials/
	├── models/
	├── textures/
	└── audio/
```

## Node responsibilities

- `Main`: owns round state, initial spawning, elimination, in-place reset, and
  pause-menu coordination.
- `Court`: static collision and spawn markers only.
- `Player`: normal/sprint movement, grounded jump, safe crouch, mouse look,
  possession, throw charging, catch window, and collision-safe dodge cooldown.
- `Ball`: physical motion, ownership state, collision reporting, pickup eligibility, and reset.
- `Target`: receives valid hits and reports elimination.
- `UI`: crosshair, minimal catch/dodge/result indicators, and the basic
  pause/controls overlay. It also owns a read-only F3 performance label.

## Communication

Use signals for major events such as:

- ball picked up
- ball thrown
- valid hit
- catch succeeded
- entity eliminated
- round reset

`Main` coordinates the round. Player and ball should not directly own global round state.

`Main.restart_round()` resets the existing player, ball, and target through
their reset methods. It must not instantiate replacements or reconnect signals.
`Main` also handles Escape and R before ordinary player input. Its process mode,
and the pause overlay's process mode, remain active while the `SceneTree` is
paused; gameplay nodes retain normal processing and therefore stop.

Global physics interpolation smooths visual transforms between physics ticks.
Entity reset methods call `reset_physics_interpolation()` after teleporting so
a round restart does not render a sweep from the old transform. `Main` records
render-frame deltas in a bounded 120-sample window and updates the F3 label from
that window and read-only `Performance` monitors four times per second. The
diagnostics do not modify simulation values or select quality settings.

## State boundaries

Ball state should be explicit and mutually exclusive:

```text
AVAILABLE -> HELD -> THROWN -> DEAD -> AVAILABLE
                    -> CAUGHT -> HELD
```

`THROWN` is the only live-ball state. A direct valid participant hit emits one
valid-hit signal and immediately transitions to `DEAD`. Catching is permitted
only from `THROWN`; `CAUGHT` is the explicit transfer transition before `HELD`.
The floor, ceiling, left wall, right wall, near wall, and far wall belong to the
`dead_ball_surface` group. First contact between a live ball and any member of
that group transitions the ball to `DEAD` without relying on node names.
`DEAD` balls remain unfrozen rigid bodies until the existing grace period has
elapsed and they are sleeping or below the pickup-speed threshold, at which
point they become `AVAILABLE`.

Player state remains lightweight:

```text
ACTIVE
CATCHING
DODGING
ELIMINATED
```

Avoid introducing a general-purpose framework or ECS for the pilot.
