#!/usr/bin/env swift

import AppKit
import CoreGraphics

func createAppIcon(size: CGSize, outputPath: String) {
    let image = NSImage(size: size)

    image.lockFocus()

    guard let context = NSGraphicsContext.current?.cgContext else {
        print("Failed to get graphics context")
        return
    }

    // Clear background (transparent)
    context.clear(CGRect(origin: .zero, size: size))

    // Scale factor to fit the icon in the canvas (finger icon viewBox is 54x54)
    let scale = min(size.width / 54.0, size.height / 54.0)
    let offsetX = (size.width - 54.0 * scale) / 2.0
    let offsetY = (size.height - 54.0 * scale) / 2.0

    context.translateBy(x: offsetX, y: size.height - offsetY)
    context.scaleBy(x: scale, y: -scale)  // Flip Y axis

    // Set fill color to black
    context.setFillColor(NSColor.black.cgColor)

    // Draw all paths from finger_easyshortcut.svg
    let paths = [
        "M22.7602 2.27813C22.0641 2.61563 22.043 2.80547 22.043 6.15938C22.043 8.50078 22.0641 9.21797 22.1906 9.49219C22.4648 10.125 23.2031 10.4203 23.8359 10.125C24.5742 9.76641 24.5742 9.7875 24.5531 6.20156C24.532 2.65781 24.5109 2.55234 23.8781 2.25703C23.4141 2.04609 23.2031 2.04609 22.7602 2.27813Z",
        "M14.8711 5.48437C14.4703 5.63203 14.1539 5.96953 14.0484 6.30703C13.8375 7.04531 13.943 7.17187 16.2 9.47109C17.3813 10.6734 18.457 11.707 18.6258 11.7914C19.7227 12.3609 20.9039 11.1586 20.3344 10.0828C20.1023 9.66093 16.0102 5.63203 15.6727 5.50547C15.3563 5.4 15.1242 5.4 14.8711 5.48437Z",
        "M30.9023 5.56875C30.7336 5.65313 29.5945 6.70781 28.3922 7.93125L26.1773 10.1461V10.6945C26.1773 11.1586 26.2195 11.2852 26.4727 11.5383C26.6414 11.707 26.8945 11.8758 27.0422 11.918C27.7172 12.0867 27.8859 11.9602 30.2906 9.53438L32.5898 7.21406V6.75C32.5898 6.18047 32.3156 5.77969 31.8094 5.56875C31.3875 5.37891 31.3031 5.37891 30.9023 5.56875Z",
        "M22.0852 12.0867C21.5367 12.3398 21.0305 12.8461 20.7141 13.4367C20.5453 13.7531 20.5242 14.4703 20.5031 24.4898L20.482 35.2266L18.6891 33.4336C16.5586 31.3242 16.1578 31.0711 14.8922 31.0922C13.9852 31.0922 13.3735 31.3242 12.7195 31.9148C11.7492 32.7797 11.4328 34.2563 11.8969 35.543C12.1078 36.1336 12.361 36.4078 15.3563 39.4242C17.1492 41.2172 18.9 43.0734 19.2797 43.5164C20.9461 45.5414 22.6969 48.1781 24.0469 50.6461L24.7008 51.8695H32.2945H39.8883L40.5633 50.2875C41.7867 47.3766 42.6727 44.6555 43.1367 42.3141C43.3688 41.1539 43.3688 41.0063 43.3688 34.7203C43.3688 28.3922 43.3688 28.2867 43.1578 27.8016C42.6727 26.7891 41.85 26.2406 40.6477 26.1773C39.9938 26.1352 39.825 26.1562 39.3399 26.4094C38.6649 26.7469 38.1164 27.3375 37.8633 28.0547L37.6735 28.582L37.6313 27.1898C37.5891 25.9031 37.568 25.7555 37.2938 25.2914C36.0492 23.2031 33.0117 23.4562 32.1469 25.7344L31.936 26.3039V25.5656C31.9149 23.7937 30.607 22.5281 28.9195 22.6336C28.5188 22.6547 28.0547 22.7812 27.8016 22.9078C27.0633 23.2875 26.3461 24.2367 26.2828 24.9117C26.2828 25.0383 26.2406 22.6336 26.1985 19.5328L26.1563 13.9219L25.8399 13.2891C25.5867 12.8039 25.3758 12.593 24.9117 12.2555C24.3422 11.8547 24.2578 11.8336 23.4774 11.8125C22.7391 11.8547 22.507 11.8758 22.0852 12.0867Z",
        "M11.3695 13.6688C10.7578 13.943 10.4625 14.6812 10.7578 15.3141C11.0742 15.9891 11.1586 15.9891 14.7023 15.9891C17.2758 15.9891 17.9297 15.968 18.1617 15.8414C18.457 15.6937 18.7945 15.1453 18.7945 14.8078C18.7945 14.4492 18.4781 13.9219 18.1617 13.7109C17.8453 13.5211 17.6555 13.5 14.7656 13.5C12.4031 13.5211 11.6438 13.5422 11.3695 13.6688Z",
        "M28.6031 13.6055C27.9703 13.8586 27.6539 14.7234 27.9914 15.3773C28.3078 16.0102 28.2867 16.0102 31.9148 16.0102H35.2266L35.5851 15.6516C35.8805 15.3563 35.9437 15.2086 35.9437 14.8711C35.9437 14.2805 35.7117 13.8797 35.2898 13.6688C34.9945 13.5211 34.5094 13.5 31.8937 13.5211C30.1851 13.5211 28.7297 13.5633 28.6031 13.6055Z"
    ]

    for pathData in paths {
        let path = parseSVGPath(pathData)
        context.addPath(path)
        context.fillPath()
    }

    image.unlockFocus()

    // Save as PNG
    guard let tiffData = image.tiffRepresentation,
          let bitmapImage = NSBitmapImageRep(data: tiffData),
          let pngData = bitmapImage.representation(using: .png, properties: [:]) else {
        print("Failed to create PNG data")
        return
    }

    do {
        try pngData.write(to: URL(fileURLWithPath: outputPath))
        print("✓ Created \(outputPath) (\(Int(size.width))x\(Int(size.height)))")
    } catch {
        print("✗ Failed to write \(outputPath): \(error)")
    }
}

