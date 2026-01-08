import SwiftUI

struct ContentView: View {
    @ObservedObject var clipboardMonitor: ClipboardMonitor
    
    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Clipboard History")
                    .font(.headline)
                    .padding()
                Spacer()
            }
            .background(Color.gray.opacity(0.1))
            
            Divider()
            
            // Clipboard items list
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

#Preview {
    ContentView(clipboardMonitor: ClipboardMonitor())
}
