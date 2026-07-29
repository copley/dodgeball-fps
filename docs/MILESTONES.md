# One-Ball Prototype Milestones

## Product goal

Build a first-person dodgeball game in Godot with:

- One human player.
- One computer-controlled opponent.
- Exactly one physical ball.
- Throwing, catching, dodging, elimination, and round reset.

The prototype is successful when the human and bot can repeatedly exchange possession of the same ball until one is eliminated, then start another clean round.

## Scope rules

- Keep exactly one human, one bot, one court, and one ball.
- Develop offline gameplay only.
- Use first-person control for the human player.
- Prefer simple, deterministic behaviour over advanced simulation.
- Complete and validate milestones sequentially.
- Do not add a feature unless it directly supports the one-ball round loop.

## Explicit exclusions

Do not add:

- Teams or additional players.
- Additional balls or ball types.
- Online multiplayer, matchmaking, accounts, or backend services.
- Campaigns, tournaments, progression, cosmetics, or monetisation.
- Multiple courts, character classes, special abilities, or equipment.
- Advanced tactical AI.
- Production-quality art or animation.
- Steam integration before the gameplay prototype is complete.

## Milestone overview

| Milestone | Outcome | Status |
| --- | --- | --- |
| M1 | Playable first-person court | Complete |
| M2 | One-ball pickup and throwing | Complete |
| M3 | Valid hit and dead-ball handling | In progress |
| M4 | Timed catching and possession transfer | Complete |
| M4.5 | Basic painted court graphics | Complete |
| M5 | Complete player controls, lateral dodge, restart, and pause menu | Complete |
| M5.1 | Physics interpolation and performance diagnostics | Complete |
| M5.2 | Render quality and visual smoothness | Validation pending |
| M6 | Basic ball-playing bot | Planned |
| M7 | Complete elimination and reset loop | Planned |
| M8 | Prototype validation and stop decision | Planned |

## Current implementation checkpoint

Movement, sprint, grounded jump, safe crouch, lateral dodge, clean restart,
pickup, charged throwing, target elimination, and timed catching are complete.
The basic painted-court visual pass and basic pause/controls menu are also
complete. Dead-ball handling after floor, wall, or ceiling contact is still
incomplete.

## M5.1 — Performance smoothing and diagnostics

### Deliverables

- Global physics interpolation for smoother rendered motion.
- Teleport-safe interpolation resets for the player, ball, and target.
- Toggleable F3 diagnostics for FPS, frame time, physics time, draw calls, and
  rendered objects.

### Exit criteria

- Round restart does not interpolate entities from their previous positions.
- Diagnostics identify the likely performance category without changing court
  visuals or gameplay values.
- Existing gameplay and court regression suites still pass.

## M5.2 — Render quality and visual smoothness

### Baseline

The original test-machine baseline at 1280×720 was approximately 60 FPS,
16.1–16.7 ms frame time, 0.7–0.9 ms physics time, 65–84 draw calls, and
228–250 rendered objects.

### Selected configuration

- Retain Forward+ and native 100% 3D render scale.
- Use 2× MSAA as the single 3D anti-aliasing method. Screen-space
  anti-aliasing remains disabled.
- Enable VSync for sensible pacing on a 60 Hz display.
- Use one real-time shadow-casting directional light with a 2048-pixel
  directional shadow map and a 35-metre shadow distance.
- Raise ambient energy moderately for even court readability. SSAO, SSIL, SSR,
  glow, volumetric fog, motion blur, dynamic resolution, and FSR remain off.
- Keep floor, wall, marking, ball, and target materials non-metallic with
  painted-surface roughness. Use a brighter orange ball and warm-white target
  for separation across the blue, red, and green floor zones.
- Keep visual-only court markings collision-free. Boundary marking centres sit
  at 0.035 m, leaving at least 0.007 m between their lower faces and the top of
  the painted floor-zone meshes.
- Reset ball interpolation whenever pickup, catch, or throw changes its
  transform so interpolation never uses a stale pre-transition transform.

### Interactive 2× versus 4× MSAA comparison

1. Run the project at 1280×720 with F3 visible and play ordinary movement,
   jumps, crouches, dodges, pickups, and throws for at least one minute.
2. Record FPS, average and maximum frame time, physics time, draw calls, and
   objects with `rendering/anti_aliasing/quality/msaa_3d=1` (2×).
3. Exit, change that setting to `2` (4×) in Project Settings, repeat the same
   route and actions, and compare court-line and silhouette edges.
4. Restore `1` unless 4× holds approximately 60 FPS, an average near 16.7 ms,
   and no persistent ordinary-play spikes on the Quadro M4000.

### Exit criteria

- Automated render-quality invariants and all gameplay regression suites pass.
- Manual 1280×720 comparison confirms smoother edges, depth-stable markings,
  readable ball/target/crosshair, smooth motion and resets, and baseline-class
  frame pacing.
- Keep this milestone validation pending until that manual comparison is
  recorded.

## M4.5 — Basic painted court graphics

### Deliverables

- Blue player half and coral-red opponent half.
- Green centre strip and perimeter apron.
- Warm-white boundary, centre, circle, activation, and ball-position markings.
- Subtle visual indicators at the unchanged player, ball, and target spawns.
- Dove-grey gym walls with dark lower trim and simple charcoal panel accents.

### Exit criteria

- All graphics are procedural, visual-only meshes with no collision.
- Existing court collision, spawn transforms, and T1–T5 gameplay remain unchanged.

## M1 — Playable first-person court

### Deliverables

- Godot project starts directly in one grey-box court.
- Human player moves with WASD.
- Mouse look is captured, clamped, and releasable.
- Court collision prevents the player leaving the playable area.
- Crosshair provides a clear aiming reference.

