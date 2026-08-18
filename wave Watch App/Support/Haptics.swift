//
//  Haptics.swift
//  wave Watch App
//
//  Standing in for the phone's expo-haptics. Quiet by design: Wave never taps
//  the wrist to demand attention, only to confirm something the user did.
//

import WatchKit

enum Haptics {
    /// Selecting a chip, an activity, a point on the intensity track.
    static func tap() {
        WKInterfaceDevice.current().play(.click)
    }

    /// A craving was captured, or an exercise was finished.
    static func logged() {
        WKInterfaceDevice.current().play(.success)
    }

    /// A wave may be building. A gentle double tap — noticeable enough to
    /// create a pause, never enough to feel like an alarm.
    static func waveBuilding() {
        let device = WKInterfaceDevice.current()
        device.play(.click)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.18) {
            device.play(.click)
        }
    }
}
