import SwiftUI

@main
struct MotionCueSensorApp: App {
    @StateObject private var model = AppModel()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .task { model.start() }
                .onChange(of: scenePhase, initial: true) { _, newPhase in
                    model.handleScenePhase(newPhase)
                }
        }
    }
}
