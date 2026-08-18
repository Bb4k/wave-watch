//
//  LogView.swift
//  wave Watch App
//
//  The phone's Log form doesn't survive the trip to a wrist: a 0-10 slider and
//  three rows of chips are too small to hit while a craving is happening. Same
//  four questions, one per screen instead — big type, full-width targets, and
//  the Digital Crown for intensity, which is the one input a wrist does better
//  than a touchscreen.
//

import SwiftUI

struct LogView: View {
    @EnvironmentObject private var store: WaveStore

    private enum Step: Int, CaseIterable {
        case intensity, activity, feeling, place

        var title: String {
            switch self {
            case .intensity: "How strong?"
            case .activity: "What were you doing?"
            case .feeling: "What were you feeling?"
            case .place: "Where were you?"
            }
        }
    }

    @State private var step: Step = .intensity
    @State private var intensity: Double = 7
    @State private var activity: String?
    @State private var feelings: Set<String> = []
    @State private var place: String?
    /// Set once the craving is saved: the flow stops and asks before it either
    /// opens the exercises or hands the user back to Home.
    @State private var saved = false
    @FocusState private var crownFocused: Bool

    private var level: Int { Int(intensity.rounded()) }

    var body: some View {
        Group {
            if saved {
                activityPrompt
            } else {
                form
            }
        }
        .waveScreen()
        // Each step replaces the last in place, so the flow reads as one screen
        // moving forward rather than four screens stacking up.
        .animation(.easeInOut(duration: 0.22), value: step)
        .animation(.easeInOut(duration: 0.22), value: saved)
        // The wizard owns the whole screen: no navigation bar, so no close
        // button in the corner competing with the step's own way out, and the
        // ~28 pt that chrome costs goes back to the question.
        .toolbar(.hidden)
        .onAppear {
            #if DEBUG
            simulateSubmitIfRequested()
            #endif
        }
    }

    private var form: some View {
        ScrollViewReader { proxy in
            ScrollView {
                VStack(alignment: .leading, spacing: 7) {
                    ScreenTitle(
                        text: step.title,
                        step: "\(step.rawValue + 1) of \(Step.allCases.count)"
                    )
                    .id("top")

                    switch step {
                    case .intensity: intensityStep
                    case .activity: activityStep
                    case .feeling: feelingStep
                    case .place: placeStep
                    }

                    PillButton(
                        title: step == .place ? "Save" : "Next",
                        symbol: step == .place ? "checkmark" : nil,
                        style: .orange,
                        action: advance
                    )
                    .padding(.top, 2)

                    // The way out, in the flow rather than in a corner: a
                    // labelled button under the one that goes forward, so
                    // leaving is a choice you read rather than an X you find.
                    PillButton(title: "Back to home", style: .quiet) {
                        Haptics.tap()
                        goHome()
                    }
                }
                .padding(.horizontal, Metrics.screenPadding)
                .padding(.top, 22)
                .padding(.bottom, 8)
            }
            // watchOS hands a modal ~60 pt of top inset. Almost all of it is
            // dead space here, so it is taken back and spent again by hand: 22
            // pt, which is what the step's own title needs to clear the status
            // time rather than run under it.
            .ignoresSafeArea(.container, edges: .top)
            // A long list of choices can leave the next step scrolled halfway
            // down. Every step starts at its question.
            .onChange(of: step) { _, _ in
                proxy.scrollTo("top", anchor: .top)
            }
        }
    }

    // MARK: Saved

