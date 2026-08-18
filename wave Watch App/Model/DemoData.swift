//
//  DemoData.swift
//  wave Watch App
//
//  Every number here is lifted from the phone app's hardcoded demo data
//  (wave-clock.tsx and insights.tsx), so the two screens agree. This is the
//  single seam: swapping in real signals means changing only this file.
//

import SwiftUI

// MARK: - Wave level

/// "Your Wave" — the one line at the top of Home.
enum WaveLevel: String, CaseIterable {
    case low = "Low"
    case medium = "Medium"
    case high = "High"

    var color: Color {
        switch self {
        case .low: Palette.green
        case .medium: Palette.orange
        case .high: Palette.red
        }
    }

    /// Which otter clip plays in the middle of the dial.
    var clip: OtterClip {
        switch self {
        case .low: .calm
        case .medium: .paddle
        case .high: .surf
        }
    }
}

// MARK: - The 24h dial

/// The four things the day-ring can show, with the phone's exact colors.
enum DayCategory {
    case sleep, craving, handled, workout

    var color: Color {
        switch self {
        case .sleep: Palette.blue
        case .craving: Palette.orange
        case .handled: Palette.green
        case .workout: Palette.purple
        }
    }

    var label: String {
        switch self {
        case .sleep: "Sleep"
        case .craving: "Craving"
        case .handled: "Handled"
        case .workout: "Workout"
        }
    }
}

/// A run of consecutive segments drawn as one capsule.
struct SegmentRun: Identifiable {
    let start: Double
    let length: Double
    let category: DayCategory

    var id: String { "\(start)-\(category)" }
}

enum DayRing {
    static let segmentCount = 56

    /// 12:00 top, 06:00 right, 00:00 bottom, 18:00 left. Same demo day as the
    /// phone: sleep through the night, craving clusters near the top.
    static let runs: [SegmentRun] = [
        SegmentRun(start: 2, length: 6, category: .craving),
        SegmentRun(start: 8, length: 3, category: .handled),
        SegmentRun(start: 11, length: 2, category: .workout),
        SegmentRun(start: 13, length: 2, category: .workout),
        SegmentRun(start: 15, length: 2, category: .handled),
        SegmentRun(start: 17, length: 2, category: .craving),
        SegmentRun(start: 19, length: 3, category: .handled),
        SegmentRun(start: 23, length: 4, category: .sleep),
        SegmentRun(start: 29, length: 12, category: .sleep),
        SegmentRun(start: 41, length: 1, category: .sleep),
        SegmentRun(start: 42, length: 5, category: .sleep),
        SegmentRun(start: 48, length: 1, category: .handled),
        SegmentRun(start: 49, length: 2, category: .craving),
        SegmentRun(start: 51, length: 3, category: .handled),
    ]

    /// Uncategorised slots, drawn as soft neutral bezel dashes.
    static let neutral = [0, 1, 22, 27, 28, 47, 54, 55]

    /// Fractional segment position of a 24h time (12:00 top, clockwise).
    static func segment(hour: Int, minute: Int) -> Double {
        let clockwise = (Double(hour) + Double(minute) / 60 - 12)
            .truncatingRemainder(dividingBy: 24)
        let wrapped = clockwise < 0 ? clockwise + 24 : clockwise
        return wrapped * (Double(segmentCount) / 24)
    }
}

// MARK: - Today

enum Today {
    static let baseCravings = 1
    static let baseUrges = 2
    static let baseHandled = 3
    static let nextWave = "1 min"
}

// MARK: - Insights

enum Period: String, CaseIterable, Identifiable {
    case thisWeek = "This Week"
    case lastWeek = "Last Week"
    case thisMonth = "This Month"

    var id: String { rawValue }

    /// Short enough for a 176 pt-wide screen.
    var shortName: String {
        switch self {
        case .thisWeek: "Week"
        case .lastWeek: "Last wk"
        case .thisMonth: "Month"
        }
    }
}

struct BarStat: Identifiable {
    let label: String
    let pct: Int
    var id: String { label }
}

struct LocationStat: Identifiable {
    let symbol: String
    let label: String
    let pct: String
    var id: String { label }
}

struct HeatRow: Identifiable {
    let label: String
    /// 7 intensities, 0...4 — indexes into `PeriodData.heatColors`.
    let cells: [Int]
    var id: String { label }
}

struct RiskTrend {
    let text: String
    let isUp: Bool

    var color: Color { isUp ? Palette.red : Palette.green }
    var symbol: String { isUp ? "arrow.up" : "arrow.down" }
}

struct PeriodData {
    let handled: String
    let streak: Int
    let heatRows: [HeatRow]
    let triggers: [BarStat]
    let activities: [BarStat]
    let locations: [LocationStat]
    /// 13 normalized (0-1) y positions for the risk line.
    let riskPoints: [Double]
    let riskAvgPct: Int
    let riskTrend: RiskTrend

