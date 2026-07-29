# Gameplay Rules

## Scope layers

- **Implemented prototype:** normative behaviour is in [SPEC.md](SPEC.md). It
  has one human, one deterministic bot, one court, one physical ball and one
  direct elimination per live throw.
- **Target Version 1.0:** intended configurable offline rules for up to 12
  participants and one to six balls. These rules are not implemented.
- **Long-term possibilities:** network and community rules are conditional,
  later work.

This document owns current-versus-future rule intent. A future option is not a
current-build promise.

## Shared terminology

- **Active player:** eligible to move, possess balls and be eliminated.
- **Live ball:** an airborne thrown ball that can produce ruleset outcomes.
- **Dead surface:** a court or out-of-play contact that ends live flight.
- **Possession:** control of one held ball; each player may hold at most one.
- **Eliminated:** no longer active for the current round, subject to mode rules.
- **Revival:** return from an eliminated or prisoner state.
- **Ruleset:** selected data that decides catches, hits, revival, friendly fire,
  blocking, openings, timing and victory.
- **Authoritative event:** the ordered ruling accepted by the match authority.

## Match configuration — Target Version 1.0

The minimum practical team size is one; total participants are capped at 12.
Team allocation may be intentionally uneven: 1v1, 1v6, 1v11, 6v6, four humans
plus eight bots, or any other allocation within the total limit. Uneven
matches are a valid host choice. Possible handicap systems are not specified.

Matches support one to six balls. Each player may hold only one ball. “Local
multiplayer” means future LAN hosting, not split-screen; Internet multiplayer
is later.

Named presets may include Traditional 6v6, Casual Prison Ball, 1v11 Challenge,
Fast Multi-Ball and Custom Server Rules.

## Standard Dodgeball — Target Version 1.0

- Two teams occupy opposite halves and cannot physically cross the centre line
  or leave the playable court.
- Illegal movement is prevented; line crossing does not itself eliminate.
- A team wins when its opponent has no active players.
- Eliminated players move to a sideline or spectator state.
- A clean catch may eliminate the thrower, revive a teammate and/or transfer
  possession, as configured by the ruleset.
- Revival order is configurable. FIFO—first eliminated, first revived—is the
  default traditional policy.

## Prison Ball — Target Version 1.0

- Eliminated players move behind the opposing team into a bounded prison zone.
- Prisoners can move within their prison boundary and receive teammate passes.
- A successful teammate resurrection pass may revive a prisoner.
- Rulesets decide whether prisoners can collect stray balls or throw at
  opponents.
- Catching an opponent throw does not normally revive a prisoner; an arcade
  ruleset may permit it.
- A prisoner cannot be eliminated again while already imprisoned.
- Revival returns the player to a safe spawn on their own side by default.
- A short configurable protection period may prevent immediate spawn
  elimination.

## Round openings — Target Version 1.0

Supported openings are a traditional centre-line rush, balls pre-assigned to
teams, balls near team baselines, and custom arcade starting positions.

With activation required:

```text
retrieve centre ball -> return behind activation line -> ball becomes throwable
```

With activation disabled:

```text
retrieve ball -> ball is immediately throwable
```

The round uses a visible synchronized `3 -> 2 -> 1 -> GO` countdown. Players
remain locked or restricted to starting zones until `GO`.

## Throwing

The implemented prototype has one standard charged throw using hold-and-release
power. Future intended types are:

1. Standard flat or fast throw.
2. Lob or arc throw.
3. Rolling throw.
4. Curve or spin throw.

Future input may use Shift/Ctrl modifiers, separate actions or selectable throw
modes. No final input layout is selected.

## Catching and revival — Target Version 1.0

A catch should require correct timing, aim/alignment toward the incoming ball
and entry into the player's catch/hand volume. Accessibility and difficulty can
alter the timing window, catch angle and volume tolerance without removing
those underlying skills.

Catch effects are ruleset-controlled: possession transfer, thrower elimination
and teammate revival are separate decisions. Standard revival order defaults
to FIFO. Prison Ball normally revives through a teammate resurrection pass,
not an opponent-throw catch.

The prototype implements a timed human catch with range, forward and incoming
direction checks, but has no revival or configurable catch effects.

## Live balls, deflection and multi-hit chains — Target Version 1.0

A live airborne ball may eliminate multiple players before a dead-surface
contact. A struck player stays eliminated even if a teammate later catches the
same ball; that catch may still apply configured effects against the thrower.
A player or held-ball deflection remains live, and a teammate may catch it
before dead-surface contact.

Each flight tracks collision and hit history. A ball must not eliminate the
same player twice in one live-flight sequence. Relevant metadata is defined in
[STATE_MACHINES.md](STATE_MACHINES.md).

The prototype deliberately accepts at most one elimination per throw. It does
not implement deflection chains or multi-elimination.

## Blocking — Target Version 1.0

A player may use a held ball to block an incoming live ball. The incoming ball
may remain live and catchable. If the held blocking ball is knocked away and
later reaches a dead surface, the defender may be eliminated according to the
ruleset. Blocking and friendly-fire consequences are configurable.

## Friendly fire — Unresolved default

A ruleset may make friendly throws pass harmlessly, collide physically without
elimination, or apply full friendly fire. No universal default is finalized.

## Player collision and movement

Opponents must not clip through one another; physical interaction and
body-blocking are intended. The teammate-collision default is unresolved and
may become configurable.

Grounded, human-like movement is the default. Modes may enable tactical slides
or more agile dodges. Dodge can provide momentum, temporary hitbox reduction,
invulnerability frames or combinations. The prototype dodge has momentum only
and no invulnerability.

## Round victory, match formats and sudden death

Configurable formats are single round, first to N wins, best of N, timed match
and custom server-defined structure. Timing may be unlimited or configurable,
with optional sudden death.

Possible sudden-death policies include reduced playable area, removal of
neutral balls, altered ball availability, overtime, replay or
immediate-elimination conditions. None is selected universally.

Simultaneous final eliminations require a configurable draw, replay, overtime,
sudden-death, first-authoritative-event or mode-specific ruling.

## Bot rules — Target Version 1.0

Humans and bots should eventually use the same `PlayerAvatar` and action
constraints. Bots should throw, catch, block, dodge, use advanced throws,
coordinate and participate in Prison Ball. Difficulty may vary reaction delay,
aim, strength, catch timing, dodge intelligence, positioning, tactics,
teamwork, throw selection and deliberate mistakes. The current bot is basic
and deterministic.
