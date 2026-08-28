import ServiceManagement
import XCTest
@testable import ClipboardManager

@MainActor
final class LoginItemManagerTests: XCTestCase {
    func testReconcileUsesActualSystemState() {
        let settings = AppSettings(defaults: isolatedDefaults())
        let service = FakeLoginItemService(status: .enabled)
        settings.launchAtLogin = false

        let manager = LoginItemManager(settings: settings, service: service)
        manager.reconcile()

        XCTAssertTrue(manager.isEnabled)
        XCTAssertTrue(settings.launchAtLogin)
    }

    func testSuccessfulRegistrationUpdatesStoredState() throws {
        let settings = AppSettings(defaults: isolatedDefaults())
        let service = FakeLoginItemService(status: .notRegistered)
        let manager = LoginItemManager(settings: settings, service: service)

        try manager.setEnabled(true)

        XCTAssertEqual(service.registerCallCount, 1)
        XCTAssertTrue(manager.isEnabled)
        XCTAssertTrue(settings.launchAtLogin)
    }

    func testFailedRegistrationRestoresActualState() {
        let settings = AppSettings(defaults: isolatedDefaults())
        let service = FakeLoginItemService(status: .notRegistered, registerError: TestError.failed)
        let manager = LoginItemManager(settings: settings, service: service)
        settings.launchAtLogin = true

        XCTAssertThrowsError(try manager.setEnabled(true))

        XCTAssertFalse(manager.isEnabled)
        XCTAssertFalse(settings.launchAtLogin)
    }

    func testSuccessfulUnregistrationUpdatesStoredState() throws {
        let settings = AppSettings(defaults: isolatedDefaults())
        let service = FakeLoginItemService(status: .enabled)
        let manager = LoginItemManager(settings: settings, service: service)

        try manager.setEnabled(false)

        XCTAssertEqual(service.unregisterCallCount, 1)
        XCTAssertFalse(manager.isEnabled)
        XCTAssertFalse(settings.launchAtLogin)
    }

    func testFailedUnregistrationRestoresActualState() {
        let settings = AppSettings(defaults: isolatedDefaults())
        let service = FakeLoginItemService(status: .enabled, unregisterError: TestError.failed)
        let manager = LoginItemManager(settings: settings, service: service)
        settings.launchAtLogin = false

        XCTAssertThrowsError(try manager.setEnabled(false))

        XCTAssertTrue(manager.isEnabled)
        XCTAssertTrue(settings.launchAtLogin)
    }

    private func isolatedDefaults() -> UserDefaults {
        UserDefaults(suiteName: "ClipboardManagerLoginTests-\(UUID())")!
    }
}

private enum TestError: Error { case failed }

private final class FakeLoginItemService: LoginItemServicing {
    var status: SMAppService.Status
    let registerError: Error?
    let unregisterError: Error?
    private(set) var registerCallCount = 0
    private(set) var unregisterCallCount = 0

    init(status: SMAppService.Status, registerError: Error? = nil, unregisterError: Error? = nil) {
        self.status = status
        self.registerError = registerError
        self.unregisterError = unregisterError
    }

    func register() throws {
        registerCallCount += 1
        if let registerError { throw registerError }
        status = .enabled
    }

    func unregister() throws {
        unregisterCallCount += 1
        if let unregisterError { throw unregisterError }
        status = .notRegistered
    }
}
