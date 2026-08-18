//
//  WaveStore.swift
//  wave Watch App
//
//  Session-scoped state, matching the phone's log-store: the demo has no
//  backend, so a craving logged here lives until the app quits and immediately
//  shows up in the wave clock and the Today counters.
//

import Combine
import SwiftUI

/// The one flow that is open over the pages, if any. Logging and exercises are
/// steps of a single journey — log, then optionally an activity — so they share
/// one presentation rather than stacking a sheet on a sheet. That is what lets
/// "Done" at the end of an activity land on Home directly instead of unwinding
/// back through the screen that opened it.
enum WaveFlow: Equatable {
    case log
    /// `afterLogging` only changes the opening line of the exercise picker.
    case activity(afterLogging: Bool)
}

@MainActor
final class WaveStore: ObservableObject {
    /// Seeded Low to match the reference mock.
    @Published var waveLevel: WaveLevel = .low
    @Published private(set) var logs: [CravingLog] = []
    @Published var period: Period = .thisWeek

    /// Whether the wave alert is up. It is not a page the user can reach — see
    /// ContentView — because a wave that can be swiped to is not a wave: the
    /// whole point is that it arrives on its own, uninvited. So nothing sets
    /// this true but the prediction (here, the demo timer), and every way out
    /// of the alert sets it back to false.
    @Published var showAlert = false

    /// The open flow, presented once at the app's root — see `WaveFlow`.
    @Published var flow: WaveFlow?

    /// Flipped when the splash lifts. Home's entrance waits on it so the two
    /// don't play over each other.
    @Published var splashDone = false

    var todayCravings: Int { Today.baseCravings + logs.count }
    var todayUrges: Int { Today.baseUrges + logs.count }
    var todayHandled: String { "\(Today.baseHandled)/\(Today.baseHandled + logs.count)" }

    var data: PeriodData { PeriodData.all[period] ?? PeriodData.all[.thisWeek]! }

    func add(_ log: CravingLog) {
        logs.append(log)
    }

    // MARK: Flow

    func open(_ flow: WaveFlow) {
        self.flow = flow
    }

    /// Where every flow ends: the flow closes, the alert behind it is resolved,
    /// and the user is on Home — in one move. Nothing in between gets a frame
    /// on screen.
    func endFlow() {
        flow = nil
        showAlert = false
    }

    /// Leaving the alert without starting anything.
    func goHome() {
        withAnimation(.easeInOut(duration: 0.3)) { showAlert = false }
    }

    // MARK: Demo

    /// The demo has no prediction model behind it, so the wave alert is put on
    /// a timer: five seconds after the app opens from the watch menu, the same
    /// page a real notification would open slides up on its own.
    private var craving: Task<Void, Never>?

    func scheduleDemoCraving(after seconds: Double = 5) {
        guard craving == nil else { return }
        craving = Task { [weak self] in
            try? await Task.sleep(for: .seconds(seconds))
            guard !Task.isCancelled, let self, !self.showAlert, self.flow == nil else { return }
            withAnimation(.easeInOut(duration: 0.45)) { self.showAlert = true }
        }
    }

    init() {
        #if DEBUG
        applyLaunchArguments()
        #endif
    }

    #if DEBUG
    /// Lets the simulator jump straight to a screen or state for screenshots,
    /// since watchOS gives no way to script the UI from outside.
    private func applyLaunchArguments() {
        let args = ProcessInfo.processInfo.arguments
        if let i = args.firstIndex(of: "-waveLevel"), i + 1 < args.count,
           let level = WaveLevel(rawValue: args[i + 1]) {
            waveLevel = level
        }
        if let i = args.firstIndex(of: "-period"), i + 1 < args.count,
           let p = Period(rawValue: args[i + 1]) {
            period = p
        }
        if args.contains("-alert") { showAlert = true }
        if args.contains("-log") { flow = .log }
        if args.contains("-exercises") { flow = .activity(afterLogging: false) }
        // Skips the splash so a screenshot doesn't have to wait it out.
        if args.contains("-noSplash") { splashDone = true }
    }
    #endif
}
