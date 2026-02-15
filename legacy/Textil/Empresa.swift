//
//  Empresa.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//

//
//  Empresa.swift
//  Textil
//

import Foundation
import SwiftData

@Model
class Empresa {

    var nombre: String
    var rfc: String
    var direccion: String
    var telefono: String

    // Logo
    var logoData: Data?

    var activo: Bool

    init() {
        self.nombre = ""
        self.rfc = ""
        self.direccion = ""
        self.telefono = ""
        self.logoData = nil
        self.activo = true
    }
}
