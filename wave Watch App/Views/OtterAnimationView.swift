//
//  OtterAnimationView.swift
//  wave Watch App
//
//  The phone plays the otter clips with expo-video. watchOS has no SwiftUI
//  VideoPlayer, so the same three mp4s are extracted to JPEG frames at build
//  time and cycled here — which also lets the otter sit inside the wave clock's
//  dial, loop seamlessly, and cost nothing when off screen.
//

import Combine
import SwiftUI
import UIKit

/// The same three clips the phone's OtterVideo uses.
enum OtterClip: String {
    case calm, paddle, surf

    var prefix: String { "otter_\(rawValue)" }

    /// Frames per clip, extracted from the source artwork.
    static let frameCount = 48
}

/// Loads one clip's frames into memory, and only one at a time.
@MainActor
final class FrameLoader: ObservableObject {
    @Published private(set) var frames: [UIImage] = []

    private var currentPrefix: String?
    private var task: Task<Void, Never>?

    func load(_ clip: OtterClip) {
        guard clip.prefix != currentPrefix else { return }
        currentPrefix = clip.prefix
        task?.cancel()

        task = Task { [weak self] in
            let loaded = await Self.decode(prefix: clip.prefix, count: OtterClip.frameCount)
            guard !Task.isCancelled else { return }
            self?.frames = loaded
        }
    }

    func unload() {
        task?.cancel()
        currentPrefix = nil
        frames = []
    }

    /// Decoding off the main actor keeps the first frame from hitching the UI.
    private nonisolated static func decode(prefix: String, count: Int) async -> [UIImage] {
        await Task.detached(priority: .userInitiated) { () -> [UIImage] in
            var out: [UIImage] = []
            out.reserveCapacity(count)
            for i in 0..<count {
                if Task.isCancelled { return [] }
                let name = String(format: "%@_%02d", prefix, i)
                guard let url = Bundle.main.url(forResource: name, withExtension: "jpg"),
                      let data = try? Data(contentsOf: url),
                      let image = UIImage(data: data) else { continue }
                out.append(forceDecoded(image))
            }
            return out
        }.value
    }

    /// Decode now rather than on the first draw, so playback doesn't hitch.
    /// (`UIImage.preparingForDisplay()` is unavailable on watchOS.)
    private nonisolated static func forceDecoded(_ image: UIImage) -> UIImage {
        guard let cg = image.cgImage else { return image }
        guard let ctx = CGContext(
            data: nil,
            width: cg.width,
            height: cg.height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: CGColorSpaceCreateDeviceRGB(),
            // The frames are opaque, so skip the alpha channel.
            bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue
        ) else { return image }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: cg.width, height: cg.height))
        guard let decoded = ctx.makeImage() else { return image }
        return UIImage(cgImage: decoded, scale: image.scale, orientation: image.imageOrientation)
    }
}

/// The circular otter medallion, matching the phone's OtterVideo.
struct OtterAnimationView: View {
    var clip: OtterClip
    var size: CGFloat

    @StateObject private var loader = FrameLoader()

    static let fps: Double = 12

    var body: some View {
        Group {
            if loader.frames.isEmpty {
                // Warm placeholder until the frames finish decoding.
                Circle().fill(Palette.orangeSoft)
            } else {
                TimelineView(.animation(minimumInterval: 1.0 / Self.fps)) { context in
                    let t = context.date.timeIntervalSinceReferenceDate
                    let i = Self.frameIndex(at: t, count: loader.frames.count)
                    Image(uiImage: loader.frames[i])
                        .resizable()
                        .scaledToFill()
                }
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .onAppear { loader.load(clip) }
        .onDisappear { loader.unload() }
        .onChange(of: clip) { _, new in loader.load(new) }
    }

    /// Ping-pong: forward through the clip, then back. The turnaround makes the
    /// loop seamless without needing the source to be a perfect cycle.
    static func frameIndex(at time: TimeInterval, count: Int) -> Int {
        guard count > 1 else { return 0 }
        let cycle = count * 2 - 2
        let i = Int(time * fps) % cycle
        return i < count ? i : cycle - i
    }
}
