//
//  Cliente.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  Cliente.swift
//  Textil
//

import SwiftData

@Model
class Cliente {

    // Información
    var nombreComercial: String
    var razonSocial: String
    var rfc: String

    // Crédito
    var plazoDias: Int
    var limiteCredito: Double

    // Contacto
    var contacto: String
    var telefono: String
    var email: String

    // Dirección
    var calle: String
    var numero: String
    var colonia: String
    var ciudad: String
    var estado: String
    var pais: String
    var codigoPostal: String

    // Otros
    var observaciones: String
    var activo: Bool

    init() {
        self.nombreComercial = ""
        self.razonSocial = ""
        self.rfc = ""
        self.plazoDias = 0
        self.limiteCredito = 0
        self.contacto = ""
        self.telefono = ""
        self.email = ""
        self.calle = ""
        self.numero = ""
        self.colonia = ""
        self.ciudad = ""
        self.estado = ""
        self.pais = "México"
        self.codigoPostal = ""
        self.observaciones = ""
        self.activo = true
    }
}
