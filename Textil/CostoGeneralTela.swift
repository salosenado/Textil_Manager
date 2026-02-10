//
//  CostoGeneralTela.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
import SwiftData
import Foundation

@Model
class CostoGeneralTela {

    var nombre: String
    var consumo: Double
    var precioUnitario: Double

    // 🔴 RELACIÓN INVERSA
    var costoGeneral: CostoGeneralEntity?

    init(
        nombre: String,
        consumo: Double,
        precioUnitario: Double
    ) {
        self.nombre = nombre
        self.consumo = consumo
        self.precioUnitario = precioUnitario
    }

    var total: Double {
        consumo * precioUnitario
    }
}
