import AppKit

guard CommandLine.arguments.count > 1 else {
    exit(1)
}

let path = CommandLine.arguments[1]
let url = URL(fileURLWithPath: path)

guard let data = try? Data(contentsOf: url) else {
    exit(1)
}

let pb = NSPasteboard.general
pb.clearContents()

let item = NSPasteboardItem()
item.setString(path, forType: .string)
item.setData(data, forType: .png)
item.setString(url.absoluteString, forType: .fileURL)

pb.writeObjects([item])
