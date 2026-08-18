//
//  Exercises.swift
//  wave Watch App
//
//  The phone's exercise pop-out, ported whole: pick the emotion that's
//  strongest, then work through the exercises for it. On the watch these are
//  read one per screen — only the game needs a phone.
//

import SwiftUI

struct Emotion: Identifiable {
    let id: String
    let label: String
    let sub: String
    let color: Color
    let soft: Color
    let symbol: String

    static let all: [Emotion] = [
        Emotion(
            id: "anger",
            label: "Anger & Frustration",
            sub: "Heat that needs somewhere to go",
            color: Palette.red,
            soft: Palette.redSoft,
            symbol: "flame.fill"
        ),
        Emotion(
            id: "boundaries",
            label: "Crossed Boundaries",
            sub: "Someone stepped over your line",
            color: Palette.purple,
            soft: Palette.purpleSoft,
            symbol: "exclamationmark.shield.fill"
        ),
        Emotion(
            id: "loneliness",
            label: "Loneliness",
            sub: "Feeling cut off or unseen",
            color: Palette.blue,
            soft: Palette.blueSoft,
            symbol: "person.fill"
        ),
    ]
}

struct Exercise: Identifiable {
    let label: String
    let symbol: String
    /// The Bubble Release game — the one thing the watch can't do.
    var isGame = false
    var sub: String?

    var id: String { label }
}

enum Exercises {
    static let byEmotion: [String: [Exercise]] = [
        "anger": [
            Exercise(
                label: "Bubble Release",
                symbol: "circle.grid.3x3.fill",
                isGame: true,
                sub: "Pop the feelings away in a quick bubble game"
            ),
            Exercise(label: "Punch it out on a pillow or mattress", symbol: "hand.raised.fill"),
            Exercise(label: "Brisk 10 minute walk", symbol: "figure.walk"),
            Exercise(label: "Journal it: write a letter or a page", symbol: "square.and.pencil"),
        ],
        "boundaries": [
            Exercise(label: "Write a letter to the person who crossed the line", symbol: "envelope"),
            Exercise(label: "Imaginary dialogue: say or write what you couldn't", symbol: "bubble.left.and.bubble.right"),
            Exercise(label: "Drink a glass of water, slowly and mindfully", symbol: "drop"),
            Exercise(label: "Step away for 5 minutes from where it happened", symbol: "door.left.hand.open"),
        ],
        "loneliness": [
            Exercise(label: "Call someone you love and trust", symbol: "phone"),
            Exercise(label: "Get around people: a park, a café, anywhere", symbol: "person.3"),
            Exercise(label: "Make something with your hands", symbol: "paintbrush"),
            Exercise(label: "Give yourself a butterfly hug", symbol: "hands.clap"),
        ],
    ]

    static func forEmotion(_ emotion: Emotion) -> [Exercise] {
        byEmotion[emotion.id] ?? []
    }
}
