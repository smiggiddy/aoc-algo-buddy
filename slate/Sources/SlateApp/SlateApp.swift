import SlateTheme
import SwiftUI

@main
struct SlateApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environment(model)
                .environment(model.themeStore)
                // A terminal is a dark-first surface; letting the system tint
                // the chrome light while the grid stays dark looks broken.
                .preferredColorScheme(model.themeStore.followsSystemAppearance ? nil : .dark)
                .persistentSystemOverlays(.hidden)
        }
    }
}
