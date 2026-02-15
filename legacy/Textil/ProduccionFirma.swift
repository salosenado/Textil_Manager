//
//  ProduccionFirma.swift
//  Textil
//
//  Created by Salomon Senado on 2/7/26.
//
import SwiftData
import Foundation

@Model
class ProduccionFirma {
    var produccion: Produccion
    var maquilero: String
    var responsable: String
    var firmaMaquilero: Data?
    var firmaResponsable: Data?
    var fecha: Date

    init(
        produccion: Produccion,
        maquilero: String,
        responsable: String,
        firmaMaquilero: Data?,
        firmaResponsable: Data?
    ) {
        self.produccion = produccion
        self.maquilero = maquilero
        self.responsable = responsable
        self.firmaMaquilero = firmaMaquilero
        self.firmaResponsable = firmaResponsable
        self.fecha = Date()
    }
}
