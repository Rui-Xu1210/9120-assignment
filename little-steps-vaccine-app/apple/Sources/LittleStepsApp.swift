import SwiftUI

@main
struct LittleStepsApp: App {
    @StateObject private var store = AppStore()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(store)
                .environment(\.locale, Locale(identifier: "en_AU"))
                .tint(Theme.purple)
                #if os(macOS)
                .frame(minWidth: 460, minHeight: 620)
                #endif
        }
        #if os(macOS)
        .defaultSize(width: 640, height: 820)
        .windowResizability(.contentMinSize)
        #endif
    }
}
