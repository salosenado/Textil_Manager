//
//  ReciboProduccion.swift
//  Textil
//
//  Created by Salomon Senado on 1/31/26.
//
//
//  ReciboProduccion.swift
//  Textil
//
//  Created by Salomon Senado on 1/31/26.
//

import SwiftData
import Foundation

@Model
class ReciboProduccion {

    // MARK: - RELACIONES

    // 🔵 PRODUCCIÓN (EXISTENTE – NO SE TOCA)
    @Relationship
    var produccion: Produccion?

    // 🟢 COMPRAS / SERVICIOS (EXISTENTE)
    @Relationship
    var ordenCompra: OrdenCompra?

    // 🔵 DETALLES PRODUCCIÓN
    @Relationship(deleteRule: .cascade)
    var detalles: [ReciboDetalle] = []

    // 🔵 PAGOS
    @Relationship(deleteRule: .cascade)
    var pagos: [PagoRecibo] = []

    // MARK: - DATOS

    var fechaRecibo: Date
    var observaciones: String = ""

    // 🧾 FACTURA / NOTA  ✅ NUEVO (NO ROMPE NADA)
    var numeroFacturaNota: String?

    // MARK: - ESTADO

    var cancelado: Bool = false
    var fechaCancelacion: Date?

    // MARK: - INIT (SE RESPETA EL EXISTENTE)

    init(
        produccion: Produccion?,
        fechaRecibo: Date = Date(),
        ordenCompra: OrdenCompra? = nil
    ) {
        self.produccion = produccion
        self.fechaRecibo = fechaRecibo
        self.ordenCompra = ordenCompra
    }
}
