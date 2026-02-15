//
//  DispersionSalida.swift
//  Textil
//
//  Created by Salomon Senado on 2/13/26.
//


import Foundation
import SwiftData

@Model
class DispersionSalida {

    var concepto: String
    var nombre: String
    var cuenta: String
    var monto: Double

    init(concepto: String,
         nombre: String,
         cuenta: String,
         monto: Double) {

        self.concepto = concepto
        self.nombre = nombre
        self.cuenta = cuenta
        self.monto = monto
    }
}
