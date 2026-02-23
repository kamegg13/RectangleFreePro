//
//  CustomSizeManager.swift
//  Rectangle
//
//  Pro Feature: Custom window sizes and positions
//

import Foundation

struct CustomWindowSize: Codable, Identifiable {
    let id: UUID
    var name: String
    /// ≤1 = ratio (% de l'écran), >1 = pixels absolus
    var width: Float
    var height: Float
    /// Position X du centre (0.5 = centré, 0 = gauche, 1 = droite)
    var centerX: Float
    /// Position Y du centre (0.5 = centré, 0 = bas, 1 = haut)
    var centerY: Float

    init(id: UUID = UUID(), name: String, width: Float, height: Float, centerX: Float = 0.5, centerY: Float = 0.5) {
        self.id = id
        self.name = name
        self.width = width
        self.height = height
        self.centerX = centerX
        self.centerY = centerY
    }
}
