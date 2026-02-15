//
//  Produccion.swift
//  Textil
//
//  Created by Salomon Senado on 1/30/26.
//
import SwiftData
import Foundation

@Model
class Produccion {

    var detalle: OrdenClienteDetalle?
    var recibos: [ReciboProduccion] = []

    var maquilero: String = ""
    var pzCortadas: Int = 0
    var costoMaquila: Double = 0

    var cancelada: Bool = false
    var fechaCancelacion: Date?
    var usuarioCancelacion: String?

    var ordenMaquila: String?
    var fechaOrdenMaquila: Date?

    init(
        detalle: OrdenClienteDetalle? = nil,
        maquilero: String = "",
        pzCortadas: Int = 0,
        costoMaquila: Double = 0
    ) {
        self.detalle = detalle
        self.maquilero = maquilero
        self.pzCortadas = pzCortadas
        self.costoMaquila = costoMaquila
    }
}
