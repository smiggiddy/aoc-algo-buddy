# Slate

A local terminal for iPadOS, built on [libghostty](https://mitchellh.com/writing/libghostty-is-coming).

Same idea as [a-Shell](https://github.com/holzschu/a-shell) — commands run *on the
iPad*, not over SSH — but with Ghostty's terminal engine and a Metal renderer
instead of hterm in a web view, and with Ghostty desktop's keybindings.

> **Status: not yet built.** Every line here was written against the real
> `libghostty-vt` headers, but it has never been through a compiler — there's no
> Mac in the loop yet. Expect to fix things on first build; see
> [What to verify first](#what-to-verify-first).

## Why this shape

iOS denies `fork`/`exec`/`posix_spawn` to sandboxed apps. There is no PTY and no
child process, so the usual `forkpty()` + `/bin/zsh` terminal is off the table.

What *is* allowed is running commands as function calls inside your own process,
which is what `ios_system` does and why a-Shell works. Slate takes the same
approach and swaps in a better front end:

| Layer | a-Shell | Slate |
|---|---|---|
| Commands | `ios_system` (+ WASI) | `ios_system` (+ WASI) |
| VT emulation | hterm (JS) | `libghostty-vt` |
| Rendering | WKWebView / SwiftTerm | Metal, CoreText glyph atlas |
| Keybindings | custom | Ghostty desktop defaults |

## Architecture

```
SlateApp      SwiftUI shell — tabs, split tree, settings, command palette
   │
SlateRender   CAMetalLayer view, glyph atlas, instanced cell renderer
   │
SlateTerminal libghostty-vt bindings: terminal, render state, key encoder
   │
SlateIO       backends: built-in shell (works now), ios_system (needs vendoring)
   │
SlateTheme    themes and palettes     SlateInput  chords, keymap, key mapping
```

Two seams matter:

- **`TerminalBackend`** — everything above it is a byte stream. Local, WASI, and
  SSH are all just backends; swapping one doesn't touch the terminal, renderer,
  or input layers.
- **`TerminalSnapshot`** — the renderer never touches libghostty memory. Each
  frame is a detached, fully-resolved value, so rendering can't race the parser.

### Rendering

Two instanced draw calls per frame — one for cell backgrounds, one for glyphs —
regardless of grid size. The atlas stores single-channel coverage and the shader
tints with the cell's foreground colour, so **changing theme never invalidates
the atlas**. Redraws are driven by a snapshot generation counter, not a fixed
rate: an idle terminal costs nothing.

### Input

`libghostty`'s key encoder does the encoding, and `setopt_from_terminal` re-syncs
it before every keypress — application cursor mode, `modifyOtherKeys`, alt-as-esc,
and the Kitty keyboard protocol all come out correct without Slate implementing
any of it.

Chords are matched on **physical key** (`UIKey.keyCode`), not the character
produced, so Ghostty's bindings stay where your fingers are on any layout.

## Keybindings

Modelled on Ghostty's macOS defaults — `super` is ⌘, which is exactly the Magic
Keyboard's ⌘.

| Chord | Action | | Chord | Action |
|---|---|---|---|---|
| ⌘T | New tab | | ⌘C / ⌘V | Copy / Paste |
| ⌘N | New window | | ⌘K | Clear screen |
| ⌘W | Close split | | ⌘= / ⌘− / ⌘0 | Font size |
| ⌘D | Split right | | ⇧⇞ / ⇧⇟ | Scroll page |
| ⇧⌘D | Split down | | ⌘↑ / ⌘↓ | Jump to prompt* |
| ⌥⌘←↑↓→ | Focus split | | ⌘1…8 | Go to tab |
| ⌘[ / ⌘] | Cycle splits | | ⌘9 | Last tab |
| ⇧⌘[ / ⇧⌘] | Prev / next tab | | ⇧⌘P | Command palette |
| ⇧⌘↩ | Zoom split | | ⌘, | Settings |

<sub>* needs OSC 133 shell integration</sub>

**Only ⌘ chords are claimed by the app.** ⌃C, ⌃D, ⌃Z, and Esc go to the program —
a test enforces this, because getting it wrong makes the terminal useless.

Override with `Documents/keybindings.conf`, using Ghostty's syntax:

```
keybind = super+t=new_split:down
keybind = super+k=unbind
```

An unparseable line is reported and skipped, never fatal.

### On-screen keys

The software keyboard has no Esc, Ctrl, Tab, or arrows. The accessory bar adds
them, with Ctrl and Alt as **sticky modifiers** — tap ctrl, then `c`, and the
program gets `^C`.

## Themes

Catppuccin Mocha (default) · Tokyo Night · Rosé Pine · Everforest Dark ·
Catppuccin Latte · Nord · Gruvbox Dark · Dracula · One Dark · Solarized Light

Full 16-colour ANSI palettes; slots 16–255 are generated as the standard xterm
cube and greyscale ramp. Drop JSON files in `Documents/Themes` for your own —
same fields as the built-ins, `#rrggbb` colours. `colors` in the built-in shell
prints a chart to check a theme against the renderer.

## Building

```sh
brew install xcodegen
cd slate
xcodegen generate
open Slate.xcodeproj
```

Requires iPadOS 17+, Xcode 16+. The `GhosttyKit.xcframework` comes from
[libghostty-spm](https://github.com/Lakr233/libghostty-spm) via SwiftPM — pin it
to a tag once you know which header revision you're on, since `main` tracks a
moving API.

It runs on the **built-in shell** out of the box (`help`, `ls`, `cd`, `cat`,
`colors`, …) so you can see the terminal working before wiring anything up.

### Adding the real command set

1. `git clone https://github.com/holzschu/ios_system`
2. `swift run --package-path xcfs build`
3. Link `ios_system.xcframework`; **embed without linking** the command
   frameworks you want (`awk`, `curl`, `files`, `shell`, `text`, …)
4. Add `SLATE_IOS_SYSTEM` to `SWIFT_ACTIVE_COMPILATION_CONDITIONS`
5. Switch `AppModel.makeSurface()` to `IOSSystemBackend()`

Step 3's embed-don't-link distinction is the one that's easy to get wrong; the
symptom is commands reporting "not found" despite the framework being present.

## What to verify first

Ranked by how likely they are to be wrong and how loudly they'll fail:

1. **Allocator alignment** (`slate_ghostty_shim.c`). Zig's allocator vtable
   passes alignment as a log2 exponent; the shim assumes that. If it's ever a
   byte count instead, you get immediate heap corruption. One function to fix.
2. **Render-state object binding** (`RenderStateReader.swift`). The
   allocate-then-bind order for the row iterator and cell reader is read from
   the headers, not from a working build. First place to check if the screen
   comes out empty or garbled.
3. **`GhosttyKit` module layout** — whether the umbrella exposes `ghostty/vt.h`
   under that module name, and whether the opaque handles import as
   `OpaquePointer`. Mechanical to fix, may touch several files.
4. **Cell style reads** — `GHOSTTY_RENDER_STATE_ROW_CELLS_DATA_STYLE` is read
   into a `GhosttyStyle`; if the render API hands back a `GhosttyStyleId`
   instead, attributes need a second lookup.

`SlateTheme` and `SlateInput` have no libghostty dependency and are covered by
tests, so `swift test` on those two is meaningful even before the rest builds.

## Not done yet

- **Selection and copy.** libghostty tracks selection; the touch UI and ⌘C
  aren't wired. `copy_to_clipboard` deliberately returns unhandled rather than
  copying the wrong thing.
- **Mouse reporting.** `wantsMouseTracking` is read and suppresses scrollback
  panning, but touches aren't forwarded as mouse events, so vim/tmux won't see
  them.
- **Kitty graphics / sixel.** libghostty parses them; the renderer ignores them.
- **Keyboard split resize.** ⌃⌘arrows are unhandled — splits are drag-resizable
  only.
- **Scrollback search.** ⌘F is bound but does nothing.
- **Background suspension.** iPadOS will suspend the app and the built-in shell
  survives it; a real backend needs reconnect/restore handling.
