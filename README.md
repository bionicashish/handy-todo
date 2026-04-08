# Handy To-Do

A minimal macOS menu bar checklist app. No Dock icon — lives quietly in your menu bar.

![Swift](https://img.shields.io/badge/Swift-6.1-orange) ![macOS](https://img.shields.io/badge/macOS-14%2B-blue)

## Features

- Lives in the menu bar, out of your way
- Add to-dos inline — press Enter to confirm
- Check off items to strike them through
- Click any item text to edit it in place
- `Cmd+R` or the refresh button clears all tasks
- `Esc` closes the panel
- Items persist across app launches

## Requirements

- macOS 14+
- Swift 6 (Xcode Command Line Tools or full Xcode)

## Build & Run

```bash
chmod +x build.sh
./build.sh
open HandyToDo.app
```

## Build DMG

```bash
chmod +x build-dmg.sh
./build-dmg.sh
```

This creates `HandyToDo.dmg` in the repository root.


## Keyboard Shortcuts

| Shortcut | Action |
|----------|--------|
| `Enter` | Add / confirm a to-do |
| `Cmd+R` | Clear all tasks |
| `Esc` | Close the panel |
| `Cmd+A` | Select all text in focused field |
| `Cmd+C` | Copy |
| `Cmd+V` | Paste |
| `Cmd+X` | Cut |

## First Run (local unsigned build)

macOS will block an unsigned app on first open. Right-click → **Open** → **Open** to bypass, or run:

```bash
xattr -dr com.apple.quarantine HandyToDo.app
```
