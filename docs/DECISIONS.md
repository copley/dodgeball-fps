# Product and Architecture Decisions

Each record states context, decision, consequence and revisit condition.
Future-facing decisions describe direction, not implemented code.

## D-001 — Godot 4 and GDScript

- **Context:** The pilot needs fast iteration on first-person 3D gameplay.
- **Decision:** Use Godot 4.x and typed GDScript.
- **Consequence:** Scenes, physics and tooling follow Godot conventions; avoid
  third-party frameworks without approval.
- **Revisit when:** A proven platform or production requirement cannot be met.

## D-002 — Offline-first

- **Context:** The core sport must be valuable without network population or
  infrastructure.
- **Decision:** Build robust offline play, local configuration and bots before
  network expansion.
- **Consequence:** LAN and Internet work are conditional later phases.
- **Revisit when:** Core mechanics and offline match architecture pass their
  validation gates.

## D-003 — One-ball prototype before multi-ball

- **Context:** Multiple balls multiply possession, collision and ruling risks.
- **Decision:** Validate exactly one physical ball first.
- **Consequence:** The prototype intentionally cannot prove multi-ball play.
- **Revisit when:** M8 supports continuing and core mechanics are satisfactory.

## D-004 — Humans and bots share `PlayerAvatar`

- **Context:** Separate physical implementations would drift in capability and
  fairness.
- **Decision:** Future human and bot controllers emit intent to one avatar type.
- **Consequence:** Bots can gain mechanic parity without duplicating mechanics.
- **Revisit when:** Network authority or accessibility requires a documented
  interface refinement.

## D-005 — Data-driven rulesets

- **Context:** Standard, Prison Ball and custom variants change the same
  collision facts in different ways.
- **Decision:** Future rulings belong to `DodgeballRuleset` data/logic and named
  presets, not maps or ball scripts.
- **Consequence:** Configuration must be validated and authoritative.
- **Revisit when:** A rule cannot be represented without unsafe arbitrary code.

## D-006 — Separate match and round authority

- **Context:** Scores and formats outlive an individual round.
- **Decision:** Future `MatchController` owns the match lifecycle while
  `RoundController` applies round rulings.
- **Consequence:** Round reset cannot accidentally reset match scores.
- **Revisit when:** A simpler boundary is demonstrated across all formats.

## D-007 — Authoritative server

- **Context:** Networked physics and elimination need consistent outcomes.
- **Decision:** Future servers decide physical and competitive truth; clients
  may predict presentation and local motion.
- **Consequence:** Networking requires reconciliation and latency-aware UX.
- **Revisit when:** Never for competitive authority; prediction details may
  change after network prototypes.

## D-008 — Fun over realism

- **Context:** Literal physics or sport interpretation can harm readability and
  enjoyment.
- **Decision:** **Whenever realism conflicts with fun, this game should
  prioritize fun.**
- **Consequence:** Arcade tuning is acceptable when rules remain legible.
- **Revisit when:** The interpretation harms accessibility or competitive
  fairness, not merely because it is unrealistic.

## D-009 — Child-friendly sports presentation

- **Context:** The intended audience includes children and casual players.
- **Decision:** Use cheerful non-violent feedback; exclude gore, realistic pain,
  toxic language, gambling and loot boxes.
- **Consequence:** Elimination is framed as being “out,” not injury.
- **Revisit when:** Presentation assets need stricter age-rating guidance; the
  non-violent principle remains.

## D-010 — Reset prototype entities in place

- **Context:** Re-instantiation risks duplicate entities, signals and delayed
  events.
- **Decision:** Current `Main` resets the existing human, bot and ball in place.
- **Consequence:** Reset methods must comprehensively clear local state.
- **Revisit when:** A separately tested multi-participant spawn lifecycle
  requires replacement.

## D-011 — Major extraction waits until after M8

- **Context:** Architecture built before subjective mechanic validation may
  preserve the wrong game.
- **Decision:** Keep `Main` as prototype coordinator through M8; extract
  gradually only if expansion is approved.
- **Consequence:** Future documents are guidance, not permission to scaffold.
- **Revisit when:** M8 yields an explicit continue/revise decision and the next
  milestone is approved.
