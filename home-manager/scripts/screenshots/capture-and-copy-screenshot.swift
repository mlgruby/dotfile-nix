import Foundation
import AppKit

let fileManager = FileManager.default
let home = fileManager.homeDirectoryForCurrentUser
let shotDir = home.appendingPathComponent("Screenshots")

try? fileManager.createDirectory(at: shotDir, withIntermediateDirectories: true)

let formatter = DateFormatter()
formatter.dateFormat = "yyyy-MM-dd 'at' HH.mm.ss"
let timestamp = formatter.string(from: Date())
let fileURL = shotDir.appendingPathComponent("Screenshot \(timestamp).png")

let process = Process()
process.executableURL = URL(fileURLWithPath: "/usr/sbin/screencapture")
process.arguments = ["-i", "-x", fileURL.path]

do {
    try process.run()
} catch {
    exit(1)
}

// Wait until either screencapture exits OR the PNG file is completely written (ends with 12-byte PNG IEND chunk).
// /usr/sbin/screencapture calls MDItemSetAttributes (Spotlight mds) after closing the PNG file, which can hang
// for 60+ seconds when mds is busy and block the clipboard update if we wait for process exit first.
let pngIEND = Data([0x00, 0x00, 0x00, 0x00, 0x49, 0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82])
var capturedData: Data? = nil

while process.isRunning {
    if let data = try? Data(contentsOf: fileURL),
       data.count > 24,
       data.suffix(12) == pngIEND {
        capturedData = data
        break
    }
    usleep(20_000)
}

if capturedData == nil {
    process.waitUntilExit()
    guard process.terminationStatus == 0,
          fileManager.fileExists(atPath: fileURL.path),
          let data = try? Data(contentsOf: fileURL),
          !data.isEmpty else {
        exit(0)
    }
    capturedData = data
}

if let imageData = capturedData {
    let pasteboard = NSPasteboard.general
    pasteboard.clearContents()

    let item = NSPasteboardItem()
    item.setData(imageData, forType: .png)
    item.setString(fileURL.absoluteString, forType: .fileURL)
    item.setString(fileURL.path, forType: .string)
    pasteboard.writeObjects([item])

    let soundPaths = [
        "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Screen Capture.aif",
        "/System/Library/Components/CoreAudio.component/Contents/SharedSupport/SystemSounds/system/Shutter.aif"
    ]
    if let soundPath = soundPaths.first(where: { fileManager.fileExists(atPath: $0) }) {
        let soundProcess = Process()
        soundProcess.executableURL = URL(fileURLWithPath: "/usr/bin/afplay")
        soundProcess.arguments = [soundPath]
        try? soundProcess.run()
    }
}

let cutoff = Date().addingTimeInterval(-3 * 24 * 60 * 60)
if let files = try? fileManager.contentsOfDirectory(
    at: shotDir,
    includingPropertiesForKeys: [.contentModificationDateKey]
) {
    for file in files where file.lastPathComponent.hasPrefix("Screenshot ") && file.pathExtension == "png" {
        if let values = try? file.resourceValues(forKeys: [.contentModificationDateKey]),
           let modified = values.contentModificationDate,
           modified < cutoff {
            try? fileManager.trashItem(at: file, resultingItemURL: nil)
        }
    }
}
