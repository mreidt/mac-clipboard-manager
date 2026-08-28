import Foundation
import ServiceManagement

protocol LoginItemServicing { var status: SMAppService.Status { get }; func register() throws; func unregister() throws }
struct MainLoginItemService: LoginItemServicing { var status: SMAppService.Status { SMAppService.mainApp.status }; func register() throws { try SMAppService.mainApp.register() }; func unregister() throws { try SMAppService.mainApp.unregister() } }

@MainActor
final class LoginItemManager {
    private let service: LoginItemServicing
    private let settings: AppSettings
    init(settings: AppSettings, service: LoginItemServicing = MainLoginItemService()) { self.settings = settings; self.service = service }
    var isEnabled: Bool { service.status == .enabled }
    func reconcile() { settings.launchAtLogin = isEnabled }
    func setEnabled(_ enabled: Bool) throws { do { if enabled { try service.register() } else { try service.unregister() }; settings.launchAtLogin = isEnabled } catch { settings.launchAtLogin = isEnabled; throw error } }
}
