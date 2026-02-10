//
//  CostoGeneralInsumo.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//

import SwiftData
import Foundation

@Model
class CostoGeneralInsumo {

    var nombre: String
    var cantidad: Double
    var costoUnitario: Double

    // 🔴 RELACIÓN INVERSA
    var costoGeneral: CostoGeneralEntity?

    init(
        nombre: String,
        cantidad: Double,
        costoUnitario: Double
    ) {
        self.nombre = nombre
        self.cantidad = cantidad
        self.costoUnitario = costoUnitario
    }

    var total: Double {
        cantidad * costoUnitario
    }
}
