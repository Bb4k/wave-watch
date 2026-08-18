//
//  ExercisesView.swift
//  wave Watch App
//
//  Exercises are the thing a watch is actually good for: you're mid-craving,
//  the phone is in a pocket, and you need one instruction you can read. So they
//  live here now — pick the feeling, then one exercise per screen in large
//  type. Only Bubble Release needs a phone, because it's a game.
//

import SwiftUI

struct ExercisesView: View {
    /// Reached straight after logging rather than from Home, which changes the
    /// opening line only.
    var afterLogging: Bool = false

    @EnvironmentObject private var store: WaveStore

    @State private var emotion: Emotion?
    @State private var index = 0
    @State private var showHandoff = false
    @State private var done = false

    var body: some View {
        Group {
            if done {
                doneScreen
            } else if let emotion {
                exerciseScreen(emotion)
            } else {
                emotionPicker
            }
        }
        .waveScreen()
        .animation(.easeInOut(duration: 0.22), value: emotion?.id)
        .animation(.easeInOut(duration: 0.22), value: index)
        // No navigation bar, so no close button in the corner: "Not now" and
        // "Done" are the ways out, and they say where they go.
        .toolbar(.hidden)
        .sheet(isPresented: $showHandoff) { PhoneHandoffView() }
        .onAppear {
            #if DEBUG
            // Jumps past the picker so a specific exercise can be screenshot.
            let args = ProcessInfo.processInfo.arguments
            if let i = args.firstIndex(of: "-emotion"), i + 1 < args.count {
                emotion = Emotion.all.first { $0.id == args[i + 1] }
            }
            if let i = args.firstIndex(of: "-exercise"), i + 1 < args.count,
               let n = Int(args[i + 1]) {
                index = n
            }
            #endif
        }
    }

    // MARK: Pick a feeling

    private var emotionPicker: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                ScreenTitle(
                    text: "What are you feeling?",
                    step: afterLogging ? "Craving logged" : nil
                )

                Text("Pick the one that's strongest right now.")
                    .font(WaveFont.caption)
                    .foregroundStyle(Palette.muted)
                    .fixedSize(horizontal: false, vertical: true)

                ForEach(Emotion.all) { item in
                    Button {
                        emotion = item
                        index = 0
                        Haptics.tap()
                    } label: {
                        // Icon and name on one line, the description under both:
                        // these names wrap to two or three lines at this width,
                        // and a side-by-side icon ends up floating beside them.
                        VStack(alignment: .leading, spacing: 4) {
                            HStack(spacing: 8) {
                                Circle()
                                    .fill(item.soft)
                                    .frame(width: 28, height: 28)
                                    .overlay(
                                        Image(systemName: item.symbol)
                                            .font(.system(size: 14))
                                            .foregroundStyle(item.color)
                                    )
                                Text(item.label)
                                    .font(WaveFont.headline)
                                    .foregroundStyle(Palette.ink)
                                    .multilineTextAlignment(.leading)
                                    .fixedSize(horizontal: false, vertical: true)
                                Spacer(minLength: 0)
                            }
                            Text(item.sub)
                                .font(WaveFont.caption)
                                .foregroundStyle(Palette.muted)
                                .multilineTextAlignment(.leading)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity)
                        .background(
                            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                                .fill(Palette.card)
                        )
                        .overlay(
                            RoundedRectangle(cornerRadius: Radius.card, style: .continuous)
                                .stroke(item.color, lineWidth: 1)
                        )
                    }
                    .buttonStyle(.plain)
                }

