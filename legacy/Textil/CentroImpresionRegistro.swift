//
//  CentroImpresionRegistro.swift
//  Textil
//
//  Created by Salomon Senado on 2/12/26.
//


import SwiftData
import Foundation

@Model
class CentroImpresionRegistro {

    var idReferencia: String
    var empresa: String
    var responsable: String
    var proveedor: String
    var firmaResponsableData: Data?
    var firmaProveedorData: Data?
    var fechaImpresion: Date

    init(
        idReferencia: String,
        empresa: String,
        responsable: String,
        proveedor: String,
        firmaResponsableData: Data?,
        firmaProveedorData: Data?
    ) {
        self.idReferencia = idReferencia
        self.empresa = empresa
        self.responsable = responsable
        self.proveedor = proveedor
        self.firmaResponsableData = firmaResponsableData
        self.firmaProveedorData = firmaProveedorData
        self.fechaImpresion = Date()
    }
}
