//
//  TipoTela.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//

import SwiftData

@Model
final class TipoTela {

    var nombre: String
    var activo: Bool

    init(nombre: String, activo: Bool = true) {
        self.nombre = nombre
        self.activo = activo
    }
}
