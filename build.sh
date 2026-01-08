#!/bin/bash

# Build the standalone clipboard manager
echo "Building Clipboard Manager..."

# Create app bundle structure
mkdir -p ClipboardManager.app/Contents/MacOS
mkdir -p ClipboardManager.app/Contents/Resources

# Compile the Swift code
swiftc -parse-as-library -O -framework AppKit -framework SwiftUI \
    ClipboardManager-Standalone.swift \
    -o ClipboardManager.app/Contents/MacOS/ClipboardManager

# Create Info.plist
cat > ClipboardManager.app/Contents/Info.plist << 'EOF'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>ClipboardManager</string>
    <key>CFBundleIdentifier</key>
    <string>com.local.ClipboardManager</string>
    <key>CFBundleName</key>
    <string>ClipboardManager</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
</dict>
</plist>
EOF

echo "✅ Build complete! App created at: ClipboardManager.app"
echo ""
echo "To run: open ClipboardManager.app"
