//
//  CustomSnapTargetTests.swift
//  RectangleTests
//
//  Tests de la détection de zone trigger dans CustomSnapTarget
//

import XCTest
@testable import Rectangle

class CustomSnapTargetTests: XCTestCase {

    private let screenFrame = CGRect(x: 0, y: 0, width: 2560, height: 1440)

    // MARK: - NormalizedRect.contains (logique de zone)

    func testCursorInsideTriggerZone() {
        // Zone 0%-20% en bas à gauche
        let zone = NormalizedRect(x: 0.0, y: 0.0, width: 0.2, height: 0.2)
        let cursorInZone = CGPoint(x: 100, y: 100)  // dans les 512x288 pixels
        XCTAssertTrue(zone.contains(point: cursorInZone, screen: screenFrame))
    }

    func testCursorOutsideTriggerZone() {
        let zone = NormalizedRect(x: 0.0, y: 0.0, width: 0.2, height: 0.2)
        let cursorOutside = CGPoint(x: 1500, y: 900)  // centre de l'écran
        XCTAssertFalse(zone.contains(point: cursorOutside, screen: screenFrame))
    }

    func testCornerZoneTopRight() {
        // Coin supérieur droit : 80%-100% x 80%-100%
        let zone = NormalizedRect(x: 0.8, y: 0.8, width: 0.2, height: 0.2)
        let insidePoint = CGPoint(x: 2500, y: 1400)
        let outsidePoint = CGPoint(x: 100, y: 100)
        XCTAssertTrue(zone.contains(point: insidePoint, screen: screenFrame))
        XCTAssertFalse(zone.contains(point: outsidePoint, screen: screenFrame))
    }

    // MARK: - CustomSnapTarget Codable

    func testCustomSnapTargetCodable() throws {
        let target = CustomSnapTarget(
            name: "My Zone",
            triggerZone: NormalizedRect(x: 0.0, y: 0.0, width: 0.1, height: 0.1),
            targetFrame: NormalizedRect(x: 0.0, y: 0.0, width: 0.5, height: 1.0)
        )
        let data = try JSONEncoder().encode(target)
        let decoded = try JSONDecoder().decode(CustomSnapTarget.self, from: data)
        XCTAssertEqual(decoded.name, "My Zone")
        XCTAssertEqual(decoded.triggerZone.width, 0.1, accuracy: 0.001)
        XCTAssertEqual(decoded.targetFrame.width, 0.5, accuracy: 0.001)
    }

    // MARK: - CustomSnapCalculation

    func testCustomSnapCalcRect() {
        let target = CustomSnapTarget(
            name: "Left Half",
            triggerZone: NormalizedRect(x: 0.0, y: 0.0, width: 0.05, height: 1.0),
            targetFrame: NormalizedRect(x: 0.0, y: 0.0, width: 0.5, height: 1.0)
        )
        Defaults.customSnapTargets.typedValue = [target]

        let calc = CustomSnapCalculation(index: 0)
        let params = RectCalculationParameters(
            window: Window(id: 0, rect: .zero),
            visibleFrameOfScreen: screenFrame,
            action: .customSnap1,
            lastAction: nil
        )
        let result = calc.calculateRect(params)
        XCTAssertEqual(result.rect.width, 1280, accuracy: 1)
        XCTAssertEqual(result.rect.height, 1440, accuracy: 1)
        XCTAssertEqual(result.rect.minX, 0, accuracy: 1)

        Defaults.customSnapTargets.typedValue = nil
    }

    func testCustomSnapCalcOutOfBoundsReturnsNull() {
        Defaults.customSnapTargets.typedValue = []
        let calc = CustomSnapCalculation(index: 3)
        let params = RectCalculationParameters(
            window: Window(id: 0, rect: .zero),
            visibleFrameOfScreen: screenFrame,
            action: .customSnap4,
            lastAction: nil
        )
        let result = calc.calculateRect(params)
        XCTAssertTrue(result.rect.isNull)
        Defaults.customSnapTargets.typedValue = nil
    }
}