    /// Logging is the whole ask; an exercise is an offer on top of it. So this
    /// asks rather than assuming, and "not now" is a real answer that returns
    /// the user to Home.
    private var activityPrompt: some View {
        ScrollView {
            // Tighter than the other otter screens: the question and both
            // answers have to be on screen together, or "not now" reads as
            // unavailable rather than as a choice.
            VStack(spacing: 6) {
                OtterAnimationView(clip: .calm, size: 48)
                    .overlay(Circle().stroke(Palette.card, lineWidth: 2))

                Text("Craving logged.")
                    .font(WaveFont.title)
                    .foregroundStyle(Palette.ink)

                Text("Want to do an activity?")
                    .font(WaveFont.body)
                    .foregroundStyle(Palette.inkSoft)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)

                PillButton(title: "Yes", symbol: "water.waves", style: .orange) {
                    Haptics.tap()
                    // Swaps the flow's content rather than opening anything on
                    // top of it, so the activity can end straight on Home.
                    store.open(.activity(afterLogging: true))
                }

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

    // MARK: Steps

    /// Two ways to set it, because the crown alone was one way too few: it only
    /// works while this card holds focus, and focus is quietly lost to the
    /// scroll view the moment anything else on the screen is touched — at which
    /// point the slider looks live and does nothing. Dragging the track is the
    /// input that always works; the crown stays for the times it has focus,
    /// since a wrist is better at turning than at aiming.
    private var intensityStep: some View {
        VStack(spacing: 5) {
            Text("\(level)")
                .font(WaveFont.hero)
                .foregroundStyle(Palette.orange)
            Text(Choices.intensityWord(level))
                .font(WaveFont.headline)
                .foregroundStyle(Palette.orange)

            slider

            Text("Drag or turn the crown")
                .font(WaveFont.caption)
                .foregroundStyle(Palette.muted)
        }
        .frame(maxWidth: .infinity)
        .waveCard(padding: 10)
        .focusable()
        .focused($crownFocused)
        .digitalCrownRotation(
            $intensity,
            from: 0, through: 10, by: 1,
            sensitivity: .medium,
            isContinuous: false,
            isHapticFeedbackEnabled: true
        )
        // Taking focus in `onAppear` runs before the card is in the hierarchy
        // and is dropped; a turn of the run loop later it holds.
        .task {
            try? await Task.sleep(for: .milliseconds(120))
            crownFocused = true
        }
    }

    private var slider: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let knob: CGFloat = 20
            // The knob's centre travels the width less its own diameter, so it
            // sits inside the track at both ends rather than hanging off them.
            let travel = max(w - knob, 1)
            let x = knob / 2 + travel * CGFloat(intensity / 10)

            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Palette.border)
                    .frame(height: 8)
                Capsule()
                    .fill(Palette.orange)
                    .frame(width: x, height: 8)
                Circle()
                    .fill(Palette.white)
                    .frame(width: knob, height: knob)
                    .overlay(Circle().stroke(Palette.orange, lineWidth: 3))
                    .position(x: x, y: 14)
            }
            .frame(width: w, height: 28)
            // The whole band is the target, not just the 8 pt track.
            .contentShape(Rectangle())
            // High priority, or the enclosing scroll view claims the drag and
            // the knob never moves — which is exactly how this looked before.
            .highPriorityGesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        // `minimumDistance: 0` means a plain tap lands here too
                        // and jumps the value, which is the fastest way to set
                        // a 0-10 scale on a screen this size.
                        let raw = (value.location.x - knob / 2) / travel * 10
                        let next = min(max(raw.rounded(), 0), 10)
                        guard next != intensity else { return }
                        intensity = next
                        Haptics.tap()
                    }
            )
        }
        .frame(height: 28)
    }

    private var activityStep: some View {
        VStack(spacing: 6) {
            ForEach(Choices.activities, id: \.label) { item in
                ChoiceRow(
                    label: item.label,
                    symbol: item.symbol,
                    selected: activity == item.label
                ) {
                    activity = item.label
                    Haptics.tap()
                }
            }
        }
    }

    private var feelingStep: some View {
        VStack(spacing: 6) {
            ForEach(Choices.feelings, id: \.self) { label in
                ChoiceRow(label: label, selected: feelings.contains(label)) {
                    if feelings.contains(label) {
                        feelings.remove(label)
                    } else {
                        feelings.insert(label)
                    }
                    Haptics.tap()
                }
            }
        }
    }

    private var placeStep: some View {
        VStack(spacing: 6) {
            ForEach(Choices.places, id: \.self) { label in
                ChoiceRow(label: label, selected: place == label) {
                    place = label
                    Haptics.tap()
                }
            }
        }
    }

    // MARK: Flow

    private func advance() {
        if let next = Step(rawValue: step.rawValue + 1) {
            step = next
            Haptics.tap()
        } else {
            submit()
        }
    }

    private func submit() {
        let now = Calendar.current.dateComponents([.hour, .minute], from: Date())
        store.add(
            CravingLog(
                hour: now.hour ?? 12,
                minute: now.minute ?? 0,
                intensity: level,
                activity: activity,
                feelings: Array(feelings),
                place: place
            )
        )
        Haptics.logged()
        saved = true
    }

    /// Every way out of this flow ends in the same place, in one move.
    private func goHome() {
        store.endFlow()
    }

    #if DEBUG
    /// Steps the whole flow through on a timer, so it can be exercised in a
    /// simulator that can't be tapped from outside.
    private func simulateSubmitIfRequested() {
        let args = ProcessInfo.processInfo.arguments
        // Jumps straight to the post-save prompt, which is otherwise four taps
        // in from a screen nothing can tap.
        if args.contains("-saved") { saved = true }
        guard args.contains("-simulateSubmit") else { return }
        for (i, s) in Step.allCases.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1 + Double(i) * 0.6) {
                step = s
            }
        }
    }
    #endif
}

#Preview {
    LogView().environmentObject(WaveStore())
}
