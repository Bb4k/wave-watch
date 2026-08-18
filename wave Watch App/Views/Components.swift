//
//  Components.swift
//  wave Watch App
//
//  The phone's design language — cream cards, pill buttons, chips — rebuilt at
//  wrist scale. Every tappable thing here is a full-width bar; nothing is
//  side-by-side, because two targets on a 176 pt row are two targets you miss.
//

import SwiftUI

/// The dark ink pill ("Log a craving") and the orange one ("Do an activity").
struct PillButton: View {
    enum Style { case ink, orange, quiet }

    var title: String
    var symbol: String?
    var style: Style = .ink
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 7) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 13, weight: .bold))
                }
                Text(title)
                    .font(WaveFont.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            .foregroundStyle(foreground)
            .frame(maxWidth: .infinity)
            .frame(height: Metrics.buttonHeight)
            .background(Capsule(style: .continuous).fill(background))
            .overlay(
                Capsule(style: .continuous)
                    .stroke(style == .quiet ? Palette.border : .clear, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var background: Color {
        switch style {
        case .ink: Palette.ink
        case .orange: Palette.orange
        case .quiet: Palette.card
        }
    }

    private var foreground: Color {
        style == .quiet ? Palette.inkSoft : Palette.white
    }
}

/// A full-width selectable row — the watch replacement for the phone's chips.
/// One per line, so the whole width is the target.
struct ChoiceRow: View {
    var label: String
    var symbol: String?
    var selected: Bool
    var tint: Color = Palette.orange
    var action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 9) {
                if let symbol {
                    Image(systemName: symbol)
                        .font(.system(size: 14))
                        .foregroundStyle(selected ? tint : Palette.inkSoft)
                        .frame(width: 18)
                }
                Text(label)
                    .font(WaveFont.body)
                    .foregroundStyle(selected ? tint : Palette.inkSoft)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                if selected {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(tint)
                }
            }
            .padding(.horizontal, 12)
            .frame(maxWidth: .infinity, minHeight: Metrics.rowHeight)
            .background(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .fill(selected ? tint.opacity(0.12) : Palette.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                    .stroke(selected ? tint : Palette.border, lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

/// A screen's question, in the display voice.
struct ScreenTitle: View {
    var text: String
    var step: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 2) {
            // The caption line is kept even when there's nothing to say in it.
            // Every screen then starts its question at the same height, which
            // is the height that clears the status time — a screen without a
            // step counter would otherwise run its title under the clock.
            Text(step ?? " ")
                .font(WaveFont.caption)
                .foregroundStyle(Palette.muted)
            Text(text)
                .font(WaveFont.title)
                .foregroundStyle(Palette.ink)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

/// The craving-pattern heatmap — the one piece of Insights that stayed on the
/// watch. Everything else (triggers, locations, risk) is a phone job.
struct CravingPatternCard: View {
    var data: PeriodData
    var replay: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Craving pattern")
                .font(WaveFont.headline)
                .foregroundStyle(Palette.ink)

            ChartWipe(delay: Entrance.chartDelay(5), replay: replay) {
                VStack(spacing: 4) {
                    ForEach(data.heatRows) { row in
                        HStack(spacing: 4) {
                            Text(row.label)
                                .font(WaveFont.caption)
                                .foregroundStyle(Palette.muted)
                                .lineLimit(1)
                                .frame(width: 34, alignment: .leading)
                            ForEach(Array(row.cells.enumerated()), id: \.offset) { _, intensity in
                                RoundedRectangle(cornerRadius: 4, style: .continuous)
                                    .fill(PeriodData.heatColors[intensity])
                                    .aspectRatio(1, contentMode: .fit)
                                    .frame(maxWidth: .infinity)
                            }
                        }
                    }
                    HStack(spacing: 4) {
                        Color.clear.frame(width: 34, height: 1)
                        ForEach(Array(PeriodData.dayLetters.enumerated()), id: \.offset) { _, day in
                            Text(day)
                                .font(WaveFont.caption)
                                .foregroundStyle(Palette.muted)
                                .frame(maxWidth: .infinity)
                        }
                    }
                }
            }

            HStack(spacing: 6) {
                Text("Low")
                    .font(WaveFont.caption)
                    .foregroundStyle(Palette.muted)
                LinearGradient(
                    colors: [Color(hex: 0xDAEBD8), Color(hex: 0xF5D79E), Color(hex: 0xEE7A3C)],
                    startPoint: .leading, endPoint: .trailing
                )
                .frame(height: 6)
                .clipShape(Capsule())
                Text("High")
                    .font(WaveFont.caption)
                    .foregroundStyle(Palette.muted)
            }
        }
        .waveCard()
    }
}
