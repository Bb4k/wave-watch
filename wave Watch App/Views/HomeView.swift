//
//  HomeView.swift
//  wave Watch App
//
//  Cut back to what a wrist earns its place with: the wave, the two actions,
//  today's count, and the craving pattern. Everything else the phone showed —
//  handled totals, streak, triggers, activities, locations, risk — is a phone
//  job now.
//

import SwiftUI

struct HomeView: View {
    @EnvironmentObject private var store: WaveStore

    @State private var replay = 0

    var body: some View {
        ScrollViewReader { proxy in
        ScrollView {
            VStack(spacing: 6) {
                SlideIn(index: 0, replay: replay) {
                    Text(store.waveLevel.rawValue)
                        .font(WaveFont.title)
                        .foregroundStyle(store.waveLevel.color)
                }
                .id("top")

                WaveClockView(
                    size: Metrics.clockSize,
                    clip: store.waveLevel.clip,
                    logs: store.logs,
                    replay: replay,
                    delay: Entrance.chartDelay(1)
                )

                SlideIn(index: 2, replay: replay) {
                    WaveClockLegend()
                }
                .padding(.top, 2)

                SlideIn(index: 3, replay: replay) {
                    PillButton(title: "Log a craving", symbol: "plus", style: .ink) {
                        store.open(.log)
                    }
                }
                .id("log")

                SlideIn(index: 4, replay: replay) {
                    PillButton(title: "Do an activity", symbol: "water.waves", style: .orange) {
                        store.open(.activity(afterLogging: false))
                    }
                }

                SlideIn(index: 5, replay: replay) { todayCard }
                    .id("today")

                SlideIn(index: 6, replay: replay) {
                    CravingPatternCard(data: store.data, replay: replay)
                }
                .id("pattern")

                Text("Triggers, locations and history are in Wave on your phone.")
                    .font(WaveFont.caption)
                    .foregroundStyle(Palette.muted)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 2)
            }
            .padding(.horizontal, Metrics.screenPadding)
            .padding(.top, 8)
            .padding(.bottom, 10)
        }
        // watchOS reserves a band at the top for a navigation title this screen
        // doesn't have — enough of one that the dial couldn't finish inside the
        // screen. Taking the safe area back is what buys the title and the
        // whole circle their one screenful; the status time still draws over
        // the corner, which the centred title clears.
        .ignoresSafeArea(.container, edges: .top)
        // No scroll-position handling here on purpose: Home keeps whatever
        // position the user left it at. Snapping back to the top the moment a
        // page change or a flow ended is what made the foot of the page feel
        // like it threw you back to the start.
        .debugScroll(proxy)
        }
        .waveScreen()
        // Once, when the splash lifts — see Entrance.swift.
        .openEntrance($replay)
    }

    private var todayCard: some View {
        VStack(spacing: 6) {
            Text("Today")
                .font(WaveFont.headline)
                .foregroundStyle(Palette.ink)
                .frame(maxWidth: .infinity, alignment: .leading)

            HStack(spacing: 0) {
                stat(
                    symbol: "heart.fill", tint: Palette.red,
                    value: "\(store.todayCravings)",
                    label: store.todayCravings == 1 ? "craving" : "cravings"
                )
                divider
                stat(
                    symbol: "flame.fill", tint: Palette.orange,
                    value: "\(store.todayUrges)", label: "urges"
                )
                divider
                stat(
                    symbol: "checkmark.circle.fill", tint: Palette.green,
                    value: store.todayHandled, label: "handled"
                )
            }
        }
        .waveCard()
    }

    private var divider: some View {
        Rectangle()
            .fill(Palette.border)
            .frame(width: 1, height: 34)
    }

    private func stat(symbol: String, tint: Color, value: String, label: String) -> some View {
        VStack(spacing: 2) {
            Image(systemName: symbol)
                .font(.system(size: 12))
                .foregroundStyle(tint)
            Text(value)
                .font(WaveFont.number(18))
                .foregroundStyle(Palette.ink)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(WaveFont.caption)
                .foregroundStyle(Palette.muted)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    HomeView().environmentObject(WaveStore())
}
