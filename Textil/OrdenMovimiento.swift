//
//  OrdenMovimiento.swift
//  Textil
//
//  Created by Salomon Senado on 1/31/26.
//

import SwiftData
import Foundation

@Model
class OrdenMovimiento: Identifiable {

    var movimiento: String
    var fecha: Date

    init(movimiento: String, fecha: Date = Date()) {
        self.movimiento = movimiento
        self.fecha = fecha
    }
}
