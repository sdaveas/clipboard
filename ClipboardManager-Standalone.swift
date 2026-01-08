import AppKit
import SwiftUI
import Carbon

// MARK: - Settings Manager
class SettingsManager: ObservableObject {
    static let shared = SettingsManager()
    
    @Published var maxHistoryCount: Int {
        didSet {
            UserDefaults.standard.set(maxHistoryCount, forKey: "maxHistoryCount")
        }
    }
    
    @Published var keyModifier: String {
        didSet {
            UserDefaults.standard.set(keyModifier, forKey: "keyModifier")
        }
    }
    
    @Published var keyCode: String {
        didSet {
            UserDefaults.standard.set(keyCode, forKey: "keyCode")
        }
    }
    
    private init() {
        self.maxHistoryCount = UserDefaults.standard.object(forKey: "maxHistoryCount") as? Int ?? 10
        self.keyModifier = UserDefaults.standard.string(forKey: "keyModifier") ?? "Ctrl+Shift"
        self.keyCode = UserDefaults.standard.string(forKey: "keyCode") ?? "P"
    }
    
    func getKeyCodeValue() -> UInt32 {
        switch keyCode {
        case "P": return 35
        case "C": return 8
        case "V": return 9
        case "H": return 4
        case "K": return 40
        case "L": return 37
        default: return 35
        }
    }
    
    func getModifierFlags() -> UInt32 {
        switch keyModifier {
        case "Cmd+Shift": return UInt32(cmdKey | shiftKey)
        case "Ctrl+Shift": return UInt32(controlKey | shiftKey)
        case "Option+Shift": return UInt32(optionKey | shiftKey)
        case "Cmd+Ctrl": return UInt32(cmdKey | controlKey)
        default: return UInt32(controlKey | shiftKey)
        }
    }
}

// MARK: - Clipboard Monitor
class ClipboardMonitor: ObservableObject {
    @Published var clipboardHistory: [ClipboardItem] = []
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let pasteboard = NSPasteboard.general
    private var settings = SettingsManager.shared
    
    struct ClipboardItem: Identifiable {
        let id = UUID()
        let text: String
        let timestamp: Date
    }
    
    func startMonitoring() {
        lastChangeCount = pasteboard.changeCount
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            self?.checkClipboard()
        }
    }
    
    func stopMonitoring() {
        timer?.invalidate()
        timer = nil
    }
    
    private func checkClipboard() {
        let currentChangeCount = pasteboard.changeCount
        
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            
            if let text = pasteboard.string(forType: .string), !text.isEmpty {
                if clipboardHistory.first?.text != text {
                    addToHistory(text: text)
                }
            }
        }
    }
    
    private func addToHistory(text: String) {
        let item = ClipboardItem(text: text, timestamp: Date())
        clipboardHistory.insert(item, at: 0)
        
        let maxCount = settings.maxHistoryCount
        if clipboardHistory.count > maxCount {
            clipboardHistory = Array(clipboardHistory.prefix(maxCount))
        }
    }
    
    func copyToClipboard(text: String) {
        pasteboard.clearContents()
        pasteboard.setString(text, forType: .string)
        lastChangeCount = pasteboard.changeCount
    }
}

// MARK: - Quick Panel View
struct QuickPanelView: View {
    @ObservedObject var clipboardMonitor: ClipboardMonitor
    @Binding var selectedIndex: String
    @Binding var isSearchVisible: Bool
    @Binding var selectedItemIndex: Int
    let onSelect: (Int) -> Void
    let onFilteredIndicesChange: ([Int]) -> Void
    @State private var searchText: String = ""
    @FocusState private var isSearchFocused: Bool
    
    // Fuzzy search filtering
    private var filteredHistory: [(index: Int, item: ClipboardMonitor.ClipboardItem)] {
        let history = clipboardMonitor.clipboardHistory.enumerated().map { ($0, $1) }
        
        if searchText.isEmpty {
            return Array(history)
        }
        
        let query = searchText.lowercased()
        return history.filter { _, item in
            fuzzyMatch(query: query, text: item.text.lowercased())
        }
    }
    
