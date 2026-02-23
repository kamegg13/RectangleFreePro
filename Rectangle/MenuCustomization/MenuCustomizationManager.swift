//
//  MenuCustomizationManager.swift
//  Rectangle
//
//  Pro Feature: Hide/show menu bar actions
//

import Cocoa

class MenuCustomizationManager {

    /// Retourne true si l'action doit être cachée dans le menu
    static func isHidden(_ action: WindowAction) -> Bool {
        guard let hidden = Defaults.hiddenMenuActions.typedValue else { return false }
        return hidden.contains(action.name)
    }

    /// Met à jour la liste des actions cachées
    static func setHidden(_ hidden: Bool, for action: WindowAction) {
        var current = Defaults.hiddenMenuActions.typedValue ?? []
        if hidden {
            if !current.contains(action.name) {
                current.append(action.name)
            }
        } else {
            current.removeAll { $0 == action.name }
        }
        Defaults.hiddenMenuActions.typedValue = current
    }
}