// Simple SVG path parser
func parseSVGPath(_ pathData: String) -> CGPath {
    let path = CGMutablePath()
    var currentPoint = CGPoint.zero

    var commands: [(String, String)] = []
    var currentCommand = ""
    var currentArgs = ""

    for char in pathData {
        if char.isLetter {
            if !currentCommand.isEmpty {
                commands.append((currentCommand, currentArgs.trimmingCharacters(in: .whitespaces)))
                currentArgs = ""
            }
            currentCommand = String(char)
        } else {
            currentArgs.append(char)
        }
    }
    if !currentCommand.isEmpty {
        commands.append((currentCommand, currentArgs.trimmingCharacters(in: .whitespaces)))
    }

    for (command, argsString) in commands {
        let args = argsString.split(separator: " ").compactMap { Double($0) }

        switch command {
        case "M":
            if args.count >= 2 {
                currentPoint = CGPoint(x: args[0], y: args[1])
                path.move(to: currentPoint)
            }
        case "L":
            if args.count >= 2 {
                currentPoint = CGPoint(x: args[0], y: args[1])
                path.addLine(to: currentPoint)
            }
        case "H":
            if args.count >= 1 {
                currentPoint = CGPoint(x: args[0], y: currentPoint.y)
                path.addLine(to: currentPoint)
            }
        case "V":
            if args.count >= 1 {
                currentPoint = CGPoint(x: currentPoint.x, y: args[0])
                path.addLine(to: currentPoint)
            }
        case "C":
            if args.count >= 6 {
                let cp1 = CGPoint(x: args[0], y: args[1])
                let cp2 = CGPoint(x: args[2], y: args[3])
                currentPoint = CGPoint(x: args[4], y: args[5])
                path.addCurve(to: currentPoint, control1: cp1, control2: cp2)
            }
        case "Z", "z":
            path.closeSubpath()
        default:
            break
        }
    }

    return path
}

print("Generating app icons...")




// macOS app icon sizes according to Apple HIG
let sizes: [(Int, String)] = [
    (16, "Assets.xcassets/AppIcon.appiconset/icon_16x16.png"),
    (32, "Assets.xcassets/AppIcon.appiconset/icon_16x16@2x.png"),
    (32, "Assets.xcassets/AppIcon.appiconset/icon_32x32.png"),
    (64, "Assets.xcassets/AppIcon.appiconset/icon_32x32@2x.png"),
    (128, "Assets.xcassets/AppIcon.appiconset/icon_128x128.png"),
    (256, "Assets.xcassets/AppIcon.appiconset/icon_128x128@2x.png"),
    (256, "Assets.xcassets/AppIcon.appiconset/icon_256x256.png"),
    (512, "Assets.xcassets/AppIcon.appiconset/icon_256x256@2x.png"),
    (512, "Assets.xcassets/AppIcon.appiconset/icon_512x512.png"),
    (1024, "Assets.xcassets/AppIcon.appiconset/icon_512x512@2x.png")
]

for (size, path) in sizes {
    createAppIcon(size: CGSize(width: size, height: size), outputPath: path)
}

print("\nApp icons generated successfully!")
