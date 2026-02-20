//
//  SpaceManagerTests.swift
//  RectangleTests
//
//  Tests de la logique next/prev space (sans appels système)
//

import XCTest
@testable import Rectangle

class SpaceManagerTests: XCTestCase {

    // MARK: - calculateTargetIndex

    func testNextSpaceNormal() {
        // Depuis l'index 0, direction +1 → index 1
        let result = SpaceManager.calculateTargetIndex(currentIdx: 0, direction: +1, count: 4)
        XCTAssertEqual(result, 1)
    }

    func testPreviousSpaceNormal() {
        // Depuis l'index 2, direction -1 → index 1
        let result = SpaceManager.calculateTargetIndex(currentIdx: 2, direction: -1, count: 4)
        XCTAssertEqual(result, 1)
    }

    func testNextSpaceWrapAround() {
        // Depuis le dernier index, direction +1 → revient au début
        let result = SpaceManager.calculateTargetIndex(currentIdx: 3, direction: +1, count: 4)
        XCTAssertEqual(result, 0)
    }

    func testPreviousSpaceWrapAround() {
        // Depuis le premier index, direction -1 → va à la fin
        let result = SpaceManager.calculateTargetIndex(currentIdx: 0, direction: -1, count: 4)
        XCTAssertEqual(result, 3)
    }

    func testSingleSpace() {
        // Avec un seul space, next et prev restent au même index
        XCTAssertEqual(SpaceManager.calculateTargetIndex(currentIdx: 0, direction: +1, count: 1), 0)
        XCTAssertEqual(SpaceManager.calculateTargetIndex(currentIdx: 0, direction: -1, count: 1), 0)
    }

    func testTwoSpaces() {
        XCTAssertEqual(SpaceManager.calculateTargetIndex(currentIdx: 0, direction: +1, count: 2), 1)
        XCTAssertEqual(SpaceManager.calculateTargetIndex(currentIdx: 1, direction: +1, count: 2), 0)
    }
}
