import AppKit
import SwiftUI

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

// MARK: - App Delegate
class AppDelegate: NSObject, NSApplicationDelegate {
    var statusItem: NSStatusItem?
    var popover: NSPopover?
    var clipboardMonitor: ClipboardMonitor?
    
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
