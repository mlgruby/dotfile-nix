import Foundation
import AppKit

let fileManager = FileManager.default
let home = fileManager.homeDirectoryForCurrentUser
let shotDir = home.appendingPathComponent("Screenshots")

// 1. Ensure ~/Screenshots directory exists
try? fileManager.createDirectory(at: shotDir, withIntermediateDirectories: true)

// 2. Generate timestamped file path
let formatter = DateFormatter()
formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
let timestamp = formatter.string(from: Date())
let fileURL = shotDir.appendingPathComponent("Screenshot \(timestamp).png")
let filePath = fileURL.path

// 3. Launch macOS interactive selection
let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
process.arguments = ["-i", filePath]

do {
    try process.run()
    process.waitUntilExit()
} catch {
    exit(1)
}

// 4. User pressed Escape or canceled selection
guard process.terminationStatus == 0, fileManager.fileExists(atPath: filePath) else {
    exit(0)
}

// 5. Dual-representation clipboard:
//    - public.utf8-plain-text (file path for CLI / terminal agents like Antigravity, Claude, Codex)
//    - public.png (raw image binary for web apps, Slack, ChatGPT, Discord, Notion)
//    - public.file-url (file URL for Finder and drag-and-drop)
if let imgData = try? Data(contentsOf: fileURL) {
    let pb = NSPasteboard.general
    pb.clearContents()

    let item = NSPasteboardItem()
    item.setString(filePath, forType: .string)
    item.setData(imgData, forType: .png)
    item.setString(fileURL.absoluteString, forType: .fileURL)

    pb.writeObjects([item])
}

// 6. Native macOS Trash auto-pruning for screenshots older than 3 days
let threeDaysAgo = Date().addingTimeInterval(-3 * 24 * 3600)
if let files = try? fileManager.contentsOfDirectory(
    at: shotDir,
    includingPropertiesForKeys: [.contentModificationDateKey]
) {
    for file in files where file.lastPathComponent.hasPrefix("Screenshot ") && file.pathExtension == "png" {
        if let attrs = try? file.resourceValues(forKeys: [.contentModificationDateKey]),
           let modDate = attrs.contentModificationDate,
           modDate < threeDaysAgo {
            try? fileManager.trashItem(at: file, resultingItemURL: nil)
        }
    }
}
