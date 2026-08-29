import ApplicationServices

@MainActor
protocol AccessibilityPermissionChecking: AnyObject {
    func isTrusted() -> Bool
    func requestPermissionPromptIfNeeded()
}

final class AccessibilityPermissionManager: AccessibilityPermissionChecking {
    private var didRequestPrompt = false
    private let checkTrust: () -> Bool
    private let prompt: () -> Void

    init(checkTrust: @escaping () -> Bool = { AXIsProcessTrusted() }, prompt: (() -> Void)? = nil) {
        self.checkTrust = checkTrust
        self.prompt = prompt ?? {
            let options = [kAXTrustedCheckOptionPrompt.takeUnretainedValue() as String: true] as CFDictionary
            _ = AXIsProcessTrustedWithOptions(options)
        }
    }

    func isTrusted() -> Bool {
        checkTrust()
    }

    func requestPermissionPromptIfNeeded() {
        guard !didRequestPrompt else { return }
        didRequestPrompt = true
        prompt()
    }
}
