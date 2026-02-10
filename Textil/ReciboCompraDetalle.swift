//
//  ReciboCompraDetalle.swift
//  Textil
//
//  Created by Salomon Senado on 2/1/26.
//
//
//  ReciboCompraDetalle.swift
//  Textil
//
//  Created by Salomon Senado on 2/1/26.
//

import SwiftData
import Foundation

@Model
class ReciboCompraDetalle {

    // MARK: - DATOS

    /// Tipo de movimiento (ej. "Recepción")
    var concepto: String

    /// Cantidad recibida
    var monto: Double

    /// Observaciones libres
    var observaciones: String = ""

    // 🔥 NUEVO: CLAVE PARA INVENTARIOS POR MODELO
    /// Modelo recibido (ej. Mezclilla 501, Servicio Corte)
    var modelo: String

    /// Descripción / artículo
    var articulo: String

    // MARK: - RELACIONES

    @Relationship
    var recibo: ReciboProduccion?

    @Relationship
    var ordenCompra: OrdenCompra?

    // MARK: - AUDITORÍA

    var usuarioEliminacion: String?
    var fechaEliminacion: Date?

    // MARK: - INIT

    init(
        concepto: String,
        monto: Double,
        modelo: String,
        articulo: String,
        recibo: ReciboProduccion?,
        ordenCompra: OrdenCompra?
    ) {
        self.concepto = concepto
        self.monto = monto
        self.modelo = modelo
        self.articulo = articulo
        self.recibo = recibo
        self.ordenCompra = ordenCompra
    }
}
