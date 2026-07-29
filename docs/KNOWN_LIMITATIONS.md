# Known Limitations and Open Questions

## Implemented prototype limitations

- Exactly one human, one deterministic bot, one court and one physical ball.
- Offline keyboard/mouse play only; no controller, LAN or Internet support.
- One standard charged throw; no lob, roll, curve or spin modes.
- The human has a basic timed catch and lateral dodge; the dodge has no
  invulnerability.
- The bot retrieves, aims and throws but does not catch, dodge, block,
  coordinate or use advanced throws.
- Each live throw accepts at most one elimination; no multi-hit or deflection
  chains.
- Direct elimination only; no teams, revival, Prison Ball, scores, match
  formats or sudden death.
- One court scene without a formal map contract.
- Basic pause menu and diagnostics, not production UI/audio/visual polish.

## Pending evaluation

No subjective conclusion may be inferred from headless tests. Pending evidence:

- the bot has not received sufficient interactive evaluation;
- throwing satisfaction has not been assessed;
- catch fairness has not been assessed;
- dodge usefulness has not been assessed;
- menu usability has not been assessed;
- audio is not yet meaningfully evaluated;
- detailed visual defects are not fully catalogued;
- the ten-round M8 play-test is incomplete;
- the M5.2 manual render comparison is pending.

See [PLAYTESTING.md](PLAYTESTING.md) and
[playtests/TEMPLATE.md](playtests/TEMPLATE.md).

## Unresolved design decisions

- Whether controller support is a mandatory Version 1.0 release gate.
- The default teammate-collision policy.
- The first implementation milestone after M8.
- The universal friendly-fire default.
- A final advanced-throw input layout.
- Default sudden-death and simultaneous-final-elimination policies.
- Any future handicap system for uneven teams.

## Intentional current exclusions

The prototype excludes extra players/balls/courts, advanced AI, networking,
matchmaking, accounts, backend services, progression, cosmetics, achievements,
monetisation, complex menus, polished art and cinematic content. These are
scope controls, not undocumented current features.

## Long-term features not implemented

LAN and Internet multiplayer, human/bot servers, community hosting, Workshop
maps, custom server rules/plugins, ranked servers, matchmaking and progression
are possibilities only. [ROADMAP.md](ROADMAP.md) keeps them conditional.
