//
//  MovimientoPedido.swift
//  Textil
//
//  Created by Salomon Senado on 2/3/26.
//
import SwiftData
import Foundation

@Model
class MovimientoPedido {

    var titulo: String
    var detalle: String
    var fecha: Date
    var usuario: String
    var icono: String
    var colorHex: String

    @Relationship
    var orden: OrdenCliente?

    init(
        titulo: String,
        detalle: String,
        fecha: Date = Date(),
        usuario: String,
        icono: String,
        colorHex: String,
        orden: OrdenCliente? = nil
    ) {
        self.titulo = titulo
        self.detalle = detalle
        self.fecha = fecha
        self.usuario = usuario
        self.icono = icono
        self.colorHex = colorHex
        self.orden = orden
    }
}
