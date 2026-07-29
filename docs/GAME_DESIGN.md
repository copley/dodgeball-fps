# Game Design

## Document layer and authority

This document owns product intent and the desired player experience. It does
not redefine the current build; [SPEC.md](SPEC.md) remains normative for the
implemented prototype. Future statements are design intent, not implemented
features or approved implementation work.

## Product pitch

> A first-person arcade dodgeball simulator where up to 12 human and AI players
> compete in short, highly skill-based matches using accurate throws, catches,
> curves, dodges, blocks, positioning and team tactics. It should be easy for
> children and casual players to understand while rewarding precision,
> movement, court awareness and mechanical mastery.

The product vision is an offline-first, first-person arcade dodgeball simulator
inspired by the accessibility, repeatable rounds, local match hosting and bot
support of classic tactical shooters such as Counter-Strike: Condition Zero.
The intended destination is a cheerful, sports-oriented commercial indie Steam
release.

## Target audience and player fantasy

Children and casual players should quickly understand “throw, catch, dodge and
stay in,” while experienced players find depth in ball speed, trajectories,
positioning, prediction and coordinated tactics. The player fantasy is being a
skilled dodgeball athlete: reading the court in first person, making a precise
throw under pressure, committing to a fair catch, escaping by a narrow dodge,
or protecting a teammate with a block.

## Design pillars

1. **Readable arcade sport.** Recognizable dodgeball rules and clear feedback
   come before simulation detail.
2. **Easy entry, high mastery.** Basic actions are legible; their timing,
   accuracy and tactical combinations provide the skill ceiling.
3. **Short repeatable rounds.** Fast setup, local configuration and capable
   bots support “one more round.”
4. **Offline-first flexibility.** Solo and locally hosted matches should remain
   worthwhile without an online population.
5. **Cheerful competition.** Presentation is upbeat, non-violent and suitable
   for children without removing competitive depth.
6. **Configurable without ambiguity.** Named, data-driven ruleset presets make
   important variations explicit.

## Core design principle

> **Whenever realism conflicts with fun, this game should prioritize fun.**

Movement is grounded and human-like by default, emphasizing positioning and
court awareness. A mode may enable tactical slides or more agile arcade
movement when that improves play. Dodge rules may provide momentum, temporary
hitbox reduction, invulnerability frames, or a combination. The implemented
prototype dodge supplies lateral movement only and no invulnerability.

## Skill model

The intended skill areas are:

- throwing accuracy;
- throw velocity and charge control;
- throw trajectory selection;
- catching proficiency;
- dodge, duck and evasion agility;
- court awareness;
- spatial positioning;
- blocking and deflection;
- communication and team coordination;
- ball and possession awareness.

Difficulty and accessibility may widen catch timing, angle or volume
tolerances, but should preserve timing, aim/alignment and physical catch-volume
requirements. Bot difficulty should similarly cover reaction, tactics and
decision quality rather than only aim accuracy.

## Child-friendly tone

The game must avoid graphic injury, gore, realistic pain, violent impact
presentation, toxic or aggressive language, gambling systems and loot boxes.
Elimination feedback should sound like an upbeat sports call: `OUT!`,
`CAUGHT!`, `GREAT BLOCK!`, `PLAYER RETURNS!` or `ROUND WON!`.

## Implemented prototype

The current offline prototype contains exactly one human, one basic
deterministic bot, one court and one physical ball. It implements one
hold-and-release charged throw, a basic timed catch, a basic lateral dodge,
live/dead ball handling, direct single elimination, winner display and an
automatic clean in-place round reset. It is a narrow mechanic-validation slice,
not the full product.

The bot retrieves, aims and throws but does not catch, dodge, block, coordinate
or select advanced throws. Throwing satisfaction, catch fairness, dodge
usefulness and bot balance still require interactive M8 evaluation.

## Target Version 1.0

The intended Version 1.0 is offline-first and supports:

- customizable locally hosted matches with up to 12 total participants;
- arbitrary human and bot combinations and intentionally uneven teams,
  including 1 vs 11;
- one to six physical balls, with at most one held by each player;
- Standard Dodgeball and Prison Ball;
- robust configurable bots with human feature parity;
- selectable maps implementing a standard map contract;
- data-driven rulesets and named presets;
- high-quality throwing, catching and responsive movement.

The required Version 1.0 scope currently stated is excellent throwing and
catching, responsive movement, both named modes, robust offline bots, local
match configuration and standardized map contracts. Controller support is a
very high priority, but whether it is a mandatory Version 1.0 release gate is
an open decision.

Technical priority order is:

1. Excellent throwing and catching.
2. Controller support.
3. Strong bots.
4. Online multiplayer.
5. Multiple game modes.
6. Maps.
7. Polished visuals.
8. Progression.

This ordering expresses priority, not a claim that online multiplayer belongs
to the required Version 1.0 scope.

## Competitive and custom play

Official or ranked servers should use locked standardized rulesets. Casual and
custom servers may allow uneven teams, custom ball counts, modified catch
rules, movement variants, friendly fire, custom match formats and unusual bot
configurations.

## Long-term possibilities

Possible later phases include LAN multiplayer, Internet server multiplayer,
humans-only or mixed human/bot servers, community hosting, Steam Workshop maps,
custom rulesets, server-side plugins, competitive and ranked servers,
matchmaking and broader progression. Advanced server-browser plugins, deep
cosmetic progression, large Workshop integration, complex matchmaking ladders,
broad progression and advanced community administration are post-release or
later work. None is implemented or approved by this vision document.
