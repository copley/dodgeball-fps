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

- [ ] **T6 — Lateral dodge and cooldown**
  - Add short left/right displacement with cooldown and boundary-safe movement.
  - Acceptance: dodge is responsive but cannot be continuously spammed.

- [ ] **T7 — Round reset and pilot validation**
  - Restore all entities and state after elimination or development reset.
  - Acceptance: repeated rounds do not accumulate duplicate balls, signals, or score events.

## Stop condition

Stop after T7. Any extra feature requires an explicit scope decision and a new issue.
