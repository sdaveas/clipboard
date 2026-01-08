import AppKit
import SwiftUI
import Carbon

// MARK: - Clipboard Monitor
class ClipboardMonitor: ObservableObject {
    @Published var clipboardHistory: [ClipboardItem] = []
    
    private var timer: Timer?
    private var lastChangeCount: Int = 0
    private let pasteboard = NSPasteboard.general
    private let maxHistoryCount = 10
    
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
        
        if clipboardHistory.count > maxHistoryCount {
            clipboardHistory = Array(clipboardHistory.prefix(maxHistoryCount))
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
    let onSelect: (Int) -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Clipboard History")
                    .font(.title2)
                    .fontWeight(.semibold)
                Spacer()
                Text("Ctrl+Shift+P")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding()
            
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
            } else {
                ScrollView {
                    VStack(spacing: 4) {
                        ForEach(Array(clipboardMonitor.clipboardHistory.enumerated()), id: \.element.id) { index, item in
                            QuickPanelItemRow(
                                number: index + 1,
                                item: item,
                                isSelected: selectedIndex == "\(index + 1)"
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
                    Text("Type a number (1-\(clipboardMonitor.clipboardHistory.count)) to paste")
                        .font(.caption)
                        .foregroundColor(.gray)
                    Spacer()
                    if !selectedIndex.isEmpty {
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
    }
}

struct QuickPanelItemRow: View {
    let number: Int
    let item: ClipboardMonitor.ClipboardItem
    let isSelected: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Number badge
            Text("\(number)")
                .font(.system(size: 16, weight: .bold, design: .monospaced))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(isSelected ? Color.blue : Color.gray)
                .cornerRadius(8)
            
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
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(isSelected ? Color.blue.opacity(0.1) : Color.clear)
        .cornerRadius(8)
        .padding(.horizontal, 8)
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

// MARK: - Content View
struct ContentView: View {
    @ObservedObject var clipboardMonitor: ClipboardMonitor
    
    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Clipboard History")
                    .font(.headline)
                    .padding()
                Spacer()
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
    @Published var selectedIndex = ""
}

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var clipboardMonitor: ClipboardMonitor?
    var quickPanelWindow: NSWindow?
    var hotKeyRef: EventHotKeyRef?
    var panelState = PanelState()
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        
        if let button = statusItem?.button {
            button.image = NSImage(systemSymbolName: "doc.on.clipboard", accessibilityDescription: "Clipboard Manager")
            button.action = #selector(togglePopover)
            button.target = self
        }
        
        popover = NSPopover()
        popover?.contentSize = NSSize(width: 300, height: 400)
        popover?.behavior = .transient
        
        clipboardMonitor = ClipboardMonitor()
        
        if let monitor = clipboardMonitor {
            popover?.contentViewController = NSHostingController(rootView: ContentView(clipboardMonitor: monitor))
        }
        
        clipboardMonitor?.startMonitoring()
        
        // Register global hotkey (Ctrl+Shift+P)
        registerGlobalHotkey()
    }
    
    func registerGlobalHotkey() {
        var eventHotKey: EventHotKeyRef?
        let modifiers: UInt32 = UInt32(controlKey | shiftKey)
        let keyCode: UInt32 = 35 // P key
        
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
    }
    
    @objc func showQuickPanel() {
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
    }
    
    func selectClipboardItem(at index: Int) {
        guard let monitor = clipboardMonitor,
              index >= 0 && index < monitor.clipboardHistory.count else {
            return
        }
        
        let item = monitor.clipboardHistory[index]
        monitor.copyToClipboard(text: item.text)
        hideQuickPanel()
        
        // Simulate paste (Cmd+V)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            let src = CGEventSource(stateID: .hidSystemState)
            let cmdd = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: true) // V key
            let cmdu = CGEvent(keyboardEventSource: src, virtualKey: 0x09, keyDown: false)
            cmdd?.flags = .maskCommand
            cmdu?.flags = .maskCommand
            cmdd?.post(tap: .cghidEventTap)
            cmdu?.post(tap: .cghidEventTap)
        }
    }
    
    @objc func togglePopover() {
        if let button = statusItem?.button {
            if popover?.isShown == true {
                popover?.performClose(nil)
            } else {
                popover?.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            }
        }
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
    
    var body: some View {
        QuickPanelView(
            clipboardMonitor: clipboardMonitor,
            selectedIndex: $panelState.selectedIndex,
            onSelect: onSelect
        )
        .onAppear {
            NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
                handleKeyPress(event)
                return nil
            }
        }
    }
    
    func handleKeyPress(_ event: NSEvent) {
        if event.keyCode == 53 { // Escape
            onClose()
        } else if event.keyCode == 36 { // Return
            if let index = Int(panelState.selectedIndex), index > 0 && index <= clipboardMonitor.clipboardHistory.count {
                onSelect(index - 1)
            }
        } else if let char = event.charactersIgnoringModifiers, char.count == 1 {
            let character = char.first!
            if character.isNumber {
                panelState.selectedIndex += String(character)
                if let index = Int(panelState.selectedIndex), index > 0 && index <= clipboardMonitor.clipboardHistory.count {
                    onSelect(index - 1)
                }
            }
        }
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
