import Foundation
import XCTest
@testable import ClipboardManager

@MainActor
final class AppDataStoreTests: XCTestCase {
    func testDevelopmentOverrideUsesItsOwnStoreDirectory() throws {
        let directory = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: directory) }

        let url = try AppDataStore.storeURL(
            environment: [AppDataStore.directoryEnvironmentKey: directory.path]
        )

        XCTAssertEqual(url, directory.appendingPathComponent(AppDataStore.storeFilename))
        XCTAssertTrue(FileManager.default.fileExists(atPath: directory.path))
        let attributes = try FileManager.default.attributesOfItem(atPath: directory.path)
        XCTAssertEqual(attributes[.posixPermissions] as? NSNumber, NSNumber(value: 0o700))
    }

    func testInstalledAppUsesBundleSpecificApplicationSupportDirectory() throws {
        let applicationSupport = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: applicationSupport) }

        let url = try AppDataStore.storeURL(
            environment: [:],
            applicationSupportDirectory: applicationSupport
        )

        XCTAssertEqual(
            url,
            applicationSupport
                .appendingPathComponent(AppDataStore.bundleIdentifier, isDirectory: true)
                .appendingPathComponent(AppDataStore.storeFilename)
        )
    }

    func testDevelopmentAndInstalledContainersDoNotShareFavorites() throws {
        let root = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString, isDirectory: true)
        defer { try? FileManager.default.removeItem(at: root) }
        let developmentDirectory = root.appendingPathComponent("development", isDirectory: true)
        let applicationSupport = root.appendingPathComponent("application-support", isDirectory: true)

        let developmentContainer = try AppDataStore.makeContainer(
            environment: [AppDataStore.directoryEnvironmentKey: developmentDirectory.path],
            applicationSupportDirectory: applicationSupport
        )
        let developmentRepository = ClipboardRepository(context: developmentContainer.mainContext)
        let favorite = try XCTUnwrap(
            developmentRepository.recordCopiedText("development favorite", historyLimit: 20)
        )
        try developmentRepository.setFavorite(entryID: favorite.id, isFavorite: true)

        let installedContainer = try AppDataStore.makeContainer(
            environment: [:],
            applicationSupportDirectory: applicationSupport
        )
        let installedRepository = ClipboardRepository(context: installedContainer.mainContext)

        XCTAssertEqual(try developmentRepository.fetchFavorites().map(\.text), ["development favorite"])
        XCTAssertTrue(try installedRepository.fetchFavorites().isEmpty)
    }
}