    // Simple fuzzy matching algorithm
    private func fuzzyMatch(query: String, text: String) -> Bool {
        var queryIndex = query.startIndex
        var textIndex = text.startIndex
        
        while queryIndex < query.endIndex && textIndex < text.endIndex {
            if query[queryIndex] == text[textIndex] {
                queryIndex = query.index(after: queryIndex)
            }
            textIndex = text.index(after: textIndex)
        }
        
        return queryIndex == query.endIndex
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Clipboard History")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Text("\(SettingsManager.shared.keyModifier)+\(SettingsManager.shared.keyCode)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            
            // Search field (toggleable with Cmd+F)
            if isSearchVisible {
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Search clipboard...", text: $searchText)
                        .textFieldStyle(.plain)
                        .focused($isSearchFocused)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                        .buttonStyle(.plain)
                    }
                    Button(action: { isSearchVisible = false }) {
                        Image(systemName: "xmark")
                            .foregroundColor(.gray)
                    }
                    .buttonStyle(.plain)
                    .help("Close search (Cmd+F)")
                }
                .padding(8)
                .background(Color(NSColor.controlBackgroundColor))
                .cornerRadius(8)
                .padding(.horizontal)
                .padding(.bottom, 8)
                .transition(.move(edge: .top).combined(with: .opacity))
            }
            
            Divider()
            
            if clipboardMonitor.clipboardHistory.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Text("No clipboard history")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Copy some text to get started")
                        .font(.subheadline)
                        .foregroundColor(.gray.opacity(0.8))
                    Spacer()
                }
                .frame(height: 200)
            } else if filteredHistory.isEmpty {
                VStack(spacing: 8) {
                    Spacer()
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 48))
                        .foregroundColor(.gray.opacity(0.5))
                    Text("No matches found")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text("Try a different search")
                        .font(.subheadline)
                        .foregroundColor(.gray.opacity(0.8))
                    Spacer()
                }
                .frame(height: 200)
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(Array(filteredHistory.enumerated()), id: \.element.item.id) { displayIndex, historyItem in
                            QuickPanelItemRow(
                                number: historyItem.index + 1,
                                item: historyItem.item,
                                isSelected: isSearchVisible ? (displayIndex == selectedItemIndex) : (historyItem.index == selectedItemIndex || selectedIndex == "\(historyItem.index + 1)"),
                                showNumber: !isSearchVisible,
                                onClick: {
                                    onSelect(historyItem.index)
                                },
                                searchQuery: searchText
                            )
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
            
            // Footer
            if !clipboardMonitor.clipboardHistory.isEmpty {
                Divider()
                HStack {
                    if searchText.isEmpty {
                        if isSearchVisible {
                            Text("\(filteredHistory.count) of \(clipboardMonitor.clipboardHistory.count) items")
                                .font(.caption)
                                .foregroundColor(.gray)
                        } else {
                            Text("Use arrows or type a number • Press Cmd+F to search")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("\(filteredHistory.count) of \(clipboardMonitor.clipboardHistory.count) items")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    if !selectedIndex.isEmpty && !isSearchVisible {
                        Text("Selected: \(selectedIndex)")
                            .font(.caption)
                            .foregroundColor(.blue)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
        }
        .frame(width: 600, height: 500)
        .background(Color(NSColor.windowBackgroundColor))
        .onChange(of: isSearchVisible) { _, newValue in
            if !newValue {
                searchText = ""
            } else {
                selectedItemIndex = 0
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    isSearchFocused = true
                }
            }
        }
        .onChange(of: filteredHistory.map { $0.index }) { _, newIndices in
            onFilteredIndicesChange(newIndices)
        }
    }
}

struct QuickPanelItemRow: View {
    let number: Int
    let item: ClipboardMonitor.ClipboardItem
    let isSelected: Bool
    var showNumber: Bool = true
    let onClick: () -> Void
    var searchQuery: String = ""
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onClick) {
            HStack(spacing: 12) {
                // Number badge (only shown when not searching)
                if showNumber {
                    Text("\(number)")
                        .font(.system(size: 16, weight: .bold, design: .monospaced))
                        .foregroundColor(.white)
                        .frame(width: 32, height: 32)
                        .background(isSelected ? Color.blue : (isHovered ? Color.gray.opacity(0.8) : Color.gray))
                        .cornerRadius(8)
                }
                
                // Content
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.text)
                        .font(.system(size: 13))
                        .lineLimit(2)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(timeAgo(from: item.timestamp))
                        .font(.system(size: 11))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isHovered {
                    Image(systemName: "hand.tap.fill")
                        .font(.system(size: 14))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isSelected ? Color.blue.opacity(0.1) : (isHovered ? Color.gray.opacity(0.05) : Color.clear))
        .cornerRadius(8)
        .padding(.horizontal, 8)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Settings View
struct SettingsView: View {
    @ObservedObject var settings = SettingsManager.shared
    let onClose: () -> Void
    let onHotkeyChange: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Settings")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
            }
            .padding()
            
            Divider()
            
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Max History Count
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Maximum Clipboard Items")
                            .font(.headline)
                        HStack {
                            Slider(value: Binding(
                                get: { Double(settings.maxHistoryCount) },
                                set: { settings.maxHistoryCount = Int($0) }
                            ), in: 5...50, step: 1)
                            Text("\(settings.maxHistoryCount)")
                                .frame(width: 30)
                                .font(.system(.body, design: .monospaced))
                        }
                        Text("Number of clipboard items to keep in history")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Divider()
                    
                    // Info about paste behavior
                    VStack(alignment: .leading, spacing: 8) {
                        Text("📋 Paste Behavior")
                            .font(.headline)
                        Text("Selected items are copied to clipboard. Press Cmd+V to paste them wherever you need.")
                            .font(.caption)
                            .foregroundColor(.gray)
                    }
                    
                    Divider()
                    
                    // Keyboard Shortcut
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Keyboard Shortcut")
                            .font(.headline)
                        
                        HStack {
                            Picker("Modifier", selection: $settings.keyModifier) {
                                Text("Cmd+Shift").tag("Cmd+Shift")
                                Text("Ctrl+Shift").tag("Ctrl+Shift")
                                Text("Option+Shift").tag("Option+Shift")
                                Text("Cmd+Ctrl").tag("Cmd+Ctrl")
                            }
                            .frame(width: 150)
                            
                            Text("+")
                                .foregroundColor(.gray)
                            
                            Picker("Key", selection: $settings.keyCode) {
                                Text("P").tag("P")
                                Text("C").tag("C")
                                Text("V").tag("V")
                                Text("H").tag("H")
                                Text("K").tag("K")
                                Text("L").tag("L")
                            }
                            .frame(width: 80)
                        }
                        
                        Text("Current: \(settings.keyModifier)+\(settings.keyCode)")
                            .font(.caption)
                            .foregroundColor(.blue)
                        
                        Text("⚠️ Restart required for shortcut changes to take effect")
                            .font(.caption)
                            .foregroundColor(.orange)
                            .padding(.top, 4)
                        
                        Button("Apply Shortcut Change") {
                            onHotkeyChange()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    
                    Spacer()
                }
                .padding()
            }
        }
        .frame(width: 400, height: 500)
    }
}

