//
//  PagoPrestamoOtorgado.swift
//  Textil
//
//  Created by Salomon Senado on 2/14/26.
//
//
//  PagoPrestamoOtorgado.swift
//  Textil
//
//  Created by Salomon Senado on 2/14/26.
//

import Foundation
import SwiftData

@Model
final class PagoPrestamoOtorgado {

    var monto: Double
    var esCapital: Bool
    var usuario: String
    var fecha: Date
    var eliminado: Bool
    
    // DATOS PERSONALES
    var apellido: String?
    var direccion: String?
    var telefono: String?
    var correo: String?

    // CONFIGURACIÓN FINANCIERA
    var fechaPrimerPago: Date?
    var periodicidad: String?


    init(
        monto: Double,
        esCapital: Bool,
        usuario: String,
        fecha: Date = Date(),
        eliminado: Bool = false
    ) {
        self.monto = monto
        self.esCapital = esCapital
        self.usuario = usuario
        self.fecha = fecha
        self.eliminado = eliminado
    }
}
