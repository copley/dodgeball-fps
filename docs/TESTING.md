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
- [ ] Shift sprint preserves diagonal normalization and collision.
- [ ] Space jumps only while grounded.
- [ ] Ctrl crouches and refuses to stand under an obstruction.
- [ ] Player picks up only the available ball.
- [ ] Quick and charged throws produce different speeds.
- [ ] Ball collides with floor, walls, and target.
- [ ] One valid hit produces one elimination.
- [ ] Catch succeeds only inside the intended timing window.
- [ ] Successful catch grants possession.
- [ ] Dodge moves laterally and respects its cooldown.
- [ ] Escape pauses gameplay, releases the mouse, and opens all menu panels.
- [ ] Menu clicks do not throw, catch, pick up, dodge, jump, or restart through
	  the overlay.
- [ ] Resume recaptures the mouse; menu Restart Round resets and resumes.
- [ ] Reset restores one player, one ball, and one target.
- [ ] Five consecutive resets create no duplicate entities or events.
- [ ] Movement and ball motion appear smooth with physics interpolation enabled.
- [ ] F3 toggles FPS, frame time, physics time, draw-call, and object diagnostics.
- [ ] Restarted entities do not visibly interpolate from their previous position.

## Evidence expected in pull requests

Each implementation PR must include:

- Commands run and their exit status.
- Manual checks performed.
- Known limitations.
- Screenshots or a short capture when behaviour is visual and cannot be established by logs.
