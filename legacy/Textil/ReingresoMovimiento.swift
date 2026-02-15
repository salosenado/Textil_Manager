//
//  ReingresoMovimiento.swift
//  Textil
//
//  Created by Salomon Senado on 2/5/26.
//
import SwiftData
import Foundation

@Model
class ReingresoMovimiento {

    var titulo: String
    var usuario: String
    var icono: String
    var color: String
    var fecha: Date

    @Relationship(inverse: \Reingreso.movimientos)
    var reingreso: Reingreso?

    init(
        titulo: String,
        usuario: String,
        icono: String,
        color: String,
        reingreso: Reingreso
    ) {
        self.titulo = titulo
        self.usuario = usuario
        self.icono = icono
        self.color = color
        self.fecha = Date()              // 👈 OBLIGATORIO
        self.reingreso = reingreso
    }
}
