//
//  PagoComision.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//


import SwiftData
import Foundation

@Model
class PagoComision {

    var fecha: Date
    var monto: Double

    @Relationship
    var agente: Agente?

    init(
        fecha: Date = Date(),
        monto: Double,
        agente: Agente?
    ) {
        self.fecha = fecha
        self.monto = monto
        self.agente = agente
    }
}
