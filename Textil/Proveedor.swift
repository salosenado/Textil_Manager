//
//  Proveedor.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  Proveedor.swift
//  Textil
//

import Foundation
import SwiftData

@Model
class Proveedor {

    // Proveedor
    var nombre: String
    var contacto: String
    var rfc: String
    var plazoPagoDias: Int

    // Dirección
    var calle: String
    var numeroExterior: String
    var numeroInterior: String
    var colonia: String
    var ciudad: String
    var estado: String
    var codigoPostal: String

    // Contacto
    var telefonoPrincipal: String
    var telefonoSecundario: String
    var email: String

    var activo: Bool

    init() {
        self.nombre = ""
        self.contacto = ""
        self.rfc = ""
        self.plazoPagoDias = 0
        self.calle = ""
        self.numeroExterior = ""
        self.numeroInterior = ""
        self.colonia = ""
        self.ciudad = ""
        self.estado = ""
        self.codigoPostal = ""
        self.telefonoPrincipal = ""
        self.telefonoSecundario = ""
        self.email = ""
        self.activo = true
    }
}
