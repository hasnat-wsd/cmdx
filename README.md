# CmdX

**Windows / Linux style cut & paste for the macOS Finder.**

Select files or folders, press <kbd>⌘</kbd> <kbd>X</kbd>, open another
folder, press <kbd>⌘</kbd> <kbd>V</kbd>, and they are moved there.

![Platform](https://img.shields.io/badge/platform-macOS%2013%2B-lightgrey)
![Swift](https://img.shields.io/badge/swift-6-orange)
![Dependencies](https://img.shields.io/badge/dependencies-none-brightgreen)
![License](https://img.shields.io/badge/license-MIT-blue)

---

## Contents

- [Features](#features)
- [Requirements](#requirements)
- [Build](#build)
- [Install](#install)
- [Usage](#usage)
- [Update](#update)
- [Uninstall](#uninstall)
- [How it works](#how-it-works)
- [Security & privacy](#security--privacy)
- [Architecture](#architecture)
- [Troubleshooting](#troubleshooting)
- [License](#license)

---

## Features

| Action | Result |
| --- | --- |
| <kbd>⌘X</kbd> on one or more files or folders | Items are marked as cut and appear **faded** in Finder. The menu bar shows how many. |
| <kbd>⌘V</kbd> in another folder or on the Desktop | Items are **moved** there. |
| <kbd>⌘V</kbd> again | Nothing happens, because the cut has been used (same as Windows). |
| <kbd>Esc</kbd>, or **Cancel Cut** in the menu | The cut is cancelled and nothing moves. |
| Copy something else | The pending cut is dropped (same as Windows). |
| <kbd>⌘X</kbd> / <kbd>⌘V</kbd> while renaming or searching | Normal text cut and paste. |
| <kbd>⌘V</kbd> with nothing cut | Normal Finder paste (a copy). |

Finder does the move itself, so you keep its conflict dialogs ("Replace /
Keep Both"), <kbd>⌘Z</kbd> undo, permission prompts, moves between
drives, and its standard **progress window**.

---

## Requirements

| | |
| --- | --- |
| **macOS** | 13 Ventura or later |
| **Toolchain** | Xcode 16+ **or** the Xcode Command Line Tools (Swift 6) |
| **Permission** | Accessibility (requested on first launch) |

If you don't have a Swift toolchain, install the Command Line Tools:

```sh
xcode-select --install
```

Check it worked:

```sh
swift --version   # should report Swift 6.x
```

---

## Build

### 1. Clone

```sh
git clone https://github.com/hasnat-wsd/cmdx.git
cd cmdx
```

### 2. Build the app

```sh
Scripts/build-app.sh
```

This script:

1. runs the unit tests,
2. builds an optimised release binary,
3. assembles `dist/CmdX.app`,
4. signs it with the hardened runtime and verifies the signature.

The finished app is at **`dist/CmdX.app`**.

### Optional: sign with your own identity

By default the app gets an *ad-hoc* signature. That works locally, but
macOS asks for Accessibility permission again after every rebuild (see
[Update](#update)). To avoid that, sign with an Apple Developer
certificate:

```sh
# List the signing identities on this Mac
security find-identity -v -p codesigning

SIGN_IDENTITY="Developer ID Application: Your Name (TEAMID)" Scripts/build-app.sh
```

### Run the tests only

```sh
swift test
```

---

## Install

### 1. Copy to Applications

```sh
# Quit any running copy first
osascript -e 'quit app "CmdX"' 2>/dev/null

ditto dist/CmdX.app /Applications/CmdX.app
```

### 2. Launch

```sh
open /Applications/CmdX.app
```

CmdX runs in the **menu bar**, shown as a ✂ scissors icon. It has no Dock
icon or window.

### 3. Grant Accessibility access

On first launch, macOS shows a prompt.

1. Click **Open System Settings**. You can also go to **System Settings ▸
   Privacy & Security ▸ Accessibility** yourself.
2. Turn on **CmdX**. If it isn't listed, click **+** and choose
   `/Applications/CmdX.app`.

CmdX starts working within about two seconds, with no relaunch needed.
The ✂ icon changes from dimmed to normal.

> **Why Accessibility?** CmdX needs it to notice <kbd>⌘X</kbd> /
> <kbd>⌘V</kbd> in Finder and to trigger Finder's own Copy and Move
> commands. See [Security & privacy](#security--privacy).

### 4. Start at login (optional)

**System Settings ▸ General ▸ Login Items & Extensions ▸ Open at Login ▸
+**, then choose **CmdX**.

---

## Usage

1. In Finder, select one or more files or folders.
2. Press <kbd>⌘</kbd> <kbd>X</kbd>. The items fade, and the menu bar shows
   ✂ with a count.
3. Open the destination folder, or click the Desktop.
4. Press <kbd>⌘</kbd> <kbd>V</kbd>. The items are moved.

To cancel, press <kbd>Esc</kbd> in Finder or choose **Cancel Cut** from the
✂ menu.

> **Progress window:** long moves, such as large items going to another
> drive, show Finder's standard *"Moving N items to …"* window, with a
> progress bar, time remaining and a Stop button. Moves on the same disk
> finish instantly, so no window appears, the same as drag-and-drop.

---

## Update

```sh
cd cmdx
git pull
Scripts/build-app.sh
osascript -e 'quit app "CmdX"' 2>/dev/null
ditto dist/CmdX.app /Applications/CmdX.app
open /Applications/CmdX.app
```

> **Ad-hoc signed builds:** macOS ties the Accessibility permission to the
> exact build. After updating, open **System Settings ▸ Privacy & Security
> ▸ Accessibility**, select **CmdX**, remove it with **–**, then add it
> again with **+**. Builds signed with your own identity (see
> [Build](#optional-sign-with-your-own-identity)) don't need this.

---

## Uninstall

```sh
osascript -e 'quit app "CmdX"' 2>/dev/null
rm -rf /Applications/CmdX.app
tccutil reset Accessibility com.wsd.cmdx   # remove the Accessibility entry
```

If you added it to **Login Items**, remove it there as well. CmdX keeps no
settings, caches or other files anywhere else.

---

## How it works

CmdX never reads, writes or deletes files itself. It turns your keystrokes
into Finder's own commands:

1. **⌘X** → CmdX sends Finder **Copy** (⌘C) and remembers that this copy is
   a *cut*.
2. **⌘V** → if that copy is still on the clipboard, CmdX sends Finder
   **Move Item Here** (⌘⌥V).

### The "faded" look

macOS gives other apps no way to change how Finder draws its icons, so
CmdX gets the Windows-style fade without touching Finder or your files:

- It finds where the cut items are on screen through the Accessibility API.
  This is read-only.
- It draws a click-through overlay over each item, in Finder's background
  colour at 60% opacity. This adapts to light and dark mode.
- The fade follows scrolling, folder changes and window moves (it refreshes
  4× per second). It disappears on paste, <kbd>Esc</kbd>, **Cancel Cut**,
  or when you switch away from Finder.
- It only draws on Finder's front window, and on desktop icons that no
  other window is covering, so it never paints over another app.
- Supported views: icon, list (the whole row fades) and the Desktop. Column
  and gallery views are matched on a best-effort basis.

---

## Security & privacy

- **No third-party dependencies.** It uses only Apple system frameworks
  (AppKit, CoreGraphics, ApplicationServices, Foundation).
- **No file access.** Finder does every file operation.
- **No network and no storage.** Keystrokes are checked in memory, and only
  to recognise <kbd>⌘X</kbd>, <kbd>⌘V</kbd> and <kbd>Esc</kbd>. Any other
  key is passed on immediately without further inspection.
- **Minimal diagnostics.** Cut and paste decisions go to the macOS unified
  log as reasons and item counts. File names, paths and other keystrokes
  are never logged.
- **Narrow scope.** It acts only when Finder is the frontmost app and no
  editable text field has focus. If focus can't be determined, it does
  nothing.
- **Fixed output.** It only ever posts ⌘C and ⌘⌥V. Those events are tagged
  so CmdX never reacts to its own input.
- **Overlays never take input.** They ignore the mouse, can't become key,
  and are hidden from Accessibility. Finding items stops after a fixed
  number of elements and 60 ms per refresh, so a busy Finder can't freeze
  CmdX.
- **Read-only clipboard.** CmdX reads file URLs and never writes to the
  clipboard.
- **Hardened runtime** code signing.
- **Not sandboxed, on purpose.** The App Sandbox does not allow event taps
  or posting keystrokes to other apps, which this feature needs. That is
  also why CmdX is distributed as source, not through the Mac App Store.

---

## Architecture

```text
Sources/
├── CmdXCore/                 Pure logic (Foundation only, unit tested)
│   ├── Models/               KeyStroke, Shortcut, CutState, CutSession, CutEvent…
│   ├── Ports/                Protocols the core depends on (DIP)
│   └── Coordinator/          CutPasteCoordinator, ClipboardChangeAwaiter,
│                             CutHighlightPresenter
└── CmdX/                     macOS adapters and UI
    ├── App/                  main, AppDelegate, AppController, CompositionRoot
    ├── Input/                Event tap, keystroke mapping, Finder command sender
    ├── Highlight/            Finder item locator (AX tree search) and fade overlays
    ├── Feedback/             Diagnostics logging and failure beep
    ├── System/               Frontmost app, AX focus, pasteboard, permission, timers
    │   └── Accessibility/    Type-safe AXUIElement wrapper and value decoding
    └── UI/                   Menu bar item and menu
Tests/CmdXCoreTests/          Swift Testing suites and test doubles
Scripts/build-app.sh          Test → build → bundle → sign
Resources/Info.plist          App bundle metadata (menu-bar-only app)
```

- **Single responsibility:** each type has one job. For example,
  `EventTapMonitor` only intercepts keys and `FinderKeystrokeSender` only
  posts commands.
- **Dependency inversion:** the core depends only on the protocols in
  `Ports/`. Concrete implementations are wired up in `CompositionRoot`.
- **Interface segregation:** many small, focused protocols instead of one
  large "system" interface.
- **Testability:** time, Finder, the clipboard, focus and the screen are
  all faked in tests, so the whole cut → paste flow runs in milliseconds.
- **Small files:** no source file is longer than 200 lines.

---

## Troubleshooting

<details>
<summary><b>⌘X does nothing / the ✂ icon looks dimmed</b></summary>

CmdX doesn't have Accessibility access, or the access belongs to an older
build. Open **System Settings ▸ Privacy & Security ▸ Accessibility**,
remove **CmdX** with **–**, add `/Applications/CmdX.app` again with **+**,
and make sure it is turned on.

</details>

<details>
<summary><b>Pasting created a <code>.textClipping</code> file</b></summary>

The cut didn't capture any files, so ⌘V did a normal Finder paste of
whatever text was on the clipboard. CmdX beeps when a cut fails. To see
why, stream its log in Terminal while you try again:

```sh
log stream --level debug --predicate 'subsystem == "com.wsd.cmdx"'
```

</details>

<details>
<summary><b>An item isn't faded after ⌘X</b></summary>

The move still works. The fade is visual only. It's reliable in icon view,
list view and on the Desktop; column and gallery views are best-effort.

</details>

<details>
<summary><b><code>swift test</code> fails with "plugin for module 'TestingMacros' not found"</b></summary>

This is a known issue in the Swift 6.4 Command Line Tools: the first test
build after a clean checkout can fail. Run `swift test` again and it
passes. `Scripts/build-app.sh` handles this automatically.

</details>

---

## License

Released under the [MIT License](LICENSE).
