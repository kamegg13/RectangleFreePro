//
//  ArrangementManagerTests.swift
//  RectangleTests
//
//  Tests de sérialisation/désérialisation et normalisation des frames
//

import XCTest
@testable import Rectangle

class ArrangementManagerTests: XCTestCase {

    // MARK: - NormalizedRect serialization

    func testNormalizedRectCodable() throws {
        let original = NormalizedRect(x: 0.1, y: 0.2, width: 0.5, height: 0.6)
        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(NormalizedRect.self, from: data)
        XCTAssertEqual(decoded.x, original.x, accuracy: 0.001)
        XCTAssertEqual(decoded.y, original.y, accuracy: 0.001)
        XCTAssertEqual(decoded.width, original.width, accuracy: 0.001)
        XCTAssertEqual(decoded.height, original.height, accuracy: 0.001)
    }

    // MARK: - NormalizedRect.toScreen

    func testToScreenFullScreen() {
        let screen = CGRect(x: 0, y: 0, width: 2560, height: 1440)
        let norm = NormalizedRect(x: 0, y: 0, width: 1, height: 1)
        let result = norm.toScreen(screen)
        XCTAssertEqual(result.width, 2560, accuracy: 1)
        XCTAssertEqual(result.height, 1440, accuracy: 1)
    }

    func testToScreenQuarter() {
        let screen = CGRect(x: 0, y: 0, width: 2560, height: 1440)
        let norm = NormalizedRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
        let result = norm.toScreen(screen)
        XCTAssertEqual(result.origin.x, 640, accuracy: 1)
        XCTAssertEqual(result.origin.y, 360, accuracy: 1)
        XCTAssertEqual(result.width, 1280, accuracy: 1)
        XCTAssertEqual(result.height, 720, accuracy: 1)
    }

    func testToScreenWithOffset() {
        // Écran secondaire commençant à x=2560
        let screen = CGRect(x: 2560, y: 0, width: 1920, height: 1080)
        let norm = NormalizedRect(x: 0, y: 0, width: 1, height: 1)
        let result = norm.toScreen(screen)
        XCTAssertEqual(result.origin.x, 2560, accuracy: 1)
        XCTAssertEqual(result.width, 1920, accuracy: 1)
    }

    // MARK: - NormalizedRect.contains

    func testContainsPoint() {
        let screen = CGRect(x: 0, y: 0, width: 2560, height: 1440)
        // Zone 25%-75% de l'écran
        let zone = NormalizedRect(x: 0.25, y: 0.25, width: 0.5, height: 0.5)
        // Point au centre → dedans
        XCTAssertTrue(zone.contains(point: CGPoint(x: 1280, y: 720), screen: screen))
        // Point dans le coin → dehors
        XCTAssertFalse(zone.contains(point: CGPoint(x: 10, y: 10), screen: screen))
    }

    // MARK: - WindowArrangement / Arrangement Codable

    func testArrangementCodableRoundtrip() throws {
        let window = WindowArrangement(
            bundleId: "com.test.App",
            normalizedFrame: NormalizedRect(x: 0.0, y: 0.0, width: 0.5, height: 1.0),
            screenIndex: 0
        )
        let arrangement = Arrangement(name: "test", date: Date(timeIntervalSince1970: 0), windows: [window])

        let data = try JSONEncoder().encode(arrangement)
        let decoded = try JSONDecoder().decode(Arrangement.self, from: data)

        XCTAssertEqual(decoded.name, "test")
        XCTAssertEqual(decoded.windows.count, 1)
        XCTAssertEqual(decoded.windows[0].bundleId, "com.test.App")
        XCTAssertEqual(decoded.windows[0].screenIndex, 0)
        XCTAssertEqual(decoded.windows[0].normalizedFrame.width, 0.5, accuracy: 0.001)
    }
}
