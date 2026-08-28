import Foundation
import Observation
import ServiceManagement

protocol LoginItemServicing { var status: SMAppService.Status { get }; func register() throws; func unregister() throws }
struct MainLoginItemService: LoginItemServicing { var status: SMAppService.Status { SMAppService.mainApp.status }; func register() throws { try SMAppService.mainApp.register() }; func unregister() throws { try SMAppService.mainApp.unregister() } }

@MainActor
@Observable
final class LoginItemManager {
    private let service: LoginItemServicing
    private let settings: AppSettings
    init(settings: AppSettings, service: LoginItemServicing = MainLoginItemService()) {
        self.settings = settings
        self.service = service
        self.status = service.status
    }
    private(set) var status: SMAppService.Status = .notRegistered

    var isEnabled: Bool { status == .enabled }

    func refreshStatus() {
        status = service.status
    }

    func reconcile() {
        refreshStatus()
        settings.launchAtLogin = isEnabled
    }

    func setEnabled(_ enabled: Bool) throws {
        do {
            if enabled {
                try service.register()
            } else {
                try service.unregister()
            }
        } catch {
            refreshStatus()
            settings.launchAtLogin = isEnabled
            throw error
        }

        refreshStatus()
        settings.launchAtLogin = isEnabled
    }
}
