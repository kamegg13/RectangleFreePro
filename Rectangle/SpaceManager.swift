//
//  SpaceManager.swift
//  Rectangle
//
//  Pro Feature: Move windows between Mission Control spaces using private CGSSpace API
//

import Foundation
import CoreGraphics

// MARK: - CGSSpace private API declarations

typealias CGSConnection = UInt32

@_silgen_name("CGSMainConnectionID")
func CGSMainConnectionID() -> CGSConnection

@_silgen_name("CGSCopyManagedDisplaySpaces")
func CGSCopyManagedDisplaySpaces(_ conn: CGSConnection) -> CFArray

@_silgen_name("CGSMoveWindowsToManagedSpace")
func CGSMoveWindowsToManagedSpace(_ conn: CGSConnection, _ windows: CFArray, _ space: Int)

@_silgen_name("CGSGetWindowWorkspace")
func CGSGetWindowWorkspace(_ conn: CGSConnection, _ windowId: CGWindowID, _ space: UnsafeMutablePointer<Int>) -> CGError

// MARK: - SpaceManager

class SpaceManager {

    /// Déplace une fenêtre vers l'espace next (+1) ou prev (-1)
    static func moveWindow(windowId: CGWindowID, direction: Int) {
        let conn = CGSMainConnectionID()

        // Récupérer la liste des spaces de tous les displays
        let rawSpaces = CGSCopyManagedDisplaySpaces(conn) as! [[String: Any]]

        // Extraire tous les space IDs dans l'ordre
        var allSpaceIds: [Int] = []
        for display in rawSpaces {
            if let spaces = display["Spaces"] as? [[String: Any]] {
                for space in spaces {
                    if let spaceId = space["id64"] as? Int {
                        allSpaceIds.append(spaceId)
                    }
                }
            }
        }

        guard !allSpaceIds.isEmpty else { return }

        // Trouver le space actuel de la fenêtre
        var currentSpace: Int = 0
        _ = CGSGetWindowWorkspace(conn, windowId, &currentSpace)

        guard let currentIdx = allSpaceIds.firstIndex(of: currentSpace) else { return }

        // Calculer le prochain space (avec wrap-around)
        let targetIdx = (currentIdx + direction + allSpaceIds.count) % allSpaceIds.count
        let targetSpace = allSpaceIds[targetIdx]

        // Déplacer la fenêtre vers le space cible
        let windowArray = [windowId] as CFArray
        CGSMoveWindowsToManagedSpace(conn, windowArray, targetSpace)
    }

    /// Retourne l'index next (+1) ou previous (-1) dans une liste de spaces
    /// Utilisé dans les tests unitaires pour tester la logique sans appels système
    static func calculateTargetIndex(currentIdx: Int, direction: Int, count: Int) -> Int {
        guard count > 0 else { return 0 }
        return (currentIdx + direction + count) % count
    }
}
