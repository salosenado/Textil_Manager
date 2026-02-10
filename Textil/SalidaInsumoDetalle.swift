//
//  SalidaInsumoDetalle.swift
//  Textil
//
//  Created by Salomon Senado on 2/3/26.
//
//
//  SalidaInsumoDetalle.swift
//  Textil
//
import SwiftData
import Foundation

@Model
class SalidaInsumoDetalle {

    var esServicio: Bool

    // MODELO (si NO es servicio)
    var modeloNombre: String?

    // SERVICIO (si ES servicio)
    var nombreServicio: String?

    var cantidad: Int
    var costoUnitario: Double

    @Relationship(inverse: \SalidaInsumo.detalles)
    var salida: SalidaInsumo?

    init(
        esServicio: Bool,
        modeloNombre: String? = nil,
        nombreServicio: String? = nil,
        cantidad: Int = 1,
        costoUnitario: Double = 0,
        salida: SalidaInsumo? = nil
    ) {
        self.esServicio = esServicio
        self.modeloNombre = modeloNombre
        self.nombreServicio = nombreServicio
        self.cantidad = cantidad
        self.costoUnitario = costoUnitario
        self.salida = salida
    }
}
