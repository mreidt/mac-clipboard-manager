import Foundation
import SwiftData

enum AppDataStore {
    static let directoryEnvironmentKey = "CLIPBOARD_MANAGER_DATA_DIRECTORY"
    static let bundleIdentifier = "com.mreidt.clipboard-manager"
    static let storeFilename = "Clipboard.store"

    static func makeContainer(
        environment: [String: String] = ProcessInfo.processInfo.environment,
        applicationSupportDirectory: URL? = nil
    ) throws -> ModelContainer {
        let storeURL = try storeURL(
            environment: environment,
            applicationSupportDirectory: applicationSupportDirectory
        )
        let configuration = ModelConfiguration(url: storeURL)
        return try ModelContainer(for: ClipboardEntry.self, configurations: configuration)
    }

    static func storeURL(
        environment: [String: String],
        applicationSupportDirectory: URL? = nil
    ) throws -> URL {
        let directory: URL
#if DEBUG
        if let override = environment[directoryEnvironmentKey], !override.isEmpty {
            directory = URL(fileURLWithPath: override, isDirectory: true).standardizedFileURL
        } else {
            directory = try defaultDirectory(applicationSupportDirectory: applicationSupportDirectory)
        }
#else
        directory = try defaultDirectory(applicationSupportDirectory: applicationSupportDirectory)
#endif

        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try FileManager.default.setAttributes(
            [.posixPermissions: 0o700],
            ofItemAtPath: directory.path
        )
        return directory.appendingPathComponent(storeFilename, isDirectory: false)
    }

    private static func defaultDirectory(applicationSupportDirectory: URL?) throws -> URL {
        let baseDirectory = try applicationSupportDirectory
            ?? FileManager.default.url(
                for: .applicationSupportDirectory,
                in: .userDomainMask,
                appropriateFor: nil,
                create: true
            )
        return baseDirectory.appendingPathComponent(bundleIdentifier, isDirectory: true)
    }
}
