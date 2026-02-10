//
//  InventarioHelper.swift
//  Textil
//
//  Created by Salomon Senado on 2/2/26.
//


import SwiftData

struct InventarioHelper {

    static func inventarioDisponible(
        modelo: Modelo,
        produccion: [ReciboDetalle],
        compras: [ReciboCompraDetalle],
        ventas: [VentaClienteDetalle]
    ) -> Int {

        let ingresosProduccion = produccion
            .filter { $0.modelo == modelo.nombre && $0.fechaEliminacion == nil }
            .reduce(0) { $0 + $1.pzPrimera }

        let ingresosCompras = compras
            .filter { $0.concepto == modelo.nombre && $0.fechaEliminacion == nil }
            .reduce(0) { $0 + Int($1.monto) }

        let egresosVentas = ventas
            .filter { $0.modeloNombre == modelo.nombre && $0.fechaEliminacion == nil }
            .reduce(0) { $0 + $1.cantidad }

        return ingresosProduccion + ingresosCompras - egresosVentas
    }
}
