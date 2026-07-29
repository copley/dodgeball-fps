# Ordered Task Queue

Complete tasks sequentially. Each implementation task should have its own branch and pull request after the planning PR is merged.

- [x] **T1 — Bootstrap Godot project and grey-box court**
  - Create `project.godot`, main scene, court geometry, collision, spawn markers, and basic crosshair.
  - Acceptance: project opens directly into a bounded court without parse errors.

- [x] **T2 — First-person movement and mouse look**
  - Implement WASD movement, gravity, mouse capture, and stable camera look.
  - Acceptance: player can traverse the court predictably and cannot pass through boundaries.

- [x] **T3 — Ball pickup and charged physical throw**
  - Implement one-ball possession, pickup range, charge duration, release velocity, and reset behaviour.
  - Acceptance: quick and full-charge throws are visibly different and use physical collisions.

- [x] **T4 — Target hit and elimination**
  - Add a stationary target or deliberately simple opponent and valid-hit processing.
  - Acceptance: a thrown ball eliminates exactly once and exposes round result state.

- [x] **T5 — Timed catch**
  - Add a bounded catch window and successful possession transfer.
  - Acceptance: correctly timed catches prevent elimination; early and late attempts fail.

- [x] **T5.5 — Basic court graphics pass**
  - Add a stylized painted court, visual-only markings, gym wall treatment, and a readable indoor palette.
  - Acceptance: court colours and markings are visible, collision and spawn transforms are unchanged, and T1–T5 validation still passes.

- [x] **T6 — Player movement actions, lateral dodge, restart, and pause menu**
  - Add sprint, grounded jump, obstruction-safe crouch, short left/right dodge
	with cooldown and boundary-safe movement, in-place round restart, and a
	basic pause/controls menu.
  - Acceptance: movement remains collision-safe and normalized; jump cannot
	double-fire; crouch cannot stand into an obstruction; dodge is responsive
	but cannot be spammed; pause blocks gameplay; five restarts retain exactly
	one player, one ball, and one target.

- [x] **T6.1 — Performance smoothing and diagnostics**
  - Enable physics interpolation with teleport-safe resets and add an F3 overlay
	for FPS, frame time, physics time, draw calls, and rendered objects.
  - Acceptance: visual transform interpolation is enabled, diagnostics can be
	toggled, and court design and gameplay values remain unchanged.

- [x] **T6.3 — Live and dead ball handling**
  - Add explicit live/dead ball transitions, identify every physical court
	surface through the `dead_ball_surface` group, and prevent post-bounce hits
	or catches while preserving physical settling and re-pickup.
  - Acceptance: direct live hits emit exactly once; floor, ceiling, and all four
	walls make the ball dead; dead balls cannot eliminate or be caught; slow or
	sleeping dead balls become available; reset and all gameplay regressions pass.

- [ ] **T6.2 — Render quality and visual smoothness**
  - Configure low-cost anti-aliasing and frame pacing, improve court depth and
	material readability, and extend F3 with rolling frame-time diagnostics.
  - Acceptance: automated render invariants and gameplay regressions pass, and
	a recorded 1280×720 manual comparison confirms stable 60 FPS-class pacing,
	depth-stable lines, clear silhouettes, and smooth motion.

- [x] **T6.4 — Basic ball-playing bot**
  - Add one reusable `CharacterBody3D` bot that retrieves the single available
	ball, aims, throws toward the player, and repeats through the dead-ball lifecycle.
  - Add thrower ownership, self-hit rejection, bidirectional elimination,
	pause-safe behaviour, and clean in-place reset.
  - Acceptance: one player, one bot, and one ball sustain ten deterministic
	retrieve-and-throw cycles and all prior regression suites pass.

- [x] **T7 — Round reset and pilot loop completion**
  - Add explicit round states, single-winner acceptance, result feedback,
	pause-aware automatic reset, cancellation-safe manual reset, and in-place
	entity restoration.
  - Acceptance: automated gameplay regressions and twenty deterministic rounds
	pass without duplicate entities, signals, ownership, timers, results, or
	elimination events. Required manual M7 checks are recorded in
	`docs/TESTING.md`.

## Stop condition

Proceed only to M8 prototype validation and stop decision. Any extra feature
requires an explicit scope decision and a new issue.
