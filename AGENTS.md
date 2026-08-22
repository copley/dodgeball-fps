# AGENTS.md

## Mission

Preserve the completed one-human-versus-one-bot prototype while developing the
approved 2v2 browser multiplayer vertical slice on the
`feature/2v2-browser-multiplayer-slice` branch.

The original prototype remains a regression reference. New product work lives
behind the multiplayer entry point and must not silently break the legacy
single-player scene.

## Required workflow

1. Read this file, `README.md`, `docs/SPEC.md`, `docs/ARCHITECTURE.md`,
   `docs/TASKS.md`, `docs/TESTING.md`, `docs/MILESTONES.md`, and
   `docs/MULTIPLAYER_SLICE.md` before changing gameplay files.
2. Inspect existing scenes and scripts before editing them.
3. Prefer additive migration over rewriting proven prototype mechanics.
4. Keep server authority explicit for competitive state.
5. Run the validation commands in `docs/TESTING.md` whenever a Godot runtime is
   available.
6. Record known manual/browser/network checks that cannot be established by
   headless tests.

## Legacy prototype invariants

The existing `scenes/main.tscn` prototype must continue to preserve:

- one human player, one deterministic bot, one court, and one physical ball;
- offline operation;
- the existing pickup, charge/throw, catch, dodge, elimination, reset, pause,
  rendering and diagnostics behaviour;
- explicit ball and bot state transitions;
- no duplicate entities, signals, ownership, throws, or elimination events.

These invariants apply to the legacy prototype path, not to the separately
approved multiplayer scene.

## Approved multiplayer-slice scope

The multiplayer vertical slice may add:

- exactly two teams with up to two active slots per team;
- human players connected over Godot high-level multiplayer using WebSockets;
- deterministic bots filling unoccupied match slots;
- multiple physical dodgeballs;
- a short timed score match with respawn after elimination;
- server-authoritative possession, throws, catches, hits, score and match time;
- browser-compatible client rendering and input;
- native/headless dedicated-server startup;
- lightweight lobby/status UI needed to connect and play.

Do not add accounts, persistence, ranked ladders, payments, inventory,
monetisation, social graphs, complex matchmaking, multiple maps, polished art,
or third-party addons in this slice.

## Multiplayer invariants

- The server is the only authority for score, eliminations, possession, ball
  state, match clock, slot assignment and bot substitution.
- Clients send player intent, never authoritative outcomes.
- A connected human replaces only the bot assigned to that slot.
- A disconnected human is replaced by a bot without ending the match.
- Team identity is immutable during an active match.
- Friendly-fire hits do not score.
- One live throw can score at most one elimination.
- Browser clients never host the public match; the public server is native or
  headless and accepts WebSocket clients.

## Godot conventions

- Target Godot 4.x.
- Use GDScript.
- Prefer typed variables, typed parameters, and typed return values.
- Use `snake_case` for files, variables, and functions.
- Use `PascalCase` for named classes.
- Prefer signals and explicit ownership boundaries over global mutable state.
- Avoid third-party addons for the vertical slice.

## Git rules

- Never commit directly to `main`.
- Keep product-expansion work on the approved feature branch until reviewed.
- Do not modify unrelated files.
- Use clear commit messages.
- Do not claim browser or network validation that was not actually run.

## Definition of done for this branch

The branch is a usable vertical slice when:

- the legacy prototype still parses;
- the multiplayer scene can run a 2v2 match with bots filling empty slots;
- two real clients can connect to a native/headless server and occupy different
  match slots;
- movement, pickup, charged throw, catch, dodge, hit, respawn, scoring and the
  match clock are server-authoritative;
- the same client build is suitable for Godot Web export;
- disconnecting a client replaces that player with a bot;
- a documented local validation procedure exists for server, desktop clients,
  and browser clients.
