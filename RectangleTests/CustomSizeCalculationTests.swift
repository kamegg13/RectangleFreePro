//
//  CustomSizeCalculationTests.swift
//  RectangleTests
//
//  Tests du calcul CustomSizeCalculation : ratios % et pixels absolus, centrage
//

import XCTest
@testable import Rectangle

class CustomSizeCalculationTests: XCTestCase {

    private let screenFrame = CGRect(x: 0, y: 0, width: 2560, height: 1440)

    private func makeParams(window: CGRect = .zero, action: WindowAction = .customSize1) -> RectCalculationParameters {
        RectCalculationParameters(
            window: Window(id: 0, rect: window),
            visibleFrameOfScreen: screenFrame,
            action: action,
            lastAction: nil
        )
    }

    private func customSizeFor(_ spec: CustomWindowSize, action: WindowAction = .customSize1) -> CGRect {
        Defaults.customSizes.typedValue = [spec]
        let calc = CustomSizeCalculation(index: 0)
        let result = calc.calculateRect(makeParams(action: action))
        Defaults.customSizes.typedValue = nil
        return result.rect
    }

    // MARK: - Ratios (valeurs ≤ 1)

    func testHalfScreenRatio() {
        let spec = CustomWindowSize(name: "Half", width: 0.5, height: 0.5)
        let rect = customSizeFor(spec)
        XCTAssertEqual(rect.width, 1280, accuracy: 1)
        XCTAssertEqual(rect.height, 720, accuracy: 1)
    }

    func testFullScreenRatio() {
        let spec = CustomWindowSize(name: "Full", width: 1.0, height: 1.0)
        let rect = customSizeFor(spec)
        XCTAssertEqual(rect.width, 2560, accuracy: 1)
        XCTAssertEqual(rect.height, 1440, accuracy: 1)
    }

    // MARK: - Pixels absolus (valeurs > 1)

    func testAbsolutePixels() {
        let spec = CustomWindowSize(name: "1680x1050", width: 1680, height: 1050)
        let rect = customSizeFor(spec)
        XCTAssertEqual(rect.width, 1680, accuracy: 1)
        XCTAssertEqual(rect.height, 1050, accuracy: 1)
    }

    func testAbsolutePixelsCappedToScreen() {
        // Si la taille absolue dépasse l'écran, elle est cappée
        let spec = CustomWindowSize(name: "TooBig", width: 9999, height: 9999)
        let rect = customSizeFor(spec)
        XCTAssertLessThanOrEqual(rect.width, screenFrame.width)
        XCTAssertLessThanOrEqual(rect.height, screenFrame.height)
    }

    // MARK: - Centrage

    func testCenteredPosition() {
        let spec = CustomWindowSize(name: "Centered", width: 0.5, height: 0.5, centerX: 0.5, centerY: 0.5)
        let rect = customSizeFor(spec)
        // Centre horizontal et vertical
        XCTAssertEqual(rect.midX, screenFrame.midX, accuracy: 1)
        XCTAssertEqual(rect.midY, screenFrame.midY, accuracy: 1)
    }

    func testTopLeftPosition() {
        let spec = CustomWindowSize(name: "TopLeft", width: 0.5, height: 0.5, centerX: 0.0, centerY: 1.0)
        let rect = customSizeFor(spec)
        XCTAssertEqual(rect.minX, screenFrame.minX, accuracy: 1)
        XCTAssertEqual(rect.maxY, screenFrame.maxY, accuracy: 1)
    }

    func testBottomRightPosition() {
        let spec = CustomWindowSize(name: "BottomRight", width: 0.5, height: 0.5, centerX: 1.0, centerY: 0.0)
        let rect = customSizeFor(spec)
        XCTAssertEqual(rect.maxX, screenFrame.maxX, accuracy: 1)
        XCTAssertEqual(rect.minY, screenFrame.minY, accuracy: 1)
    }

    // MARK: - Index hors limites

    func testOutOfBoundsIndexReturnsNull() {
        Defaults.customSizes.typedValue = []
        let calc = CustomSizeCalculation(index: 0)
        let result = calc.calculateRect(makeParams())
        XCTAssertTrue(result.rect.isNull)
        Defaults.customSizes.typedValue = nil
    }
}
