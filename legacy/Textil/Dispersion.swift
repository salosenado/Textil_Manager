//
//  Dispersion.swift
//  Textil
//
//  Created by Salomon Senado on 2/13/26.
//


import Foundation
import SwiftData

@Model
class Dispersion {

    var wara: String
    var empresa: String

    var monto: Double
    var porcentajeComision: Double

    var comision: Double
    var iva: Double
    var neto: Double

    var fechaMovimiento: Date

    var concepto: String
    var observaciones: String
    
    @Relationship(deleteRule: .cascade)
    var salidas: [DispersionSalida] = []

    init(
        wara: String,
        empresa: String,
        monto: Double,
        porcentajeComision: Double,
        comision: Double,
        iva: Double,
        neto: Double,
        fechaMovimiento: Date,
        concepto: String,
        observaciones: String
    ) {
        self.wara = wara
        self.empresa = empresa
        self.monto = monto
        self.porcentajeComision = porcentajeComision
        self.comision = comision
        self.iva = iva
        self.neto = neto
        self.fechaMovimiento = fechaMovimiento
        self.concepto = concepto
        self.observaciones = observaciones
    }
}
