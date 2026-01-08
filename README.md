# Clipboard Manager for macOS

[![Download Latest Release](https://img.shields.io/github/v/release/sdaveas/clipboard?label=Download&style=for-the-badge)](https://github.com/sdaveas/clipboard/releases/latest/download/ClipboardManager.zip)

A simple, fast menu bar clipboard manager for macOS. Track your clipboard history and quickly access previously copied items.

## Features

- 📋 **Menu Bar App**: Lives in your menu bar with a clipboard icon - no dock icon
- 📝 **Clipboard History**: Automatically tracks text items (customizable: 5-50 items)
- ⏱️ **Timestamps**: See when each item was copied ("Just now", "5m ago", etc.)
- ⌨️ **Quick Access**: Global keyboard shortcut (default: Ctrl+Shift+P) to show numbered items
- 🔢 **Fast Selection**: Type a number or click to copy any item
- ⚙️ **Customizable**: Change history size and keyboard shortcuts
- 🗑️ **Clear History**: Right-click menu to clear all items
- 🔄 **Easy Restart**: Restart option in right-click menu
- 🎨 **Native UI**: Clean macOS interface using SwiftUI

## Requirements

- macOS 13.0 or later
- Swift 5.0 or later (included with Xcode Command Line Tools)

## Building and Running

### Command Line (No Xcode Required)

```bash
./build.sh
open ClipboardManager.app
```

### With Xcode

1. Open `ClipboardManager.xcodeproj` in Xcode
2. Press Cmd+R to build and run

The app will appear as a clipboard icon in your menu bar (no dock icon).

## Usage

### Menu Bar Icon
- **Left-click**: Opens clipboard history popover with settings
- **Right-click**: Shows menu with About, Clear History, Restart, and Quit

### Quick Panel (Keyboard Shortcut)
1. Press your configured shortcut (default: **Ctrl+Shift+P**) from anywhere
2. Each clipboard item is numbered (1-10 or more)
3. **Type a number** or **click an item** to copy it to clipboard
4. Press **Cmd+V** to paste in your target application
5. Press **Esc** to close the panel

### Settings
1. Click the menu bar icon to open the popover
2. Click the gear icon (⚙️) in the top-right corner
3. Customize:
   - **Maximum Clipboard Items**: 5-50 items (default: 10)
   - **Keyboard Shortcut**: Choose modifier (Cmd+Shift, Ctrl+Shift, etc.) and key (P, C, V, H, K, L)
4. Click "Apply Shortcut Change" to update the hotkey immediately

## How It Works

- Monitors the system clipboard for changes every 0.5 seconds
- Stores up to 50 text items (configurable)
- Global keyboard shortcut for quick access
- All settings persist via UserDefaults

## License

MIT License - see [LICENSE](LICENSE) file for details
