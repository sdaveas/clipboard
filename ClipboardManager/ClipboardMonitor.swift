import AppKit
import Combine

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
        // Get initial clipboard count
        lastChangeCount = pasteboard.changeCount
        
        // Check clipboard every 0.5 seconds
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
        
        // If clipboard has changed
        if currentChangeCount != lastChangeCount {
            lastChangeCount = currentChangeCount
            
            // Get the string from clipboard
            if let text = pasteboard.string(forType: .string), !text.isEmpty {
                // Don't add if it's the same as the most recent item
                if clipboardHistory.first?.text != text {
                    addToHistory(text: text)
                }
            }
        }
    }
    
    private func addToHistory(text: String) {
        let item = ClipboardItem(text: text, timestamp: Date())
        
        // Add to beginning of array
        clipboardHistory.insert(item, at: 0)
        
        // Keep only last 10 items
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
