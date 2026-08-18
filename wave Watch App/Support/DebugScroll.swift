//
//  DebugScroll.swift
//  wave Watch App
//
//  watchOS gives no way to drive the simulator's UI from outside (and macOS
//  denies AppleScript assistive access here), so screens below the fold are
//  unreachable for screenshots. This lets a launch argument jump to a section:
//
//      xcrun simctl launch <sim> <bundle-id> -scrollTo today
//
//  DEBUG only — it compiles away entirely in Release.
//

import SwiftUI

extension View {
    /// Scrolls to the `-scrollTo <id>` section once the page appears.
    func debugScroll(_ proxy: ScrollViewProxy) -> some View {
        #if DEBUG
        return onAppear {
            let args = ProcessInfo.processInfo.arguments
            guard let i = args.firstIndex(of: "-scrollTo"), i + 1 < args.count else { return }
            let anchor = args[i + 1]
            // After the first layout pass, or there is nothing to scroll to yet.
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                proxy.scrollTo(anchor, anchor: .top)
            }
        }
        #else
        return self
        #endif
    }
}
