#!/usr/bin/env swift

import AppKit
import CoreGraphics
import Foundation

private enum IconAssetError: Error, CustomStringConvertible {
    case invalidArguments
    case unreadableImage(URL)
    case missingCGImage(URL)
    case contextCreationFailed
    case pngEncodingFailed(URL)

    var description: String {
        switch self {
        case .invalidArguments:
            return "Usage: generate_app_icon_assets.swift <source.png> <design-output-dir> <appiconset-dir>"
        case let .unreadableImage(url):
            return "Unable to read image at \(url.path)"
        case let .missingCGImage(url):
            return "Unable to decode a CGImage from \(url.path)"
        case .contextCreationFailed:
            return "Unable to create a bitmap context"
        case let .pngEncodingFailed(url):
            return "Unable to encode PNG at \(url.path)"
        }
    }
}

private struct RGBA {
    var red: UInt8
    var green: UInt8
    var blue: UInt8
    var alpha: UInt8
}

private let canvasSize = 1_024
private let colorSpace = CGColorSpaceCreateDeviceRGB()
private let bitmapInfo = CGBitmapInfo.byteOrder32Big.union(
    CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
)

private func resizedRGBAImage(from sourceURL: URL) throws -> [UInt8] {
    guard let image = NSImage(contentsOf: sourceURL) else {
        throw IconAssetError.unreadableImage(sourceURL)
    }

    var proposedRect = CGRect(origin: .zero, size: image.size)
    guard let cgImage = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
        throw IconAssetError.missingCGImage(sourceURL)
    }

    var pixels = [UInt8](repeating: 0, count: canvasSize * canvasSize * 4)
    guard let context = CGContext(
        data: &pixels,
        width: canvasSize,
        height: canvasSize,
        bitsPerComponent: 8,
        bytesPerRow: canvasSize * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo.rawValue
    ) else {
        throw IconAssetError.contextCreationFailed
    }

    context.interpolationQuality = .high
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: canvasSize, height: canvasSize))
    return pixels
}

private func writePNG(
    pixels: [UInt8],
    width: Int,
    height: Int,
    to outputURL: URL,
    opaque: Bool
) throws {
    try FileManager.default.createDirectory(
        at: outputURL.deletingLastPathComponent(),
        withIntermediateDirectories: true
    )

    let mutablePixels = pixels
    let alphaInfo: CGImageAlphaInfo = opaque ? .noneSkipLast : .premultipliedLast
    let outputBitmapInfo = CGBitmapInfo.byteOrder32Big.union(
        CGBitmapInfo(rawValue: alphaInfo.rawValue)
    )

    guard
        let provider = CGDataProvider(data: Data(mutablePixels) as CFData),
        let image = CGImage(
            width: width,
            height: height,
            bitsPerComponent: 8,
            bitsPerPixel: 32,
            bytesPerRow: width * 4,
            space: colorSpace,
            bitmapInfo: outputBitmapInfo,
            provider: provider,
            decode: nil,
            shouldInterpolate: true,
            intent: .defaultIntent
        )
    else {
        throw IconAssetError.contextCreationFailed
    }

    let representation = NSBitmapImageRep(cgImage: image)
    guard let data = representation.representation(using: .png, properties: [:]) else {
        throw IconAssetError.pngEncodingFailed(outputURL)
    }
    try data.write(to: outputURL, options: .atomic)
}

private func resizedPreview(from imageURL: URL, size: Int, outputURL: URL) throws {
    guard let image = NSImage(contentsOf: imageURL) else {
        throw IconAssetError.unreadableImage(imageURL)
    }
    var proposedRect = CGRect(origin: .zero, size: image.size)
    guard let cgImage = image.cgImage(forProposedRect: &proposedRect, context: nil, hints: nil) else {
        throw IconAssetError.missingCGImage(imageURL)
    }

    var pixels = [UInt8](repeating: 0, count: size * size * 4)
    guard let context = CGContext(
        data: &pixels,
        width: size,
        height: size,
        bitsPerComponent: 8,
        bytesPerRow: size * 4,
        space: colorSpace,
        bitmapInfo: bitmapInfo.rawValue
    ) else {
        throw IconAssetError.contextCreationFailed
    }
    context.interpolationQuality = .high
    context.draw(cgImage, in: CGRect(x: 0, y: 0, width: size, height: size))
    for index in stride(from: 3, to: pixels.count, by: 4) {
        pixels[index] = 255
    }
    try writePNG(pixels: pixels, width: size, height: size, to: outputURL, opaque: true)
}

