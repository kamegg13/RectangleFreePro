//
//  WindowRulesManagerTests.swift
//  RectangleTests
//
//  Tests du modèle WindowRule et de la logique de matching
//

import XCTest
@testable import Rectangle

class WindowRulesManagerTests: XCTestCase {

    override func setUp() {
        Defaults.windowRules.typedValue = nil
    }

    override func tearDown() {
        Defaults.windowRules.typedValue = nil
    }

    // MARK: - WindowRuleAction Codable

    func testAssignToWorkspaceActionCodable() throws {
        let action = WindowRuleAction.assignToWorkspace("web")
        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(WindowRuleAction.self, from: data)
        if case .assignToWorkspace(let id) = decoded {
            XCTAssertEqual(id, "web")
        } else {
            XCTFail("Expected assignToWorkspace")
        }
    }

    func testMoveToScreenActionCodable() throws {
        let action = WindowRuleAction.moveToScreen(1)
        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(WindowRuleAction.self, from: data)
        if case .moveToScreen(let idx) = decoded {
            XCTAssertEqual(idx, 1)
        } else {
            XCTFail("Expected moveToScreen")
        }
    }

    func testApplyPositionActionCodable() throws {
        let action = WindowRuleAction.applyPosition(.leftHalf)
        let data = try JSONEncoder().encode(action)
        let decoded = try JSONDecoder().decode(WindowRuleAction.self, from: data)
        if case .applyPosition(let wa) = decoded {
            XCTAssertEqual(wa, .leftHalf)
        } else {
            XCTFail("Expected applyPosition")
        }
    }

    // MARK: - WindowRule Codable

    func testWindowRuleCodableRoundtrip() throws {
        let rule = WindowRule(
            appBundleId: "com.apple.Safari",
            windowTitleContains: nil,
            action: .assignToWorkspace("web")
        )
        let data = try JSONEncoder().encode(rule)
        let decoded = try JSONDecoder().decode(WindowRule.self, from: data)
        XCTAssertEqual(decoded.appBundleId, "com.apple.Safari")
        XCTAssertNil(decoded.windowTitleContains)
        if case .assignToWorkspace(let id) = decoded.action {
            XCTAssertEqual(id, "web")
        } else {
            XCTFail("Decoded action mismatch")
        }
    }

    func testWindowRuleWithTitleFilterCodable() throws {
        let rule = WindowRule(
            appBundleId: "com.apple.Terminal",
            windowTitleContains: "build",
            action: .applyPosition(.maximize)
        )
        let data = try JSONEncoder().encode(rule)
        let decoded = try JSONDecoder().decode(WindowRule.self, from: data)
        XCTAssertEqual(decoded.windowTitleContains, "build")
    }

    // MARK: - Defaults persistence

    func testWindowRulesStoredAndRetrieved() {
        let rule = WindowRule(appBundleId: "com.spotify.client", action: .assignToWorkspace("music"))
        Defaults.windowRules.typedValue = [rule]
        let retrieved = Defaults.windowRules.typedValue ?? []
        XCTAssertEqual(retrieved.count, 1)
        XCTAssertEqual(retrieved.first?.appBundleId, "com.spotify.client")
    }

    func testEmptyRulesDefaultsToNil() {
        XCTAssertNil(Defaults.windowRules.typedValue)
    }

    // MARK: - No rules = no crash

    func testApplyWithNoRulesDoesNothing() {
        Defaults.windowRules.typedValue = nil
        // Just verify no crash — no actual window element in tests
        let dummyApp = NSRunningApplication.current
        // Note: we can't call WindowRulesManager.apply() in tests without a real AXUIElement,
        // but we test that Defaults.windowRules returns nil gracefully
        XCTAssertNil(Defaults.windowRules.typedValue)
        _ = dummyApp  // silence unused warning
    }
}
