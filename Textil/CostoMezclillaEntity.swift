//
//  CostoMezclillaEntity.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  CostoMezclillaEntity.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//

import Foundation
import SwiftData

@Model
final class CostoMezclillaEntity {

    // MARK: - Identificación
    var modelo: String
    var tela: String
    var fecha: Date

    // MARK: - Tela
    var costoTela: Double
    var consumoTela: Double

    // MARK: - Poquetín
    var costoPoquetin: Double
    var consumoPoquetin: Double

    // MARK: - Procesos / Habilitación
    var maquila: Double
    var lavanderia: Double
    var cierre: Double
    var boton: Double
    var remaches: Double
    var etiquetas: Double
    var fleteYCajas: Double

    // MARK: - Totales (NO se guardan, se calculan)
    var totalTela: Double {
        costoTela * consumoTela
    }

    var totalPoquetin: Double {
        costoPoquetin * consumoPoquetin
    }

    var totalProcesos: Double {
        maquila
        + lavanderia
        + cierre
        + boton
        + remaches
        + etiquetas
        + fleteYCajas
    }

    var total: Double {
        totalTela + totalPoquetin + totalProcesos
    }

    var totalConGastos: Double {
        total * 1.15
    }

    // MARK: - Initializer (OBLIGATORIO y ÚNICO)
    init(
        modelo: String,
        tela: String,
        fecha: Date = .now,
        costoTela: Double,
        consumoTela: Double,
        costoPoquetin: Double,
        consumoPoquetin: Double,
        maquila: Double,
        lavanderia: Double,
        cierre: Double,
        boton: Double,
        remaches: Double,
        etiquetas: Double,
        fleteYCajas: Double
    ) {
        self.modelo = modelo
        self.tela = tela
        self.fecha = fecha
        self.costoTela = costoTela
        self.consumoTela = consumoTela
        self.costoPoquetin = costoPoquetin
        self.consumoPoquetin = consumoPoquetin
        self.maquila = maquila
        self.lavanderia = lavanderia
        self.cierre = cierre
        self.boton = boton
        self.remaches = remaches
        self.etiquetas = etiquetas
        self.fleteYCajas = fleteYCajas
    }
}