    static let heatColors: [Color] = [
        Color(hex: 0xF2EDE2), Color(hex: 0xDAEBD8), Color(hex: 0xA9D3A8),
        Color(hex: 0xF5B47C), Color(hex: 0xEE7A3C),
    ]

    static let dayLetters = ["M", "T", "W", "T", "F", "S", "S"]

    static let all: [Period: PeriodData] = [
        .thisWeek: PeriodData(
            handled: "10 / 14",
            streak: 3,
            heatRows: [
                HeatRow(label: "6 AM", cells: [3, 3, 1, 1, 2, 1, 2]),
                HeatRow(label: "12 PM", cells: [4, 4, 3, 1, 2, 3, 2]),
                HeatRow(label: "6 PM", cells: [3, 2, 0, 2, 1, 4, 3]),
            ],
            triggers: [
                BarStat(label: "Stress", pct: 48), BarStat(label: "Boredom", pct: 32),
                BarStat(label: "Being alone", pct: 22), BarStat(label: "Tired", pct: 18),
            ],
            activities: [
                BarStat(label: "Work", pct: 45), BarStat(label: "Study", pct: 30),
                BarStat(label: "Other", pct: 25),
            ],
            locations: [
                LocationStat(symbol: "building.2", label: "Office", pct: "42%"),
                LocationStat(symbol: "moon", label: "Bedroom", pct: "28%"),
                LocationStat(symbol: "cup.and.saucer", label: "Kitchen", pct: "18%"),
                LocationStat(symbol: "ellipsis", label: "Other", pct: "12%"),
            ],
            riskPoints: [0.6, 0.68, 0.52, 0.38, 0.5, 0.62, 0.44, 0.3, 0.42, 0.38, 0.6, 0.34, 0.48],
            riskAvgPct: 23,
            riskTrend: RiskTrend(text: "16% vs last week", isUp: false)
        ),
        .lastWeek: PeriodData(
            handled: "7 / 15",
            streak: 1,
            heatRows: [
                HeatRow(label: "6 AM", cells: [4, 3, 2, 3, 3, 2, 4]),
                HeatRow(label: "12 PM", cells: [4, 4, 4, 3, 3, 4, 4]),
                HeatRow(label: "6 PM", cells: [4, 3, 3, 2, 4, 4, 3]),
            ],
            triggers: [
                BarStat(label: "Stress", pct: 61), BarStat(label: "Tired", pct: 34),
                BarStat(label: "Boredom", pct: 29), BarStat(label: "Being alone", pct: 20),
            ],
            activities: [
                BarStat(label: "Work", pct: 52), BarStat(label: "Other", pct: 26),
                BarStat(label: "Study", pct: 22),
            ],
            locations: [
                LocationStat(symbol: "building.2", label: "Office", pct: "47%"),
                LocationStat(symbol: "moon", label: "Bedroom", pct: "24%"),
                LocationStat(symbol: "cup.and.saucer", label: "Kitchen", pct: "15%"),
                LocationStat(symbol: "ellipsis", label: "Other", pct: "14%"),
            ],
            riskPoints: [0.38, 0.3, 0.42, 0.5, 0.36, 0.26, 0.44, 0.55, 0.4, 0.48, 0.3, 0.52, 0.34],
            riskAvgPct: 41,
            riskTrend: RiskTrend(text: "21% vs prior week", isUp: true)
        ),
        .thisMonth: PeriodData(
            handled: "38 / 52",
            streak: 6,
            heatRows: [
                HeatRow(label: "6 AM", cells: [3, 3, 2, 2, 2, 2, 3]),
                HeatRow(label: "12 PM", cells: [3, 4, 3, 2, 3, 3, 2]),
                HeatRow(label: "6 PM", cells: [3, 2, 1, 2, 2, 3, 3]),
            ],
            triggers: [
                BarStat(label: "Stress", pct: 51), BarStat(label: "Boredom", pct: 29),
                BarStat(label: "Being alone", pct: 24), BarStat(label: "Tired", pct: 19),
            ],
            activities: [
                BarStat(label: "Work", pct: 47), BarStat(label: "Study", pct: 28),
                BarStat(label: "Other", pct: 25),
            ],
            locations: [
                LocationStat(symbol: "building.2", label: "Office", pct: "44%"),
                LocationStat(symbol: "moon", label: "Bedroom", pct: "26%"),
                LocationStat(symbol: "cup.and.saucer", label: "Kitchen", pct: "17%"),
                LocationStat(symbol: "ellipsis", label: "Other", pct: "13%"),
            ],
            riskPoints: [0.55, 0.6, 0.5, 0.45, 0.52, 0.58, 0.48, 0.4, 0.5, 0.46, 0.56, 0.42, 0.5],
            riskAvgPct: 27,
            riskTrend: RiskTrend(text: "9% vs last month", isUp: false)
        ),
    ]
}
