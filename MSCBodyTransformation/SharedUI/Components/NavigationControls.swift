import SwiftUI
import UIKit

@MainActor
private struct SinglePressNavigationBackButtonModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .navigationBarBackButtonHidden(true)
            .background {
                InteractivePopGestureBridge()
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.body.weight(.semibold))
                            .frame(
                                minWidth: AppControlMetrics.minimumTouchTarget,
                                minHeight: AppControlMetrics.minimumTouchTarget
                            )
                            .contentShape(Rectangle())
                    }
                    .buttonStyle(.plain)
                    .accessibilityLabel(Text("action.back"))
                    .accessibilityIdentifier("navigation.back")
                }
            }
    }
}

@MainActor
private struct InteractivePopGestureBridge:
    UIViewControllerRepresentable
{
    func makeUIViewController(
        context: Context
    ) -> InteractivePopGestureController {
        InteractivePopGestureController()
    }

    func updateUIViewController(
        _ uiViewController: InteractivePopGestureController,
        context: Context
    ) {
        uiViewController.enableGestureIfPossible()
    }
}

@MainActor
private final class InteractivePopGestureController:
    UIViewController,
    UIGestureRecognizerDelegate
{
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        enableGestureIfPossible()
    }

    func enableGestureIfPossible() {
        guard let gesture = navigationController?
            .interactivePopGestureRecognizer else {
            return
        }
        gesture.isEnabled = true
        gesture.delegate = self
    }

    func gestureRecognizerShouldBegin(
        _ gestureRecognizer: UIGestureRecognizer
    ) -> Bool {
        guard let navigationController else {
            return false
        }
        return navigationController.viewControllers.count > 1
            && navigationController.transitionCoordinator == nil
    }
}

extension View {
    @MainActor
    func singlePressNavigationBackButton() -> some View {
        modifier(SinglePressNavigationBackButtonModifier())
    }
}