// MARK: - Content View
struct ContentView: View {
    @ObservedObject var clipboardMonitor: ClipboardMonitor
    let onSettingsClick: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Clipboard History")
                    .font(.headline)
                    .padding()
                Spacer()
                Button(action: onSettingsClick) {
                    Image(systemName: "gearshape.fill")
                        .foregroundColor(.gray)
                }
                .buttonStyle(.plain)
                .padding(.trailing)
            }
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            if clipboardMonitor.clipboardHistory.isEmpty {
                VStack {
                    Spacer()
                    Text("No clipboard history yet")
                        .foregroundColor(.gray)
                        .font(.subheadline)
                    Text("Copy some text to get started")
                        .foregroundColor(.gray)
                        .font(.caption)
                    Spacer()
                }
            } else {
                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(clipboardMonitor.clipboardHistory) { item in
                            ClipboardItemRow(item: item, onCopy: {
                                clipboardMonitor.copyToClipboard(text: item.text)
                            })
                            
                            if item.id != clipboardMonitor.clipboardHistory.last?.id {
                                Divider()
                            }
                        }
                    }
                }
            }
        }
        .frame(width: 300, height: 400)
    }
}

struct ClipboardItemRow: View {
    let item: ClipboardMonitor.ClipboardItem
    let onCopy: () -> Void
    @State private var isHovered = false
    
