#!/usr/bin/env swift
// Reproducible vector-drawn app icon. Run from the repository root.
import AppKit

let destination = URL(fileURLWithPath: "ZenBackupManager/Assets.xcassets/AppIcon.appiconset", isDirectory: true)
try FileManager.default.createDirectory(at: destination, withIntermediateDirectories: true)
var entries: [[String: String]] = []
for points in [16, 32, 128, 256, 512] {
    for scale in [1, 2] {
        let size = points * scale
        let image = NSImage(size: NSSize(width: size, height: size))
        image.lockFocus()
        let transform = NSAffineTransform(); transform.scale(by: CGFloat(size) / 1024); transform.concat()
        let background = NSBezierPath(roundedRect: NSRect(x: 80, y: 80, width: 864, height: 864), xRadius: 192, yRadius: 192)
        NSGradient(starting: NSColor(calibratedRed: 0.08, green: 0.48, blue: 0.51, alpha: 1),
                   ending: NSColor(calibratedRed: 0.03, green: 0.20, blue: 0.27, alpha: 1))?.draw(in: background, angle: -60)
        for offset in [48.0, 24.0, 0.0] {
            let frame = NSRect(x: 254 + offset, y: 295 + offset, width: 455, height: 392)
            let window = NSBezierPath(roundedRect: frame, xRadius: 44, yRadius: 44)
            NSColor(calibratedWhite: 1, alpha: offset == 0 ? 0.96 : 0.19).setFill(); window.fill()
        }
        NSColor(calibratedRed: 0.08, green: 0.39, blue: 0.44, alpha: 1).setFill()
        for x in [291.0, 325.0, 359.0] { NSBezierPath(ovalIn: NSRect(x: x, y: 639, width: 15, height: 15)).fill() }
        let arc = NSBezierPath()
        arc.appendArc(withCenter: NSPoint(x: 480, y: 474), radius: 99, startAngle: 145, endAngle: -140, clockwise: true)
        arc.lineWidth = 34; arc.lineCapStyle = .round
        NSColor(calibratedRed: 0.08, green: 0.49, blue: 0.51, alpha: 1).setStroke(); arc.stroke()
        let arrow = NSBezierPath()
        arrow.move(to: NSPoint(x: 374, y: 567)); arrow.line(to: NSPoint(x: 375, y: 503)); arrow.line(to: NSPoint(x: 438, y: 524))
        arrow.lineWidth = 28; arrow.lineCapStyle = .round; arrow.lineJoinStyle = .round; arrow.stroke()
        image.unlockFocus()
        guard let tiff = image.tiffRepresentation, let rep = NSBitmapImageRep(data: tiff),
              let png = rep.representation(using: .png, properties: [:]) else { fatalError("Icon rendering failed") }
        let name = "icon_\(points)x\(points)@\(scale)x.png"
        try png.write(to: destination.appendingPathComponent(name))
        entries.append(["idiom": "mac", "size": "\(points)x\(points)", "scale": "\(scale)x", "filename": name])
    }
}
let contents: [String: Any] = ["images": entries, "info": ["author": "xcode", "version": 1]]
try JSONSerialization.data(withJSONObject: contents, options: [.prettyPrinted, .sortedKeys]).write(to: destination.appendingPathComponent("Contents.json"))
