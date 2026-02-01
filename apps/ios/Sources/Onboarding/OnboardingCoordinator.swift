import SwiftUI

struct OnboardingCoordinator: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var currentStep: OnboardingStep = .welcome
    
    private enum OnboardingStep {
        case welcome
        case gateway
        case permissions
        case complete
    }
    
    var body: some View {
        Group {
            switch self.currentStep {
            case .welcome:
                WelcomeView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        self.currentStep = .gateway
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)))
            
            case .gateway:
                GatewaySetupView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        self.currentStep = .permissions
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)))
            
            case .permissions:
                PermissionsView {
                    withAnimation(.easeInOut(duration: 0.35)) {
                        self.currentStep = .complete
                        self.hasCompletedOnboarding = true
                    }
                }
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal: .move(edge: .leading).combined(with: .opacity)))
            
            case .complete:
                Color.clear
            }
        }
        .animation(.easeInOut(duration: 0.35), value: self.currentStep)
    }
}
