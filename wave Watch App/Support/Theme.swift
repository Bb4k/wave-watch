//
//  Theme.swift
//  wave Watch App
//
//  Design tokens ported 1:1 from the phone app's src/constants/theme.ts, so the
//  watch and the phone read as one product. The palette is deliberately light —
//  Wave is a warm cream app, not a dark one, on every screen it runs on.
//

import SwiftUI
import WatchKit

enum Palette {
    static let bg = Color(hex: 0xFAF6EF)
    static let card = Color(hex: 0xFFFDF9)
    static let cardAlt = Color(hex: 0xF4EEE3)
    static let border = Color(hex: 0xEFE7D9)
    static let ink = Color(hex: 0x1F1A13)
    static let inkSoft = Color(hex: 0x4A4238)
    static let muted = Color(hex: 0x988E7F)
    static let faint = Color(hex: 0xCBC2B3)
    static let white = Color.white
    static let orange = Color(hex: 0xF2600C)
    static let orangeSoft = Color(hex: 0xFDE8D9)
    static let green = Color(hex: 0x3E9B63)
    static let greenSoft = Color(hex: 0xE4F1E4)
    static let blue = Color(hex: 0x3D7BD9)
    static let blueSoft = Color(hex: 0xE4EDFA)
    static let purple = Color(hex: 0xA183DE)
    static let purpleSoft = Color(hex: 0xEFE9FA)
    static let red = Color(hex: 0xE25234)
    static let redSoft = Color(hex: 0xFBE6DF)

    /// Top tint of the background fade — a whisper of orangeSoft in the cream.
    static let fadeTop = Color(hex: 0xFBEEDD)
}

enum Radius {
    static let card: CGFloat = 14
    static let small: CGFloat = 10
    static let pill: CGFloat = 999
}

enum Metrics {
    /// Tighter than the phone's 20 — a 41mm screen is 176 pt wide.
    static let screenPadding: CGFloat = 6
    static let cardGap: CGFloat = 8

    static let screen = WKInterfaceDevice.current().screenBounds.size

    /// Home's first screenful is the title and the dial, and nothing else — the
    /// two have to land inside the screen together, without a scroll to finish
    /// the circle. So the dial is the smaller of the full width and whatever is
    /// left under the title, measured rather than guessed so it holds from 40mm
    /// up to Ultra.
    /// What Home spends above the dial: the top inset plus the wave-level
    /// title and its gap.
    static let titleBlock: CGFloat = 40
    static let clockSize: CGFloat = min(screen.width - 4, screen.height - titleBlock - 4)

    /// The app mark on the splash — a third of the screen, the size a launch
    /// mark reads at without becoming the whole screen.
    static let splashIcon: CGFloat = min(76, screen.width * 0.42)

    /// Every primary action is a full-width bar this tall. Enough to hit
    /// reliably mid-craving, but no taller — two of these plus a card is what a
    /// screen can hold before the user has to scroll to find the next thing.
    static let buttonHeight: CGFloat = 42
    /// Secondary choices (chips, list rows). The full width is the target, so
    /// the bar itself doesn't need the whole 44 pt to be easy to hit.
    static let rowHeight: CGFloat = 36

    /// The otter medallion outside the wave clock — alert, done, handoff. Small
    /// enough that the copy and the actions under it are on screen with it.
    static let otterSize: CGFloat = 52
}

/// The phone pairs Space Grotesk (headings, hero numbers) with Inter (body).
/// Neither ships with watchOS, so this maps that two-voice hierarchy onto SF:
/// rounded for the display voice, default for text. At watch sizes the rounded
/// face carries the same warmth Space Grotesk gives the phone.
///
/// The named sizes below are the whole scale. They are larger than a direct
/// port of the phone would give — a wrist is read at arm's length in a glance,
/// often one-handed — but no larger than that, because every point spent on
/// type is a point of scrolling paid for later. Nothing is smaller than
/// `caption`.
enum WaveFont {
    /// The one big thing on a screen: an intensity value, "28 min".
    static let hero = Font.system(size: 32, weight: .heavy, design: .rounded)
    /// A screen's question or name.
    static let title = Font.system(size: 17, weight: .bold, design: .rounded)
    /// Card headings and button labels.
    static let headline = Font.system(size: 15, weight: .semibold, design: .rounded)
    /// Running text.
    static let body = Font.system(size: 13, weight: .medium)
    /// Supporting text — the smallest size that still reads at a glance.
    static let caption = Font.system(size: 11, weight: .medium)

    static func heading(_ size: CGFloat) -> Font {
        .system(size: size, weight: .bold, design: .rounded)
    }

    static func number(_ size: CGFloat) -> Font {
        .system(size: size, weight: .heavy, design: .rounded)
    }

    static func body(_ size: CGFloat, weight: Font.Weight = .medium) -> Font {
        .system(size: size, weight: weight)
    }
}

/// The full-bleed warm fade every screen sits on: tinted at the top, settling
/// into the base cream, sand at the bottom. Mirrors the phone's ScreenFade.
struct ScreenFade: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Palette.fadeTop, location: 0),
                .init(color: Palette.bg, location: 0.45),
                .init(color: Palette.cardAlt, location: 1),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

extension Color {
    /// 0xRRGGBB literal, so the tokens above stay copy-pasteable from the phone.
    init(hex: UInt32) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension View {
    /// Cream card with the hairline border used everywhere on the phone.
    func waveCard(padding: CGFloat = 10) -> some View {
        self
            .padding(padding)
            .frame(maxWidth: .infinity)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(Palette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .stroke(Palette.border, lineWidth: 1)
            )
    }

    /// Paints the cream fade behind a page and forces dark-on-light content.
    func waveScreen() -> some View {
        self
            .background(ScreenFade())
            .foregroundStyle(Palette.ink)
    }
}
