//
//  PagoPrestamo.swift
//  Textil
//
//  Created by Salomon Senado on 2/14/26.
//
//
//  PagoPrestamo.swift
//  Textil
//

import Foundation
import SwiftData

@Model
class PagoPrestamo {

    var monto: Double
    var esCapital: Bool
    var usuario: String
    var fecha: Date
    var eliminado: Bool   // 👈 NUEVO CAMPO

    init(
        monto: Double,
        esCapital: Bool,
        usuario: String,
        fecha: Date = Date(),
        eliminado: Bool = false   // 👈 DEFAULT
    ) {
        self.monto = monto
        self.esCapital = esCapital
        self.usuario = usuario
        self.fecha = fecha
        self.eliminado = eliminado
    }
}
