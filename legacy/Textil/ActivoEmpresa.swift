//
//  ActivoEmpresa.swift
//  Textil
//
//  Created by Salomon Senado on 2/10/26.
//
//
//  ActivoEmpresa.swift
//  Textil
//

import SwiftData
import Foundation

@Model
class ActivoEmpresa {

    // =========================
    // 📦 DATOS PRINCIPALES
    // =========================
    var articulo: String
    var fechaCompra: Date
    var cantidad: Int
    var costoUnitario: Double
    var costoTotal: Double

    // =========================
    // 📍 UBICACIÓN
    // =========================
    var ubicacion: String   // 👈 NUEVO CAMPO

    // =========================
    // 🔗 RELACIÓN
    // =========================
    var empresa: Empresa?

    // =========================
    // 💰 VENTA
    // =========================
    var vendido: Bool = false
    var precioVenta: Double?
    var fechaVenta: Date?

    // =========================
    // 📊 UTILIDAD (calculada)
    // =========================
    var utilidad: Double {
        guard let precioVenta else { return 0 }
        return precioVenta - costoTotal
    }

    // =========================
    // INIT
    // =========================
    init(
        articulo: String,
        fechaCompra: Date,
        cantidad: Int,
        costoUnitario: Double,
        empresa: Empresa?,
        ubicacion: String      // 👈 NUEVO PARÁMETRO
    ) {
        self.articulo = articulo
        self.fechaCompra = fechaCompra
        self.cantidad = cantidad
        self.costoUnitario = costoUnitario
        self.costoTotal = Double(cantidad) * costoUnitario
        self.empresa = empresa
        self.ubicacion = ubicacion   // 👈 ASIGNACIÓN
    }
}
