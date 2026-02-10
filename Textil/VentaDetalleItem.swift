//
//  VentaDetalleItem.swift
//  Textil
//
//  Created by Salomon Senado on 2/2/26.
//
//
//  VentaDetalleItem.swift
//  Textil
//

import Foundation

struct VentaDetalleItem: Identifiable {
    let id = UUID()
    var articulo: String = ""
    var departamento: String = ""
    var linea: String = ""
    var modelo: String = ""
    var color: String = ""
    var talla: String = ""
    var unidad: String = ""
    var cantidad: Int = 0
    var costo: Double = 0

    var total: Double {
        Double(cantidad) * costo
    }
}
