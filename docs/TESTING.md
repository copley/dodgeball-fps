# Testing

## Automated validation

Run from the repository root after Godot project files exist:

```bash
godot --headless --path . --editor --quit
```

When a runnable main scene exists:

```bash
godot --headless --path . --quit-after 2
```

Any parser error, missing resource, invalid node path, or non-zero exit status blocks completion.

## Manual pilot checklist

- [ ] Project opens directly into the court.
- [ ] Mouse capture and release behave predictably.
- [ ] WASD movement and collisions are stable.
- [ ] Player picks up only the available ball.
- [ ] Quick and charged throws produce different speeds.
- [ ] Ball collides with floor, walls, and target.
- [ ] One valid hit produces one elimination.
- [ ] Catch succeeds only inside the intended timing window.
- [ ] Successful catch grants possession.
- [ ] Dodge moves laterally and respects its cooldown.
- [ ] Reset restores one player, one ball, and one target.
- [ ] Five consecutive resets create no duplicate entities or events.

## Evidence expected in pull requests

Each implementation PR must include:

- Commands run and their exit status.
- Manual checks performed.
- Known limitations.
- Screenshots or a short capture when behaviour is visual and cannot be established by logs.
