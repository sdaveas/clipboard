# Clipboard Manager for macOS

A simple menu bar clipboard manager that keeps track of your last 10 copied text items.

## Features

- 📋 Lives in your menu bar with a clipboard icon
- 📝 Automatically tracks your last 10 text clipboard items
- ⏱️ Shows timestamps for each item
- 🔄 Click any item to copy it back to your clipboard
- ⌨️ **Quick Panel**: Press **Ctrl+Shift+P** to show a centered window with numbered items
- 🔢 Type a number (1-10) to instantly paste that clipboard item
- 🎨 Clean, native macOS interface using SwiftUI

## Requirements

- macOS 13.0 or later
- Xcode 14.0 or later

## Building and Running

1. Open `ClipboardManager.xcodeproj` in Xcode
2. Press Cmd+R to build and run the app
3. The app will appear as a clipboard icon in your menu bar (no dock icon)
4. Click the icon to see your clipboard history

## Usage

### Menu Bar Access
1. Copy text as you normally would (Cmd+C)
2. The app automatically tracks each copy
3. Click the menu bar icon to view your history
4. Click any item in the list to copy it back to your clipboard

### Quick Panel (Keyboard Shortcut)
1. Press **Ctrl+Shift+P** from anywhere to show the quick panel
2. Each clipboard item is numbered 1-10
3. Type the number to instantly paste that item
4. Press **Esc** to close the panel

## How It Works

- **ClipboardManagerApp.swift**: Main app entry point, sets up the menu bar icon
- **ClipboardMonitor.swift**: Monitors the system clipboard for changes every 0.5 seconds
- **ContentView.swift**: SwiftUI interface showing the clipboard history list

## Customization

You can modify the maximum number of stored items by changing `maxHistoryCount` in `ClipboardMonitor.swift` (default is 10).