### Exit criteria

- Movement and mouse look remain stable for a full play-test session.
- The project opens and runs without parser, scene, or missing-resource errors.

## M2 — One-ball pickup and throwing

### Deliverables

- Exactly one ball exists.
- An available ball can be picked up within a bounded range.
- The held ball follows a visible first-person hold position.
- Holding the throw input charges throw strength.
- Releasing the input launches the physical ball.
- Quick and fully charged throws produce visibly different speeds.
- A slow or stationary ball becomes available for pickup again.

### Exit criteria

- The player cannot hold more than one ball.
- The ball cannot be held, available, and thrown simultaneously.
- Repeated pickup and throw cycles do not duplicate or lose the ball.

## M3 — Valid hit and dead-ball handling

### Deliverables

- A newly thrown ball is live.
- A direct live-ball impact can eliminate a valid player or bot target.
- Contact with the floor, wall, ceiling, or another dead surface makes the ball dead.
- A dead ball cannot eliminate either participant.
- One throw can produce at most one elimination event.
- A dead, slow, or stationary ball becomes available for retrieval.

### Exit criteria

- A direct throw eliminates exactly once.
- A bounced ball never eliminates.
- Slow incidental contact never eliminates.
- Collision order does not create duplicate results.

## M4 — Timed catching and possession transfer

### Deliverables

- Catch input opens a short, visible catch window.
- Only a live incoming ball is eligible to be caught.
- A successful catch prevents elimination.
- A successful catch transfers the same ball into the catcher’s possession.
- Early and late catch attempts fail.
- The ball cannot remain thrown while also being held.
- Deterministic tests create incoming throws through the normal
  `AVAILABLE -> HELD -> THROWN` state path.

### Exit criteria

- Correctly timed catches succeed consistently.
- Mistimed catches allow a valid hit.
- One incoming ball cannot be caught twice.
- Catch success never creates another ball.

## M5 — Player controls, lateral dodge, restart, and pause menu

### Deliverables

- The human can dodge left and right.
- Dodge produces a short lateral velocity burst or displacement.
- A cooldown prevents continuous dodge spam.
- Dodge respects court collision and boundaries.
- Normal movement resumes immediately after the dodge.
- Minimal feedback communicates when dodge is unavailable.
- Shift sprint, grounded Space jump, and hold-Ctrl safe crouch complete the
  keyboard/mouse movement layout.
- R cleanly restores the existing player, ball, and target.
- Escape pauses gameplay and opens Resume, Restart Round, Controls, and Quit
  Game actions while releasing the mouse.

### Exit criteria

- Dodging can avoid a valid incoming throw.
- The player cannot pass through court geometry.
- Repeated dodge attempts cannot bypass the cooldown.
- Five consecutive keyboard or menu resets retain exactly one player, one ball,
  and one target.
- Gameplay physics and inputs do not run through the pause overlay.

## M6 — Basic ball-playing bot

### Bot responsibilities

- Detect the one available ball.
- Move toward and retrieve it.
- Face the human player.
- Wait for a simple configurable aiming delay.
- Throw the ball toward the human.
- Retrieve a missed or dead ball and repeat.
- Be hit and eliminated by a valid human throw.
- Stop acting after elimination.

### Behaviour constraints

- Use a small explicit state machine such as:

```text
SEEK_BALL -> MOVE_TO_BALL -> HOLD_BALL -> AIM -> THROW -> SEEK_BALL
                                               -> ELIMINATED
```

- The bot does not require pathfinding beyond what the single court needs.
- The bot does not require team tactics, personalities, advanced prediction, or difficulty classes.
- Basic catch or dodge behaviour may be added only after retrieve-and-throw behaviour is reliable.

### Exit criteria

- The bot can sustain at least ten retrieve-and-throw cycles without becoming stuck.
- The bot never creates, replaces, or loses the ball.
- The human receives repeatable incoming throws suitable for catch and dodge testing.

## M7 — Complete elimination and reset loop

### Deliverables

- A valid hit eliminates the human or bot.
- Elimination immediately ends active play.
- A minimal result message identifies the round winner.
- Reset restores:
  - One active human at the human spawn.
  - One active bot at the bot spawn.
  - One available ball at the ball spawn.
  - Hidden or cleared result feedback.
  - Cleared catch, dodge, throw, and elimination state.
- Development reset input can restart the round at any time.

### Exit criteria

- Five consecutive automatic or manual resets produce no duplicate entities, signals, hits, or result events.
- Resetting while the ball is available, held, thrown, caught, or dead produces the same clean initial state.

## M8 — Prototype validation and stop decision

### Automated validation

- Run Godot headless project validation.
- Run the main scene headlessly long enough to expose startup errors.
- Add deterministic checks for ball-state transitions and duplicate elimination prevention where practical.

### Manual validation

Confirm all of the following:

- The human can move and aim predictably.
- The same ball can be retrieved and thrown by both participants.
- Direct live-ball hits eliminate.
- Bounced or dead balls do not eliminate.
- Timed catches transfer possession.
- Mistimed catches fail.
- Dodging can avoid a throw and respects its cooldown.
- The bot repeatedly retrieves and throws the ball.
- Either participant can win a round.
- Reset always restores exactly one human, one bot, and one ball.

### Final prototype exit criteria

The prototype is complete when:

> One human and one bot can repeatedly retrieve, throw, catch, and dodge the same ball until a valid elimination ends the round, after which the game resets cleanly and can be played again.

After this milestone, stop development and make an explicit decision based on play-testing:

1. Refine the one-ball game because the loop is fun.
2. Rework the mechanics because the loop is not yet fun.
3. Approve a separately scoped expansion.

Do not expand the project automatically.
