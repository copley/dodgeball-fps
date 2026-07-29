# AGENTS.md

## Mission

Build only the Godot 4 one-human-versus-one-basic-bot, one-court, one-ball
vertical slice defined by the governing documentation.

## Required workflow

1. Read this file, `README.md`, `docs/SPEC.md`, `docs/ARCHITECTURE.md`,
   `docs/TASKS.md`, `docs/TESTING.md`, and `docs/MILESTONES.md` before changing
   files.
2. Work on exactly one issue or task at a time.
3. Inspect existing scenes and scripts before editing them.
4. Make the smallest change that satisfies the current acceptance criteria.
5. Run the validation commands in `docs/TESTING.md`.
6. Update `docs/TASKS.md` only when a task is demonstrably complete.
7. Stop and report the blocker when validation fails or requirements conflict.

## Permanent gameplay invariants

- Keep exactly one human player, one basic deterministic bot, one court, and
  one physical ball.
- Keep gameplay offline only.
- `Main` owns spawning, round state, elimination, results, and reset.
- Ball and bot state transitions must remain explicit.
- Never duplicate entities, signals, ownership, throws, or elimination events.
- Preserve all completed gameplay, rendering, and diagnostic behaviour.
- All existing automated regression suites must pass.

## Scope constraints

Do not add:

- Online multiplayer or networking.
- Matchmaking, accounts, or backend services.
- Character progression, cosmetics, achievements, or monetisation.
- Multiple courts, complex menus, polished art, or cinematic content.
- AI beyond the basic deterministic behaviour required by the vertical slice.
- Third-party addons unless explicitly approved.

## Godot conventions

- Target Godot 4.x.
- Use GDScript for the pilot.
- Prefer typed variables, typed parameters, and typed return values.
- Use `snake_case` for files, variables, and functions.
- Use `PascalCase` for named classes.
- Keep scene-specific logic close to its scene.
- Prefer signals over hard-coded cross-scene paths.
- Avoid global singletons unless the specification explicitly requires one.
- Do not hand-edit imported Godot metadata.

## Git rules

- Never commit directly to `main`.
- Use one branch and pull request per scoped issue.
- Do not modify unrelated files.
- Use clear commit messages.
- Never mark work complete without automated validation evidence and recorded
  manual play-test requirements.

## Definition of done

A task is complete only when:

- Its acceptance criteria pass.
- The project opens without parse errors.
- Complete automated regression and headless validation succeeds.
- Relevant manual play-test checks are recorded.
- No out-of-scope features were added.
