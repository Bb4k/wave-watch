//
//  WaveClockView.swift
//  wave Watch App
//
//  The signature element of the phone's Home screen: a 24h dial (12:00 top,
//  06:00 right, 00:00 bottom, 18:00 left) where the day is drawn as coloured
//  capsules around the otter. Ported from src/components/wave-clock.tsx.
//
//  The four quarter-hour labels sit in a margin outside the ring, as on the
//  phone. That margin is what bounds the dial. The two side labels are turned
//  on their side so the margin only has to hold their cap height rather than
//  the full width of "18:00" — the ring keeps the ~10 pt that buys.
//

import SwiftUI

struct WaveClockView: View {
    var size: CGFloat
    var clip: OtterClip
    /// Cravings logged this session, drawn as extra orange capsules.
    var logs: [CravingLog] = []
    /// Bumped to replay the entrance, as on the phone.
    var replay: Int = 0
    var delay: Double = 0

    /// Sweep progress, 0...1 — drives both the ring reveal and the labels.
    /// Starts fully revealed; only a page change winds it back.
    @State private var sweep: Double = 1

    /// Everything below is derived from the 130 pt reference layout. `size` is
    /// the whole footprint including the hour labels, which sit in a margin
    /// outside the ring exactly as they do on the phone.
    private var s: CGFloat { size / 130 }
    private var centre: CGFloat { size / 2 }
    /// The band the hour labels live in. With the side labels rotated it only
    /// has to clear a line of type on edge, not the width of "18:00".
    private var labelMargin: CGFloat { 10 * s }
    /// Thin segments: the ring is a reading of the day, not a gauge, and the
    /// slimmer stroke leaves the hour labels room to breathe.
    private var strokeW: CGFloat { 6 * s }
    private var ringR: CGFloat { centre - labelMargin - strokeW / 2 }
    private var medallion: CGFloat { 2 * (ringR - strokeW / 2 - 3 * s) }
    private var labelFont: CGFloat { max(8, 5 * s) }

    private static let segDeg = 360.0 / Double(DayRing.segmentCount)

    var body: some View {
        ZStack {
            // Neutral bezel dashes for the uncategorised slots.
            ForEach(DayRing.neutral, id: \.self) { i in
                capsule(from: Double(i), to: Double(i) + 1)
                    .stroke(
                        i.isMultiple(of: 2) ? Palette.cardAlt : Palette.border,
                        style: StrokeStyle(lineWidth: strokeW, lineCap: .round)
                    )
            }

            // The day itself.
            ForEach(DayRing.runs) { run in
                capsule(from: run.start, to: run.start + run.length)
                    .stroke(
                        run.category.color,
                        style: StrokeStyle(lineWidth: strokeW, lineCap: .round)
                    )
            }

            // Session logs, drawn last so they read on top of the demo day.
            ForEach(logs) { log in
                let mid = DayRing.segment(hour: log.hour, minute: log.minute)
                capsule(from: mid - 1, to: mid + 1)
                    .stroke(
                        DayCategory.craving.color,
                        style: StrokeStyle(lineWidth: strokeW, lineCap: .round)
                    )
            }

        }
        // The ring is revealed by a clockwise sweep from 6 o'clock, the way the
        // phone's RadialReveal wipes it in.
        .mask(SweepMask(t: sweep))
        // The otter pops into place while the ring sweeps around it.
        .overlay {
            PopIn(delay: delay + 0.2, replay: replay) {
                OtterAnimationView(clip: clip, size: medallion)
                    .overlay(Circle().stroke(Palette.card, lineWidth: 2 * s))
            }
        }
        .frame(width: size, height: size)
        // The four quarter-hours, in the phone's positions. Anchored to the
        // frame's edges rather than positioned by hand, so they can't clip off
        // the screen at any watch size. Each appears as the sweep passes it.
        .overlay(alignment: .top) { hourLabel("12:00", at: 0.5) }
        .overlay(alignment: .trailing) { hourLabel("06:00", at: 0.75, turned: 90) }
        .overlay(alignment: .bottom) { hourLabel("00:00", at: 0.98) }
        .overlay(alignment: .leading) { hourLabel("18:00", at: 0.25, turned: -90) }
        .onChange(of: replay) { _, _ in
            sweep = 0
            withAnimation(.easeOut(duration: Entrance.revealDuration).delay(delay)) {
                sweep = 1
            }
        }
    }

    /// Fades in as the sweep crosses this label's angle. Driven straight off
    /// `sweep` rather than given its own animation, so the labels vanish with
    /// the ring on a replay instead of lingering over an empty dial.
    ///
    /// `turned` rotates the two side labels onto their edge. Rotation doesn't
    /// change a view's layout size, so the frame afterwards re-states the
    /// footprint the turned text actually occupies — the label's cap height,
    /// which is what lets `labelMargin` be as narrow as it is.
    private func hourLabel(_ text: String, at threshold: Double, turned: Double = 0) -> some View {
        Text(text)
            .font(.system(size: labelFont, weight: .semibold))
            .foregroundStyle(Palette.muted)
            .fixedSize()
            .opacity(min(max((sweep - threshold) / 0.06, 0), 1))
            .rotationEffect(.degrees(turned))
            .frame(width: turned == 0 ? nil : labelMargin)
    }

    /// One capsule spanning `from`...`to` in fractional segment units.
    private func capsule(from: Double, to: Double) -> Path {
        // Angular padding at both ends, so round caps leave a small gap.
        let padDeg = Double((strokeW / 2 + 2 * s) / ringR) * 180 / .pi
        var a0 = from * Self.segDeg + padDeg
        var a1 = to * Self.segDeg - padDeg

        // A single-segment run can pad itself out of existence — draw a dot.
        if a1 - a0 < 0.6 {
            let mid = (from + to) * Self.segDeg / 2
            a0 = mid - 0.3
            a1 = mid + 0.3
        }

        var path = Path()
        path.addArc(
            center: CGPoint(x: centre, y: centre),
            radius: ringR,
            // Screen angles run from 3 o'clock; the dial runs from 12 o'clock.
            startAngle: .degrees(a0 - 90),
            endAngle: .degrees(a1 - 90),
            clockwise: false
        )
        return path
    }
}

/// The colour key under the dial.
struct WaveClockLegend: View {
    private static let rows: [[DayCategory]] = [[.sleep, .craving], [.handled, .workout]]

    /// Each entry is given the same width, so the two columns line up down the
    /// rows. Sized to the longest label ("Workout") rather than to the screen —
    /// stretching the columns to the full width pushes the pair apart and
    /// leaves the block reading as two lists instead of one key.
    private static let column: CGFloat = 58

    var body: some View {
        // Two rows of two. One row can only hold all four at ~8 pt, which is
        // below what a wrist can read — the pairs buy the type back.
        VStack(spacing: 5) {
            ForEach(Array(Self.rows.enumerated()), id: \.offset) { _, row in
                HStack(spacing: 8) {
                    ForEach(Array(row.enumerated()), id: \.offset) { _, item in
                        HStack(spacing: 4) {
                            Circle()
                                .fill(item.color)
                                .frame(width: 7, height: 7)
                            Text(item.label)
                                .font(WaveFont.body(11))
                                .foregroundStyle(Palette.inkSoft)
                                .lineLimit(1)
                                .minimumScaleFactor(0.8)
                        }
                        .frame(width: Self.column, alignment: .leading)
                    }
                }
            }
        }
        // The fixed columns make the block a known width; this centres it
        // under the dial rather than letting it sit wherever the padding lands.
        .frame(maxWidth: .infinity)
    }
}
