//
//  VentaClienteDetalle.swift
//  Textil
//
//  Created by Salomon Senado on 2/2/26.
//


import SwiftData
import Foundation

@Model
class VentaClienteDetalle: Identifiable {

    @Attribute(.unique)
    var id: UUID = UUID()

    var modeloNombre: String
    var cantidad: Int
    var costoUnitario: Double
    var unidad: String

    @Relationship
    var venta: VentaCliente?

    // auditoría
    var fechaEliminacion: Date?

    init(
        modeloNombre: String,
        cantidad: Int,
        costoUnitario: Double,
        unidad: String,
        venta: VentaCliente?
    ) {
        self.modeloNombre = modeloNombre
        self.cantidad = cantidad
        self.costoUnitario = costoUnitario
        self.unidad = unidad
        self.venta = venta
    }
}
