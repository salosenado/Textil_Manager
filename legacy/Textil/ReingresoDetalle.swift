//
//  ReingresoDetalle.swift
//  Textil
//
//  Created by Salomon Senado on 2/5/26.
//
//
//  ReingresoDetalle.swift
//  Textil
//

import SwiftData
import Foundation

@Model
class ReingresoDetalle {

    // MARK: - TIPO
    var esServicio: Bool

    // MARK: - RELACIÓN DIRECTA AL INVENTARIO
    @Relationship
    var modelo: Modelo?

    // MARK: - SERVICIO (si aplica)
    var nombreServicio: String?

    // MARK: - CANTIDADES
    var cantidad: Int
    var costoUnitario: Double

    // MARK: - RELACIÓN
    @Relationship(inverse: \Reingreso.detalles)
    var reingreso: Reingreso?

    // MARK: - INIT
    init(
        esServicio: Bool,
        modelo: Modelo?,
        nombreServicio: String?,
        cantidad: Int,
        costoUnitario: Double
    ) {
        self.esServicio = esServicio
        self.modelo = modelo
        self.nombreServicio = nombreServicio
        self.cantidad = cantidad
        self.costoUnitario = costoUnitario
        self.reingreso = nil
    }
}
