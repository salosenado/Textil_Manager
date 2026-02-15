//
//  Servicio.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  Servicio.swift
//  ProduccionTextilClean
//
//  Created by Salomon Senado on 1/29/26.
//

import SwiftData
import Foundation

@Model
class Servicio {

    var nombre: String
    var plazoPagoDias: Int
    var activo: Bool
    var fechaRegistro: Date

    init(
        nombre: String = "",
        plazoPagoDias: Int = 0,
        activo: Bool = true,
        fechaRegistro: Date = .now
    ) {
        self.nombre = nombre
        self.plazoPagoDias = plazoPagoDias
        self.activo = activo
        self.fechaRegistro = fechaRegistro
    }
}
