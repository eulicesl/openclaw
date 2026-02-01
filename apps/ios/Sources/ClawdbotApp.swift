import SwiftUI

@main
struct MoltbotApp: App {
    @State private var appModel: NodeAppModel
    @State private var gatewayController: GatewayConnectionController
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false

    init() {
        GatewaySettingsStore.bootstrapPersistence()
        let appModel = NodeAppModel()
        _appModel = State(initialValue: appModel)
        _gatewayController = State(initialValue: GatewayConnectionController(appModel: appModel))
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if self.hasCompletedOnboarding {
                    RootCanvas()
                        .environment(self.appModel)
                        .environment(self.appModel.voiceWake)
                        .environment(self.gatewayController)
                        .onOpenURL { url in
                            Task { await self.appModel.handleDeepLink(url: url) }
                        }
                        .onChange(of: self.scenePhase) { _, newValue in
                            self.appModel.setScenePhase(newValue)
                            self.gatewayController.setScenePhase(newValue)
                        }
                } else {
                    OnboardingCoordinator()
                        .environment(self.gatewayController)
                }
            }
        }
    }
}
