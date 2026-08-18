//
//  CravingLog.swift
//  wave Watch App
//
//  Mirrors the phone's LogEntry (src/state/log-store.ts) so a craving logged on
//  the wrist is the same shape as one logged in the app.
//

import Foundation

struct CravingLog: Identifiable, Hashable {
    let id: UUID
    /// 24h clock position, so the wave clock can place it.
    var hour: Int
    var minute: Int
    /// 0...10, same scale as the phone's slider.
    var intensity: Int
    var activity: String?
    var feelings: [String]
    var place: String?

    init(
        id: UUID = UUID(),
        hour: Int,
        minute: Int,
        intensity: Int,
        activity: String? = nil,
        feelings: [String] = [],
        place: String? = nil
    ) {
        self.id = id
        self.hour = hour
        self.minute = minute
        self.intensity = intensity
        self.activity = activity
        self.feelings = feelings
        self.place = place
    }
}

/// The same vocabulary the phone's Log screen offers, with SF Symbols standing
/// in for the phone's Phosphor icons.
enum Choices {
    static let activities: [(label: String, symbol: String)] = [
        ("Work", "briefcase"),
        ("Study", "book"),
        ("Social", "person.2"),
        ("Alone", "person"),
        ("Other", "ellipsis"),
    ]

    static let feelings = ["Anxious", "Bored", "Sad", "Angry", "Stressed"]
    static let places = ["Home", "Work", "School", "Out", "Other"]

    /// The phone's three-band wording for the 0-10 scale.
    static func intensityWord(_ value: Int) -> String {
        if value <= 3 { return "Mild" }
        if value <= 6 { return "Moderate" }
        return "Strong"
    }
}
