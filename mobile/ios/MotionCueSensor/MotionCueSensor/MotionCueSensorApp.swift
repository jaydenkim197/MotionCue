import SwiftUI

@main
struct MotionCueSensorApp: App {
    @StateObject private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            ContentView(model: model)
                .task { model.start() }
        }
    }
}
