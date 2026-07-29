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

- [ ] **T7 — Round reset and pilot validation**
  - Perform final prototype validation and close remaining one-ball loop gaps.
  - Acceptance: all pilot mechanics pass the final manual play-test without
	duplicate entities, signals, or elimination events.

## Stop condition

Stop after T7. Any extra feature requires an explicit scope decision and a new issue.