private func pixel(at index: Int, in pixels: [UInt8]) -> RGBA {
    RGBA(
        red: pixels[index],
        green: pixels[index + 1],
        blue: pixels[index + 2],
        alpha: pixels[index + 3]
    )
}

private func isRedArtwork(_ pixel: RGBA) -> Bool {
    let red = Double(pixel.red)
    let green = Double(pixel.green)
    let blue = Double(pixel.blue)
    return red > 28 && green < red * 0.62 && blue < red * 0.66 && red > green + 16
}

private func isYellowArtwork(_ pixel: RGBA) -> Bool {
    let red = Double(pixel.red)
    let green = Double(pixel.green)
    let blue = Double(pixel.blue)
    return red > 48 && green > red * 0.42 && blue < red * 0.48 && blue < green * 0.58
}

private func transparentCanvas() -> [UInt8] {
    [UInt8](repeating: 0, count: canvasSize * canvasSize * 4)
}

private func copyArtworkPixel(_ source: RGBA, into destination: inout [UInt8], at index: Int) {
    let maximum = max(source.red, max(source.green, source.blue))
    let alpha = UInt8(min(255, Int(maximum) * 255 / 218))
    guard alpha > 0 else { return }

    let scale = 255.0 / Double(alpha)
    destination[index] = UInt8(min(255, Int((Double(source.red) * scale).rounded())))
    destination[index + 1] = UInt8(min(255, Int((Double(source.green) * scale).rounded())))
    destination[index + 2] = UInt8(min(255, Int((Double(source.blue) * scale).rounded())))
    destination[index + 3] = alpha
}

private func solidCanvas(red: UInt8, green: UInt8, blue: UInt8) -> [UInt8] {
    var pixels = [UInt8](repeating: 0, count: canvasSize * canvasSize * 4)
    for index in stride(from: 0, to: pixels.count, by: 4) {
        pixels[index] = red
        pixels[index + 1] = green
        pixels[index + 2] = blue
        pixels[index + 3] = 255
    }
    return pixels
}