    var body: some View {
        Button(action: onCopy) {
            HStack(alignment: .top, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(item.text)
                        .font(.system(size: 12))
                        .lineLimit(3)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .multilineTextAlignment(.leading)
                    
                    Text(timeAgo(from: item.timestamp))
                        .font(.system(size: 10))
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                if isHovered {
                    Image(systemName: "doc.on.doc")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .background(isHovered ? Color.blue.opacity(0.1) : Color.clear)
        .onHover { hovering in
            isHovered = hovering
        }
    }
    
    private func timeAgo(from date: Date) -> String {
        let seconds = Date().timeIntervalSince(date)
        
        if seconds < 60 {
            return "Just now"
        } else if seconds < 3600 {
            let minutes = Int(seconds / 60)
            return "\(minutes)m ago"
        } else if seconds < 86400 {
            let hours = Int(seconds / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(seconds / 86400)
            return "\(days)d ago"
        }
    }
}

// MARK: - Panel State
class PanelState: ObservableObject {
    @Published var selectedIndex: String = ""
    @Published var isSearchVisible: Bool = false
    @Published var selectedItemIndex: Int = 0 // For arrow key navigation
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var clipboardMonitor: ClipboardMonitor?
    var quickPanelWindow: NSWindow?
    var settingsWindow: NSWindow?
    var hotKeyRef: EventHotKeyRef?
    var eventHandlerRef: EventHandlerRef?
    var panelState = PanelState()
    var previousApp: NSRunningApplication?
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard Manager")
            button.action = #selector(togglePopover)
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }
        
        // Create context menu
        setupContextMenu()
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 400)
        popover?.behavior = .transient
        
        clipboardMonitor = ClipboardMonitor()
        
        if let monitor = clipboardMonitor {
            popover?.contentViewController = NSHostingController(rootView: ContentView(
                clipboardMonitor: monitor,
                onSettingsClick: { [weak self] in
                    self?.showSettings()
                }
            ))
        }
        
        clipboardMonitor?.startMonitoring()
        
        // Register global hotkey (Ctrl+Shift+P)
        registerGlobalHotkey()
    }
    
    
    func registerGlobalHotkey() {
        // Unregister existing hotkey if any
        if let hotKey = hotKeyRef {
            UnregisterEventHotKey(hotKey)
        }
        if let handler = eventHandlerRef {
            RemoveEventHandler(handler)
        }
        
        let settings = SettingsManager.shared
        var eventHotKey: EventHotKeyRef?
        let modifiers = settings.getModifierFlags()
        let keyCode = settings.getKeyCodeValue()
        
        var eventType = EventTypeSpec()
        eventType.eventClass = OSType(kEventClassKeyboard)
        eventType.eventKind = OSType(kEventHotKeyPressed)
        
        let hotKeyID = EventHotKeyID(signature: OSType(0x48545259), id: 1)
        
        RegisterEventHotKey(keyCode, modifiers, hotKeyID, GetEventDispatcherTarget(), 0, &eventHotKey)
        hotKeyRef = eventHotKey
        
        // Install event handler
        var eventHandler: EventHandlerRef?
        var eventTypes = [eventType]
        
        InstallEventHandler(GetEventDispatcherTarget(), { _, event, userData in
            let appDelegate = Unmanaged<AppDelegate>.fromOpaque(userData!).takeUnretainedValue()
            appDelegate.showQuickPanel()
            return noErr
        }, 1, &eventTypes, Unmanaged.passUnretained(self).toOpaque(), &eventHandler)
        
        eventHandlerRef = eventHandler
    }
    
    @objc func showQuickPanel() {
        // Store the currently active app before showing panel
        previousApp = NSWorkspace.shared.frontmostApplication
        
        panelState.selectedIndex = ""
        
        if quickPanelWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 600, height: 500),
                styleMask: [.titled, .closable, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )
            
            window.isReleasedWhenClosed = false
            window.center()
            window.level = .floating
            window.titlebarAppearsTransparent = true
            window.titleVisibility = .hidden
            window.isMovableByWindowBackground = true
            
            quickPanelWindow = window
        }
        