                // The only way out of the picker, and it says where it goes.
                PillButton(title: "Not now", style: .quiet) {
                    Haptics.tap()
                    goHome()
                }
            }
            .padding(.horizontal, Metrics.screenPadding)
            .padding(.top, 22)
            .padding(.bottom, 8)
        }
        .ignoresSafeArea(.container, edges: .top)
    }

    // MARK: One exercise per screen

    private func exerciseScreen(_ emotion: Emotion) -> some View {
        let list = Exercises.forEmotion(emotion)
        let item = list[min(index, list.count - 1)]

        return ScrollViewReader { proxy in
        ScrollView {
            VStack(alignment: .leading, spacing: 8) {
                // Both parts kept to the left: the right of this line is where
                // watchOS draws the status time, and a count sitting under the
                // clock reads as neither.
                HStack(spacing: 5) {
                    Text(emotion.label)
                        .font(WaveFont.caption)
                        .foregroundStyle(emotion.color)
                        .lineLimit(1)
                    Text("\(index + 1) of \(list.count)")
                        .font(WaveFont.caption)
                        .foregroundStyle(Palette.muted)
                        .lineLimit(1)
                    Spacer(minLength: 0)
                }
                .id("top")

                // The instruction itself, as large as it will go — this is the
                // one thing on the screen.
                VStack(alignment: .leading, spacing: 8) {
                    Circle()
                        .fill(emotion.soft)
                        .frame(width: 34, height: 34)
                        .overlay(
                            Image(systemName: item.symbol)
                                .font(.system(size: 16))
                                .foregroundStyle(emotion.color)
                        )

                    Text(item.label)
                        .font(WaveFont.title)
                        .foregroundStyle(Palette.ink)
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)

                    if item.isGame {
                        HStack(spacing: 5) {
                            Image(systemName: "play.fill")
                                .font(.system(size: 9))
                            Text("GAME")
                                .font(.system(size: 11, weight: .bold))
                        }
                        .foregroundStyle(Palette.white)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(Capsule().fill(emotion.color))
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .waveCard(padding: 10)

                if item.isGame {
                    PillButton(title: "Open on phone", symbol: "iphone", style: .orange) {
                        showHandoff = true
                    }
                } else {
                    PillButton(title: "I did this", symbol: "checkmark", style: .orange) {
                        Haptics.logged()
                        done = true
                    }
                }

                if index + 1 < list.count {
                    PillButton(title: "Show another", style: .quiet) {
                        index += 1
                        Haptics.tap()
                    }
                }

                Button("Back") {
                    self.emotion = nil
                }
                .font(WaveFont.body)
                .buttonStyle(.plain)
                .foregroundStyle(Palette.muted)
                .frame(maxWidth: .infinity, minHeight: Metrics.rowHeight)
            }
            .padding(.horizontal, Metrics.screenPadding)
            .padding(.top, 22)
            .padding(.bottom, 8)
        }
        .ignoresSafeArea(.container, edges: .top)
        // "Show another" swaps the exercise in place. Without this the next one
        // opens scrolled to wherever the last one's buttons were.
        .onChange(of: index) { _, _ in
            proxy.scrollTo("top", anchor: .top)
        }
        }
    }

    // MARK: Done

    private var doneScreen: some View {
        ScrollView {
            VStack(spacing: 8) {
                OtterAnimationView(clip: .calm, size: Metrics.otterSize)
                    .overlay(Circle().stroke(Palette.card, lineWidth: 2))

                Text("Nice one.")
                    .font(WaveFont.title)
                    .foregroundStyle(Palette.ink)

                Text("That's how a wave passes.")
                    .font(WaveFont.body)
                    .foregroundStyle(Palette.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                // Straight to Home. The flow is presented once at the root, so
                // there is no log screen underneath for this to fall back
                // through on the way — see ContentView.
                PillButton(title: "Done", style: .ink) {
                    Haptics.tap()
                    goHome()
                }
            }
            .padding(.horizontal, Metrics.screenPadding)
            .padding(.top, 22)
            .padding(.bottom, 8)
        }
        .ignoresSafeArea(.container, edges: .top)
    }

    private func goHome() {
        store.endFlow()
    }
}

#Preview {
    ExercisesView().environmentObject(WaveStore())
}