private func createAssets(sourceURL: URL, designDirectory: URL, appIconSetDirectory: URL) throws {
    let sourcePixels = try resizedRGBAImage(from: sourceURL)

    var defaultPixels = sourcePixels
    for index in stride(from: 3, to: defaultPixels.count, by: 4) {
        defaultPixels[index] = 255
    }

    var darkPixels = solidCanvas(red: 3, green: 3, blue: 4)
    var tintedPixels = solidCanvas(red: 4, green: 4, blue: 5)
    var orbitLayer = transparentCanvas()
    var mscLayer = transparentCanvas()
    var bodyLayer = transparentCanvas()
    var transformationLayer = transparentCanvas()
    var monochromeArtwork = transparentCanvas()

    for y in 0 ..< canvasSize {
        for x in 0 ..< canvasSize {
            let index = (y * canvasSize + x) * 4
            let source = pixel(at: index, in: sourcePixels)
            let isRed = isRedArtwork(source)
            let isYellow = isYellowArtwork(source)

            if isRed || isYellow {
                darkPixels[index] = source.red
                darkPixels[index + 1] = source.green
                darkPixels[index + 2] = source.blue

                let luminance = UInt8(min(255, max(218, Int(max(source.red, max(source.green, source.blue))))))
                tintedPixels[index] = luminance
                tintedPixels[index + 1] = luminance
                tintedPixels[index + 2] = luminance

                if isRed {
                    if y < 650 {
                        copyArtworkPixel(source, into: &orbitLayer, at: index)
                    } else {
                        copyArtworkPixel(source, into: &transformationLayer, at: index)
                    }
                } else if y < 650 {
                    copyArtworkPixel(source, into: &mscLayer, at: index)
                } else {
                    copyArtworkPixel(source, into: &bodyLayer, at: index)
                }

                let maximum = max(source.red, max(source.green, source.blue))
                let alpha = UInt8(min(255, Int(maximum) * 255 / 218))
                monochromeArtwork[index] = 245
                monochromeArtwork[index + 1] = 245
                monochromeArtwork[index + 2] = 245
                monochromeArtwork[index + 3] = alpha
            }
        }
    }

    let backgroundLayer = solidCanvas(red: 5, green: 5, blue: 6)
    let defaultURL = appIconSetDirectory.appendingPathComponent("AppIcon-Default.png")
    let darkURL = appIconSetDirectory.appendingPathComponent("AppIcon-Dark.png")
    let tintedURL = appIconSetDirectory.appendingPathComponent("AppIcon-Tinted.png")

    try writePNG(pixels: defaultPixels, width: canvasSize, height: canvasSize, to: defaultURL, opaque: true)
    try writePNG(pixels: darkPixels, width: canvasSize, height: canvasSize, to: darkURL, opaque: true)
    try writePNG(pixels: tintedPixels, width: canvasSize, height: canvasSize, to: tintedURL, opaque: true)

    let layerDirectory = designDirectory.appendingPathComponent("IconComposerLayers")
    try writePNG(pixels: backgroundLayer, width: canvasSize, height: canvasSize, to: layerDirectory.appendingPathComponent("01-Background.png"), opaque: true)
    try writePNG(pixels: orbitLayer, width: canvasSize, height: canvasSize, to: layerDirectory.appendingPathComponent("02-Orbit-Red.png"), opaque: false)
    try writePNG(pixels: mscLayer, width: canvasSize, height: canvasSize, to: layerDirectory.appendingPathComponent("03-MSC-Yellow.png"), opaque: false)
    try writePNG(pixels: bodyLayer, width: canvasSize, height: canvasSize, to: layerDirectory.appendingPathComponent("04-Body-Yellow.png"), opaque: false)
    try writePNG(pixels: transformationLayer, width: canvasSize, height: canvasSize, to: layerDirectory.appendingPathComponent("05-Transformation-Red.png"), opaque: false)
    try writePNG(pixels: monochromeArtwork, width: canvasSize, height: canvasSize, to: layerDirectory.appendingPathComponent("06-Monochrome-Artwork.png"), opaque: false)

    let previewDirectory = designDirectory.appendingPathComponent("SmallSizePreviews")
    for size in [180, 120, 60, 40] {
        try resizedPreview(
            from: defaultURL,
            size: size,
            outputURL: previewDirectory.appendingPathComponent("AppIcon-Default-\(size).png")
        )
        try resizedPreview(
            from: tintedURL,
            size: size,
            outputURL: previewDirectory.appendingPathComponent("AppIcon-Tinted-\(size).png")
        )
    }
}

do {
    guard CommandLine.arguments.count == 4 else {
        throw IconAssetError.invalidArguments
    }
    let sourceURL = URL(fileURLWithPath: CommandLine.arguments[1])
    let designDirectory = URL(fileURLWithPath: CommandLine.arguments[2], isDirectory: true)
    let appIconSetDirectory = URL(fileURLWithPath: CommandLine.arguments[3], isDirectory: true)
    try createAssets(
        sourceURL: sourceURL,
        designDirectory: designDirectory,
        appIconSetDirectory: appIconSetDirectory
    )
    print("Generated App Icon assets from \(sourceURL.lastPathComponent)")
} catch {
    fputs("\(error)\n", stderr)
    exit(EXIT_FAILURE)
}