        if let monitor = clipboardMonitor {
            let contentView = QuickPanelWindowView(
                clipboardMonitor: monitor,
                panelState: panelState,
                onSelect: { [weak self] index in
                    self?.selectClipboardItem(at: index)
                },
                onClose: { [weak self] in
                    self?.hideQuickPanel()
                }
            )
            quickPanelWindow?.contentView = NSHostingView(rootView: contentView)
        }
        
        quickPanelWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func hideQuickPanel() {
        quickPanelWindow?.orderOut(nil)
        panelState.selectedIndex = ""
        panelState.isSearchVisible = false
    }
    
    func selectClipboardItem(at index: Int) {
        guard let monitor = clipboardMonitor,
              index >= 0 && index < monitor.clipboardHistory.count else {
            return
        }
        
        let item = monitor.clipboardHistory[index]
        monitor.copyToClipboard(text: item.text)
        
        print("📋 Selected item: \(item.text.prefix(50))...")
        print("✅ Copied to clipboard - press Cmd+V to paste")
        
        hideQuickPanel()
        
        // Return focus to previous app
        if let prevApp = previousApp, prevApp.bundleIdentifier != Bundle.main.bundleIdentifier {
            print("🎯 Returning focus to: \(prevApp.localizedName ?? "Unknown")")
            prevApp.activate(options: [])
        }
    }
    
    
    func showSettings() {
        popover?.performClose(nil)
        
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 400, height: 500),
                styleMask: [.titled, .closable, .resizable],
                backing: .buffered,
                defer: false
            )
            
            window.title = "Clipboard Manager Settings"
            window.isReleasedWhenClosed = false
            window.center()
            
            settingsWindow = window
        }
        
        let settingsView = SettingsView(
            onClose: { [weak self] in
                self?.settingsWindow?.orderOut(nil)
            },
            onHotkeyChange: { [weak self] in
                self?.registerGlobalHotkey()
            }
        )
        
        settingsWindow?.contentView = NSHostingView(rootView: settingsView)
        settingsWindow?.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }
    
    func setupContextMenu() {
        // We'll handle the menu manually in togglePopover
    }
    
    @objc func togglePopover(_ sender: Any?) {
        guard let event = NSApp.currentEvent else { return }
        
        // Right-click shows menu, left-click shows popover
        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "About Clipboard Manager", action: #selector(showAbout), keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Clear History", action: #selector(clearHistory), keyEquivalent: ""))
            menu.addItem(NSMenuItem(title: "Restart", action: #selector(restartApp), keyEquivalent: "r"))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit", action: #selector(quitApp), keyEquivalent: "q"))
            
            if let button = statusItem?.button {
                menu.popUp(positioning: nil, at: CGPoint(x: 0, y: button.bounds.height), in: button)
            }
        } else {
            if let button = statusItem?.button {
                if popover?.isShown == true {
                    popover?.performClose(nil)
                } else {
                    popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
                }
            }
        }
    }
    
    @objc func showAbout() {
        let alert = NSAlert()
        alert.messageText = "Clipboard Manager"
        alert.informativeText = "Version 1.0\n\nA simple menu bar clipboard manager for macOS.\n\nFeatures:\n• Track up to 50 clipboard items\n• Quick access with keyboard shortcuts\n• Customizable settings\n\nBuilt with Swift and SwiftUI"
        alert.alertStyle = .informational
        alert.addButton(withTitle: "OK")
        alert.runModal()
    }
    
    @objc func clearHistory() {
        let alert = NSAlert()
        alert.messageText = "Clear Clipboard History?"
        alert.informativeText = "This will remove all saved clipboard items. This action cannot be undone."
        alert.alertStyle = .warning
        alert.addButton(withTitle: "Clear")
        alert.addButton(withTitle: "Cancel")
        
        let response = alert.runModal()
        if response == .alertFirstButtonReturn {
            clipboardMonitor?.clipboardHistory.removeAll()
            print("🗑️ Clipboard history cleared")
        }
    }
    
    @objc func restartApp() {
        let url = URL(fileURLWithPath: Bundle.main.resourcePath!)
        let path = url.deletingLastPathComponent().deletingLastPathComponent().absoluteString
        let task = Process()
        task.launchPath = "/usr/bin/open"
        task.arguments = [path]
        task.launch()
        NSApplication.shared.terminate(nil)
    }
    
    @objc func quitApp() {
        NSApplication.shared.terminate(nil)
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        clipboardMonitor?.stopMonitoring()
    }
}

