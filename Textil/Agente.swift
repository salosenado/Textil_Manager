//
//  Agente.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  Agente.swift
//  Textil
//

import SwiftData

@Model
class Agente {

    var nombre: String
    var apellido: String
    var comision: String   // ← STRING, NO Double
    var telefono: String
    var email: String
    var activo: Bool

    init() {
        self.nombre = ""
        self.apellido = ""
        self.comision = ""
        self.telefono = ""
        self.email = ""
        self.activo = true
    }
}
