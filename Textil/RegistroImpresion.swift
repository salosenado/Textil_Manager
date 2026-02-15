//
//  RegistroImpresion.swift
//  Textil
//
//  Created by Salomon Senado on 2/13/26.
//
import Foundation
import SwiftData

@Model
class RegistroImpresion {

    var idReferencia: String
    var fecha: Date
    var usuario: String
    var tipo: String

    init(idReferencia: String,
         fecha: Date,
         usuario: String,
         tipo: String) {

        self.idReferencia = idReferencia
        self.fecha = fecha
        self.usuario = usuario
        self.tipo = tipo
    }
}