// MARK: - Quick Panel Window View
struct QuickPanelWindowView: View {
    @ObservedObject var clipboardMonitor: ClipboardMonitor
    @ObservedObject var panelState: PanelState
    let onSelect: (Int) -> Void
    let onClose: () -> Void
    @State private var filteredIndices: [Int] = []
    
    private var filteredCount: Int {
        filteredIndices.count
    }
    
    var body: some View {
        QuickPanelView(
            clipboardMonitor: clipboardMonitor,
            selectedIndex: $panelState.selectedIndex,
            isSearchVisible: $panelState.isSearchVisible,
            selectedItemIndex: $panelState.selectedItemIndex,
            onSelect: onSelect,
            onFilteredIndicesChange: { indices in
                filteredIndices = indices
            }
        )
        .onAppear {
            // Initialize filteredIndices with all items
            filteredIndices = Array(0..<clipboardMonitor.clipboardHistory.count)
            
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                // Check arrow keys and Return - intercept them in both modes
                if event.keyCode == 125 || event.keyCode == 126 || event.keyCode == 36 { // Down, Up, Return
                    let _ = handleKeyPress(event)
                    return nil // Consume the event
                }
                
                let handled = handleKeyPress(event)
                return handled ? nil : event
            }
        }
    }
    
    func handleKeyPress(_ event: NSEvent) -> Bool {
        // Escape - close search first if open, then close window
        if event.keyCode == 53 {
            if panelState.isSearchVisible {
                panelState.isSearchVisible = false
            } else {
                onClose()
            }
            return true
        }
        
        // Cmd+F - toggle search
        if event.keyCode == 3 && event.modifierFlags.contains(.command) {
            panelState.isSearchVisible.toggle()
            return true
        }
        
        // Arrow keys - navigate in both modes
        if event.keyCode == 125 { // Down arrow
            if panelState.isSearchVisible {
                let maxIndex = max(0, filteredCount - 1)
                panelState.selectedItemIndex = min(panelState.selectedItemIndex + 1, maxIndex)
            } else {
                let maxIndex = max(0, clipboardMonitor.clipboardHistory.count - 1)
                panelState.selectedItemIndex = min(panelState.selectedItemIndex + 1, maxIndex)
            }
            return true
        } else if event.keyCode == 126 { // Up arrow
            panelState.selectedItemIndex = max(panelState.selectedItemIndex - 1, 0)
            return true
        } else if event.keyCode == 36 { // Return - select current item
            if panelState.isSearchVisible {
                if filteredCount > 0 && panelState.selectedItemIndex < filteredCount {
                    // Get the actual history index from filtered indices
                    let actualIndex = filteredIndices[panelState.selectedItemIndex]
                    onSelect(actualIndex)
                }
            } else {
                // In non-search mode, use arrow-selected index if set, otherwise fall back to number selection
                if panelState.selectedItemIndex >= 0 && panelState.selectedItemIndex < clipboardMonitor.clipboardHistory.count {
                    onSelect(panelState.selectedItemIndex)
                } else if let index = Int(panelState.selectedIndex), index > 0 && index <= clipboardMonitor.clipboardHistory.count {
                    onSelect(index - 1)
                }
            }
            return true
        }
        
        // Number key selection when search is not visible
        if !panelState.isSearchVisible {
            if let char = event.charactersIgnoringModifiers, char.count == 1 {
                let character = char.first!
                if character.isNumber {
                    panelState.selectedIndex += String(character)
                    if let index = Int(panelState.selectedIndex), index > 0 && index <= clipboardMonitor.clipboardHistory.count {
                        onSelect(index - 1)
                        return true
                    }
                }
            }
        }
        
        return false
    }
}

// MARK: - Main App
@main
struct ClipboardManagerApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    
    var body: some Scene {
        Settings {
            EmptyView()
        }
    }
}
