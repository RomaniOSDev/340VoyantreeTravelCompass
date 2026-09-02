import SwiftUI
import UIKit

enum Keyboard {
    static func dismiss() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

private final class KeyboardDismissTapRecognizer: UITapGestureRecognizer {
    override init(target: Any?, action: Selector?) {
        super.init(target: target, action: action)
        cancelsTouchesInView = false
        name = KeyboardDismissInstallerView.recognizerName
    }
}

final class KeyboardDismissInstallerView: UIView {
    static let recognizerName = "Voyantree.dismissKeyboard"

    private weak var attachedWindow: UIWindow?
    private var recognizer: KeyboardDismissTapRecognizer?

    override func didMoveToWindow() {
        super.didMoveToWindow()
        attachIfNeeded()
    }

    override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow == nil {
            detach()
        }
    }

    private func attachIfNeeded() {
        guard let window else {
            detach()
            return
        }
        if attachedWindow === window { return }
        detach()
        let alreadyInstalled = window.gestureRecognizers?.contains(where: { $0.name == Self.recognizerName }) == true
        if alreadyInstalled { return }
        let tap = KeyboardDismissTapRecognizer(target: self, action: #selector(handleTap(_:)))
        window.addGestureRecognizer(tap)
        recognizer = tap
        attachedWindow = window
    }

    private func detach() {
        if let recognizer, let attachedWindow {
            attachedWindow.removeGestureRecognizer(recognizer)
        }
        recognizer = nil
        attachedWindow = nil
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let window = gesture.view else {
            Keyboard.dismiss()
            return
        }
        let point = gesture.location(in: window)
        if let hit = window.hitTest(point, with: nil), Self.isTextInput(hit) {
            return
        }
        Keyboard.dismiss()
    }

    private static func isTextInput(_ view: UIView) -> Bool {
        var current: UIView? = view
        while let node = current {
            if node is UITextField || node is UITextView || node is UISearchBar {
                return true
            }
            current = node.superview
        }
        return false
    }
}

struct KeyboardDismissInstaller: UIViewRepresentable {
    func makeUIView(context: Context) -> KeyboardDismissInstallerView {
        KeyboardDismissInstallerView()
    }

    func updateUIView(_ uiView: KeyboardDismissInstallerView, context: Context) {}
}

extension View {
    func dismissKeyboardOnTap() -> some View {
        background(KeyboardDismissInstaller())
    }

    func keyboardDoneButton() -> some View {
        toolbar {
            ToolbarItemGroup(placement: .keyboard) {
                Spacer()
                Button("Done") { Keyboard.dismiss() }
            }
        }
    }
}
