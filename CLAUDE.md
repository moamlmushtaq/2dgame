# Cloud Ship (سفينة الغيوم) — notes for Claude Code

A 2D co-op airship game for 1–6 local players, built with **Godot 4.7** (GDScript,
GL Compatibility renderer). The owner writes to you in Arabic; answer in Arabic.
All player-facing text is Arabic (Cairo font). Code, comments and commits are English.

The Arabic history and the plan of what to do next are in `docs/ROADMAP.md`.

## Game flow

Menu (join with jump, pick with interact) → story intro → **voyage** (keep the airship
flying to an island) → **island** (co-op puzzles, chest holds a map piece) → next voyage…
After `Game.MAP_TOTAL` (4) pieces the next voyage is the **pirate flagship battle**, then
the story ending with credits. Odd voyages land on Blossom Isle, even ones on Wind Isle.

## Layout

```
scenes/*.tscn           Each is one Node2D with a script; everything else is built in code.
scripts/core/           Autoloads and shared pieces:
  game.gd               Autoload `Game`: crew, story progress, settings, save file,
                        scene fades (Game.goto), pause menu (Esc/Start), bots (fill_bots).
  sound.gd              Autoload `Sound`: all SFX and music are synthesised in code
                        (music on WorkerThreadPool). Buses: Music, SFX. M mutes.
  player.gd             Player (CharacterBody2D, origin at the feet). Also paint_sailor().
  player_input.gd       PlayerInput: keyboard half, gamepad, or BOT (driven by BotBrain).
  bot_brain.gd          AI crewmates for solo players (see below).
  interactable.gd       Base for things used with the interact button; station.gd for
                        things a player climbs into and steers (helm, cannons).
  paint.gd, fx.gd       Drawing helpers (rounded boxes, Arabic text, bars, map icons),
                        particle bursts.
  sky_backdrop.gd       Painted parallax sky (class is SkyBackdrop — `Sky` clashes with
                        a Godot built-in class).
  option_list.gd        Menu list driven by PlayerInputs (menus, pause, settings).
scripts/voyage/         voyage.gd (scene root, state, spawning, damage), ship.gd (hull +
                        colliders; Ship.paint() takes a palette, reused for the pirates),
                        stations, hazards (rock, bird, bomb), pirate_ship.gd, voyage_hud.gd.
scripts/island/         island.gd builds either island (_build_blossom / _build_wind),
                        puzzle pieces (lever, plates, gate, lift, rising step, crank,
                        wind vent, bells, bell bridge, moving clouds, chest, gems), HUD.
scripts/menu/           menu.gd (lobby, main menu, settings, how-to), story.gd.
tests/                  Headless simulations (not exported).
export_presets.cfg      Windows / Linux / Web. .github/workflows/build.yml builds them.
```

## Conventions

- **Drawn in code** with `_draw()`: shapes, `Paint.box()` rounded boxes, `Paint.text()` for
  Arabic text. No audio files. A few hand-drawn CC0 images live in `assets/art/` (sky clouds,
  far islands and peaks, the boulder, birds, lanterns), drawn with `draw_texture()` from
  `_draw()` and tinted per scene. Every image must be CC0 and listed in
  `assets/art/CREDITS.md`; crop and shrink them before adding (the web build stays small).
- Scenes are minimal `.tscn` files; nodes are created in `_ready()`.
- Physics layers: 1 world, 2 players, 4 one-way platforms, 8 player heads. Players pass
  through each other but each carries a one-way "head" platform, so friends can stand on
  heads. Use `Player.LAYER_*` constants.
- Input is read through `PlayerInput` (`poll()` once per physics frame by the Player,
  then `pressed()`/`held()`/`axis_x()`), never through the InputMap. Keys are physical.
- Bots must obey the same rules as humans: they only press virtual buttons.
- Difficulty: `Game.difficulty()` and `Game.crew_strength()` (bots count as half a sailor
  for hazard sizing). Island puzzles scale with `Game.player_count()` (real bodies).
- Save file: `user://cloud_ship.cfg` (settings, stats, run in progress).

## GDScript gotchas we hit

- `:=` cannot infer from untyped values (Dictionary lookups, untyped vars): write
  `var x: float = dict["k"]`. This is a parse error, not a warning.
- Don't name a class after a built-in (`Sky` broke). Check before adding `class_name`.
- Controls created in code need `set_anchors_and_offsets_preset(PRESET_FULL_RECT)`,
  not just `set_anchors_preset`, or they end up tiny.
- `draw_colored_polygon` errors on degenerate (collinear) polygons — keep animated
  points from lining up.
- Autoloads are not visible to scripts run with `godot -s`; that's why the tests are
  injected as an autoload into a temp copy instead (tests/run.sh).

## Testing — always run before committing

Needs Godot 4.7 on PATH as `godot` or `GODOT=/path/to/godot`:

```bash
tests/run.sh smoke                 # every scene loads without script errors (CI does this too)
VOYAGE=1 tests/run.sh islands      # Blossom Isle puzzles with a scripted human + 1 bot
VOYAGE=2 tests/run.sh islands      # Wind Isle puzzles
tests/run.sh voyage 3              # 3 voyages: idle human + 2 bots (BOTS=n to change)
PIECES=4 tests/run.sh voyage 3     # 3 pirate battles
```

Simulations run with `--fixed-fps 60`, so they finish in seconds. When changing balance
or bot logic, run several times — outcomes are random. Current baseline with an idle
human + 2 bots: normal voyage wins nearly every run (12 of 12 after the mast cannon
could dip below the horizon), pirate battle about 2 in 3 (65-70% over 30+ runs).
For visual checks, run the game and take screenshots (on Linux, `xvfb-run` with
`--rendering-driver opengl3` works for headless screenshots via
`get_viewport().get_texture().get_image().save_png()`).

## Bot brain (scripts/core/bot_brain.gd)

`decide()` returns the buttons to hold this frame. On the ship: rank 0 is the deckhand
(helm when a rock is on course → holes → coal → idle at a cannon), ranks 1+ are gunners
who stay on the cannons (predictive aiming with `_pick_target`) and patch holes when the
sky is clear. Jobs are claimed per scene (`bot_claims` meta) so bots split the work. On
islands: follow the nearest human with gap-safe walking (`_ground_ahead` ray) and one
rule per puzzle (`_bells`, `_cranks`, `_gate`, `_levers`, `_tall_wall`, `_gems`). A new
island puzzle needs a matching rule here and a check in tests/sim_islands.gd.

## Branches and builds

Work has been on `claude/bold-cori-f0jmgp`. Every push runs the GitHub Actions build;
ready-to-play Windows/Linux/Web builds are the run's artifacts.
