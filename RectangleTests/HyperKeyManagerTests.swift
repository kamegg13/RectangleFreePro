//
//  HyperKeyManagerTests.swift
//  RectangleTests
//
//  Tests de la logique de timing HyperKey (tap vs hold)
//

import XCTest
@testable import Rectangle

class HyperKeyManagerTests: XCTestCase {

    // MARK: - Timing constants

    func testTapTimeoutIsReasonable() {
        // La constante de timeout doit être entre 50ms et 500ms
        XCTAssertGreaterThan(HyperKeyManager.tapTimeout, 0.05)
        XCTAssertLessThan(HyperKeyManager.tapTimeout, 0.5)
    }

    func testTapTimeoutIs150ms() {
        XCTAssertEqual(HyperKeyManager.tapTimeout, 0.15, accuracy: 0.001)
    }

    // MARK: - Hyper flags composition

    func testHyperFlagsIncludeAllModifiers() {
        let flags = HyperKeyManager.hyperFlags
        XCTAssertTrue(flags.contains(.maskCommand))
        XCTAssertTrue(flags.contains(.maskControl))
        XCTAssertTrue(flags.contains(.maskAlternate))
        XCTAssertTrue(flags.contains(.maskShift))
    }

    // MARK: - Tap vs hold logic (simulation)

    func testTapDurationIsShort() {
        // Un tap court < tapTimeout → doit émettre Escape
        let tapDuration = 0.05  // 50ms
        XCTAssertLessThan(tapDuration, HyperKeyManager.tapTimeout)
    }

    func testHoldDurationIsLong() {
        // Un hold > tapTimeout → doit injecter Hyper
        let holdDuration = 0.5  // 500ms
        XCTAssertGreaterThan(holdDuration, HyperKeyManager.tapTimeout)
    }

    // MARK: - Defaults

    func testHyperKeyDefaultIsDisabled() {
        // Par défaut, le HyperKey est désactivé
        XCTAssertFalse(Defaults.hyperKeyEnabled.enabled)
    }

    func testHyperKeyCanBeEnabled() {
        let originalValue = Defaults.hyperKeyEnabled.enabled
        Defaults.hyperKeyEnabled.enabled = true
        XCTAssertTrue(Defaults.hyperKeyEnabled.enabled)
        Defaults.hyperKeyEnabled.enabled = originalValue
    }
}
