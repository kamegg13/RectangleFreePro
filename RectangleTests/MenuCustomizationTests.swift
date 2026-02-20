//
//  MenuCustomizationTests.swift
//  RectangleTests
//
//  Tests du filtrage des actions dans MenuCustomizationManager
//

import XCTest
@testable import Rectangle

class MenuCustomizationTests: XCTestCase {

    override func setUp() {
        // Remettre à zéro avant chaque test
        Defaults.hiddenMenuActions.typedValue = nil
    }

    override func tearDown() {
        Defaults.hiddenMenuActions.typedValue = nil
    }

    func testNoActionsHiddenByDefault() {
        XCTAssertFalse(MenuCustomizationManager.isHidden(.leftHalf))
        XCTAssertFalse(MenuCustomizationManager.isHidden(.maximize))
    }

    func testHideSingleAction() {
        MenuCustomizationManager.setHidden(true, for: .leftHalf)
        XCTAssertTrue(MenuCustomizationManager.isHidden(.leftHalf))
        XCTAssertFalse(MenuCustomizationManager.isHidden(.rightHalf))
    }

    func testUnhideAction() {
        MenuCustomizationManager.setHidden(true, for: .maximize)
        XCTAssertTrue(MenuCustomizationManager.isHidden(.maximize))
        MenuCustomizationManager.setHidden(false, for: .maximize)
        XCTAssertFalse(MenuCustomizationManager.isHidden(.maximize))
    }

    func testHideMultipleActions() {
        MenuCustomizationManager.setHidden(true, for: .leftHalf)
        MenuCustomizationManager.setHidden(true, for: .rightHalf)
        MenuCustomizationManager.setHidden(true, for: .maximize)
        XCTAssertTrue(MenuCustomizationManager.isHidden(.leftHalf))
        XCTAssertTrue(MenuCustomizationManager.isHidden(.rightHalf))
        XCTAssertTrue(MenuCustomizationManager.isHidden(.maximize))
        XCTAssertFalse(MenuCustomizationManager.isHidden(.center))
    }

    func testHideProFeatureAction() {
        MenuCustomizationManager.setHidden(true, for: .moveAllToNextDisplay)
        XCTAssertTrue(MenuCustomizationManager.isHidden(.moveAllToNextDisplay))
        XCTAssertFalse(MenuCustomizationManager.isHidden(.moveAllToPreviousDisplay))
    }

    func testNoDuplicatesInStorage() {
        // Cacher deux fois ne doit pas créer de doublons
        MenuCustomizationManager.setHidden(true, for: .leftHalf)
        MenuCustomizationManager.setHidden(true, for: .leftHalf)
        let stored = Defaults.hiddenMenuActions.typedValue ?? []
        let occurrences = stored.filter { $0 == WindowAction.leftHalf.name }.count
        XCTAssertEqual(occurrences, 1)
    }

    func testPersistenceViaDefaults() {
        MenuCustomizationManager.setHidden(true, for: .topLeft)
        let stored = Defaults.hiddenMenuActions.typedValue ?? []
        XCTAssertTrue(stored.contains(WindowAction.topLeft.name))
    }
}
