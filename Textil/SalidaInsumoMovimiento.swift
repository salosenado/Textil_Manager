//
//  SalidaInsumoMovimiento.swift
//  Textil
//
//  Created by Salomon Senado on 2/4/26.
//


import SwiftData
import Foundation

@Model
class SalidaInsumoMovimiento {

    var titulo: String
    var usuario: String
    var icono: String
    var color: String
    var fecha: Date = Date()

    @Relationship
    var salida: SalidaInsumo?

    init(
        titulo: String,
        usuario: String,
        icono: String,
        color: String,
        salida: SalidaInsumo
    ) {
        self.titulo = titulo
        self.usuario = usuario
        self.icono = icono
        self.color = color
        self.salida = salida
    }
}
