# Conditional Product Roadmap

## Approval model

This roadmap describes dependency order, not an approved implementation queue.
M5.2 and M8 are the only pending prototype validation gates. Every later stage
is conditional and unapproved until earlier evidence supports it. Current tasks
remain in [TASKS.md](TASKS.md).

| Stage | Status | Gate and intended outcome |
| --- | --- | --- |
| Implemented vertical slice | Implemented through M7 | One human, deterministic bot, court and ball; charged throw, timed catch, dodge, elimination, result and clean reset |
| M5.2 render validation | Pending | Record the 2×/4× MSAA interactive comparison and visual/performance findings |
| M8 interactive validation | Pending | Complete ten interactive rounds and issue a continue, revise or stop decision |
| Core mechanic refinement | Conditional, unapproved | Refine throwing, catching, movement and feedback from observed play-test evidence |
| Controller support | Conditional, unapproved | Add high-priority controller input and accessibility; decide whether it is a Version 1.0 release gate |
| Unified avatar migration | Conditional, unapproved | Gradually place humans and bots behind one intent-driven `PlayerAvatar` |
| Offline custom match framework | Conditional, unapproved | Add match/round separation, rosters, configuration, presets and map contracts |
| Standard and Prison Ball | Conditional, unapproved | Implement separately selectable, data-driven modes |
| Multi-player and multi-ball | Conditional, unapproved | Scale to 12 participants and one to six balls after ownership/rule foundations prove stable |
| LAN | Conditional, unapproved | Add authoritative local-network hosting; this is not split-screen |
| Online networking | Conditional, unapproved | Add Internet servers, replication, reconciliation and disconnection policies |
| Workshop/community features | Conditional later work | Consider Workshop maps, plugins, community servers and administration only after core/network success |

The first implementation milestone after M8 is unresolved. Do not assume the
table authorizes immediate architectural extraction or feature expansion.

Post-release or later possibilities also include advanced server-browser
plugins, deep cosmetic progression, large Workshop integration, complex
matchmaking ladders, broader progression and advanced community-server
administration.
