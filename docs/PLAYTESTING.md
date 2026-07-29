# Interactive Play-Testing

## Purpose and authority

This guide owns subjective interactive validation. [TESTING.md](TESTING.md)
owns automated correctness commands. M8 asks whether the implemented one-ball
loop is understandable, fair and enjoyable enough to continue, revise or stop.

Headless tests can prove state transitions, entity counts, signal uniqueness
and reset behaviour. They cannot establish that throwing feels satisfying,
catches feel fair, dodge feels useful, the bot feels balanced, menus are
understandable, audio works experientially or visuals read well in motion.

## Ten-round M8 procedure

Use [playtests/TEMPLATE.md](playtests/TEMPLATE.md) for evidence.

1. Record build/commit, machine, display, input method and relevant settings.
2. Start from a clean project launch and confirm the court and controls are
   understandable without code inspection.
3. Play at least ten consecutive interactive rounds. Alternate deliberate
   attempts to throw, catch and dodge; allow both human and bot wins.
4. During the run, exercise direct hits, misses that become dead/available,
   mistimed and successful catches, dodge cooldown, automatic reset, pause
   during results, R restart and pause-menu restart.
5. Confirm every round retains exactly one human, one bot and one ball, with no
   duplicate result, lost possession, frozen input or stale delayed reset.
6. Observe F3 diagnostics and visual motion. Record, but do not silently fix,
   render defects or performance anomalies.
7. After round ten, summarize patterns rather than treating one event as a
   balance conclusion.

## What to record

- per-round winner and approximate duration;
- throws attempted and whether charge/speed/trajectory felt controllable;
- catch attempts, timing/alignment expectation and perceived fairness;
- dodge attempts, outcome, cooldown readability and usefulness;
- bot retrieval, aim, throw, stuck or repetitive behaviour;
- dead-ball readability, possession awareness and round-state clarity;
- menu comprehension, pause/restart behaviour and control discovery;
- audio presence/absence and useful or confusing feedback;
- visual defects, readability and F3 performance context;
- reproducible correctness failures separately from subjective preferences;
- accessibility observations and suggested follow-up experiments.

Do not claim balance from ten rounds; the run is a prototype decision gate.

## Severity

- **Blocker:** crash, parse failure, lost/duplicated entity, unrecoverable round,
  repeated incorrect ruling or test-invalidating setup.
- **High:** frequent unfair or unclear core mechanic that prevents meaningful
  evaluation.
- **Medium:** repeatable issue that harms play but permits the round loop.
- **Low:** minor clarity, polish or isolated comfort issue.
- **Observation:** hypothesis or preference needing more evidence.

## Decision criteria

- **Continue:** the core exchange is understandable and promising; no blocker
  undermines the evidence; approve a separately scoped next milestone.
- **Revise:** the concept remains promising but one or more core mechanics need
  focused rework and another validation cycle before expansion.
- **Stop:** the loop is not promising enough to justify further work, or a
  fundamental issue invalidates the intended product direction.

No outcome is preselected. A blocker stops the run, is recorded, and must be
resolved before claiming M8 completion.
