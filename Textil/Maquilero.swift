//
//  Maquilero.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  Maquilero.swift
//  Textil
//

import SwiftData

@Model
class Maquilero {

    // Información
    var nombre: String
    var contacto: String

    // Dirección
    var calle: String
    var numeroExterior: String
    var numeroInterior: String
    var colonia: String
    var ciudad: String
    var estado: String
    var codigoPostal: String

    // Teléfonos
    var telefonoPrincipal: String
    var telefonoSecundario: String

    var activo: Bool

    init(
        nombre: String = "",
        contacto: String = "",
        calle: String = "",
        numeroExterior: String = "",
        numeroInterior: String = "",
        colonia: String = "",
        ciudad: String = "",
        estado: String = "",
        codigoPostal: String = "",
        telefonoPrincipal: String = "",
        telefonoSecundario: String = "",
        activo: Bool = true
    ) {
        self.nombre = nombre
        self.contacto = contacto
        self.calle = calle
        self.numeroExterior = numeroExterior
        self.numeroInterior = numeroInterior
        self.colonia = colonia
        self.ciudad = ciudad
        self.estado = estado
        self.codigoPostal = codigoPostal
        self.telefonoPrincipal = telefonoPrincipal
        self.telefonoSecundario = telefonoSecundario
        self.activo = activo
    }
}
