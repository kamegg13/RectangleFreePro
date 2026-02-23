//
//  MoveAllToDisplayTests.swift
//  RectangleTests
//
//  Tests d'itération multi-fenêtres pour moveAllWindowsToDisplay
//

import XCTest
@testable import Rectangle

class MoveAllToDisplayTests: XCTestCase {

    // MARK: - WindowAction cases

    func testMoveAllToNextDisplayActionExists() {
        let action = WindowAction(rawValue: 94)
        XCTAssertEqual(action, .moveAllToNextDisplay)
    }

    func testMoveAllToPreviousDisplayActionExists() {
        let action = WindowAction(rawValue: 95)
        XCTAssertEqual(action, .moveAllToPreviousDisplay)
    }

    func testMoveAllToNextDisplayIsInActiveArray() {
        XCTAssertTrue(WindowAction.active.contains(.moveAllToNextDisplay))
    }

    func testMoveAllToPreviousDisplayIsInActiveArray() {
        XCTAssertTrue(WindowAction.active.contains(.moveAllToPreviousDisplay))
    }

    func testMoveAllActionsHaveNames() {
        XCTAssertEqual(WindowAction.moveAllToNextDisplay.name, "moveAllToNextDisplay")
        XCTAssertEqual(WindowAction.moveAllToPreviousDisplay.name, "moveAllToPreviousDisplay")
    }

    func testMoveAllActionsHaveDisplayNames() {
        XCTAssertNotNil(WindowAction.moveAllToNextDisplay.displayName)
        XCTAssertNotNil(WindowAction.moveAllToPreviousDisplay.displayName)
    }

    func testMoveAllActionsAreNotDragSnappable() {
        XCTAssertFalse(WindowAction.moveAllToNextDisplay.isDragSnappable)
        XCTAssertFalse(WindowAction.moveAllToPreviousDisplay.isDragSnappable)
    }

    func testMoveAllActionsHaveNoGaps() {
        XCTAssertEqual(WindowAction.moveAllToNextDisplay.gapsApplicable, .none)
        XCTAssertEqual(WindowAction.moveAllToPreviousDisplay.gapsApplicable, .none)
    }
}
