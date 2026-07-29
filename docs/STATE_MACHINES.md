# State Machines

## Scope and notation

The first three diagrams describe implemented prototype code. Later diagrams
describe target states only and are not implemented. State authority and
transition details must remain explicit.

## Implemented prototype round state

`Main` owns this state and accepts gameplay and elimination only in `ACTIVE`.

```mermaid
stateDiagram-v2
    [*] --> STARTING
    STARTING --> ACTIVE: ready
    ACTIVE --> RESOLVING: first valid elimination
    RESOLVING --> RESETTING: pause-aware timer
    ACTIVE --> RESETTING: manual restart
    RESOLVING --> RESETTING: manual restart cancels timer
    RESETTING --> ACTIVE: reset existing entities in place
```

## Implemented prototype ball state

Only `THROWN` is live. A direct valid hit or dead-surface contact ends live
flight. `CAUGHT` is an explicit transfer transition immediately followed by
`HELD`.

```mermaid
stateDiagram-v2
    [*] --> AVAILABLE
    AVAILABLE --> HELD: human or bot pickup
    HELD --> THROWN: throw
    THROWN --> CAUGHT: valid human catch
    CAUGHT --> HELD: possession transfer
    THROWN --> DEAD: valid participant hit
    THROWN --> DEAD: dead-surface contact
    DEAD --> AVAILABLE: grace elapsed and slow/sleeping
    AVAILABLE --> AVAILABLE: round reset
    HELD --> AVAILABLE: round reset
    THROWN --> AVAILABLE: round reset
    DEAD --> AVAILABLE: round reset
```

The current ball records thrower identity and a one-hit flag. It does not carry
multi-hit flight history.

## Implemented prototype bot state

```mermaid
stateDiagram-v2
    [*] --> SEEK_BALL
    SEEK_BALL --> MOVE_TO_BALL: ball AVAILABLE
    MOVE_TO_BALL --> HOLD_BALL: pickup succeeds
    MOVE_TO_BALL --> WAIT_FOR_BALL: ball unavailable
    HOLD_BALL --> AIM
    AIM --> THROW: aim delay elapsed
    THROW --> WAIT_FOR_BALL: throw same ball
    WAIT_FOR_BALL --> SEEK_BALL: recovery elapsed and ball AVAILABLE
    SEEK_BALL --> ELIMINATED: valid hit
    MOVE_TO_BALL --> ELIMINATED: valid hit
    HOLD_BALL --> ELIMINATED: valid hit
    AIM --> ELIMINATED: valid hit
    THROW --> ELIMINATED: valid hit
    WAIT_FOR_BALL --> ELIMINATED: valid hit
```

## Future match lifecycle — Target architecture

```mermaid
stateDiagram-v2
    [*] --> LOBBY
    LOBBY --> CONFIGURING
    CONFIGURING --> LOADING
    LOADING --> WARMUP
    WARMUP --> ROUND_STARTING
    ROUND_STARTING --> ROUND_ACTIVE: 3, 2, 1, GO
    ROUND_ACTIVE --> ROUND_RESOLVING
    ROUND_RESOLVING --> INTERMISSION
    INTERMISSION --> ROUND_STARTING: more rounds remain
    INTERMISSION --> MATCH_COMPLETE: victory decided
    MATCH_COMPLETE --> RESULTS
    RESULTS --> [*]
```

Warmup is optional and configurable, with a suggested default of 10–15
seconds. Movement, throwing and catching are allowed, but persistent
eliminations are disabled so players can test latency, sensitivity and
trajectories.

Pause is a simulation policy/modifier, not a universal online match state.
Offline play may pause simulation; a personal menu does not pause an active
network match; server-admin pause may be allowed by server policy.

## Future player state groups — Target architecture

The primary match state is:

```mermaid
stateDiagram-v2
    [*] --> SPAWNING
    SPAWNING --> ROUND_LOCKED
    ROUND_LOCKED --> ACTIVE: GO
    ACTIVE --> ELIMINATED_SIDELINE: Standard elimination
    ACTIVE --> PRISONER: Prison Ball elimination
    ELIMINATED_SIDELINE --> REVIVING: catch/ruleset revival
    PRISONER --> REVIVING: resurrection pass/ruleset
    REVIVING --> RETURNING
    RETURNING --> ACTIVE: safe return complete
    ELIMINATED_SIDELINE --> SPECTATING
    ACTIVE --> DISCONNECTED
    PRISONER --> DISCONNECTED
    SPECTATING --> DISCONNECTED
```

Orthogonal sub-states run alongside the match state:

```mermaid
stateDiagram-v2
    state Movement {
        GROUNDED --> AIRBORNE
        AIRBORNE --> GROUNDED
        GROUNDED --> CROUCHED
        CROUCHED --> GROUNDED
        GROUNDED --> DODGING
        DODGING --> GROUNDED
    }
    state Possession {
        EMPTY_HANDS --> HOLDING_BALL
        HOLDING_BALL --> EMPTY_HANDS
    }
    state Defence {
        NORMAL --> CATCHING
        CATCHING --> NORMAL
        NORMAL --> BLOCKING
        BLOCKING --> NORMAL
    }
    state Connectivity {
        CONNECTED --> RECONNECTING
        RECONNECTING --> CONNECTED
        RECONNECTING --> DISCONNECTED
    }
```

Keeping movement, possession, defence and connectivity orthogonal avoids a
combinatorial state explosion such as
`ACTIVE_CROUCHED_HOLDING_BLOCKING_CONNECTED`. Each concern can enforce its own
legal transitions while the ruleset evaluates combinations explicitly.

## Future compact ball state — Target architecture

```mermaid
stateDiagram-v2
    [*] --> INACTIVE
    INACTIVE --> NEUTRAL: round setup
    NEUTRAL --> AVAILABLE: opening/activation permits
    AVAILABLE --> HELD: possession acquired
    HELD --> AIRBORNE_LIVE: thrown
    AIRBORNE_LIVE --> HELD: valid catch
    AIRBORNE_LIVE --> DEAD: dead-surface/ruleset ruling
    DEAD --> AVAILABLE: settled and eligible
    AIRBORNE_LIVE --> OUT_OF_PLAY: leaves recoverable space
    OUT_OF_PLAY --> RESETTING
    RESETTING --> AVAILABLE
```

Deflection and blocking remain collision-history metadata within
`AIRBORNE_LIVE`, not top-level states. Flight metadata should include current
holder, last owner, original thrower, attacking team, activation status,
players already hit, blocking interactions, deflection history, catch
eligibility and a live-flight sequence identifier.

Team status is calculated from player states; it is not an independent mutable
state that can drift out of sync.

## Prison Ball elimination and revival — Target rules

```mermaid
stateDiagram-v2
    ACTIVE --> PRISONER: valid elimination
    PRISONER --> PRISONER: later hit ignored
    PRISONER --> PRISONER: opponent catch (default)
    PRISONER --> REVIVING: teammate resurrection pass
    PRISONER --> REVIVING: optional arcade catch rule
    REVIVING --> RETURNING: assign safe own-side spawn
    RETURNING --> ACTIVE: optional protection expires
```
