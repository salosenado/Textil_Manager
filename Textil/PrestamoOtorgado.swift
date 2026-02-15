//
//  PrestamoOtorgado.swift
//  Textil
//
//  Created by Salomon Senado on 2/14/26.
//
//
//  PrestamoOtorgado.swift
//  Textil
//
//  Created by Salomon Senado on 2/14/26.
//
import Foundation
import SwiftData

@Model
class PrestamoOtorgado {

    // EMPRESA QUE PRESTA
    var empresaNombre: String
    
    // IDENTIFICACIÓN
    var nombre: String
    var apellido: String?
    var esEmpleado: Bool
    var numeroEmpleado: String?

    // CONTACTO
    var direccion: String?
    var telefono: String?
    var correo: String?

    // FINANCIERO
    var montoPrestado: Double
    var tasaAnual: Double
    var plazoMeses: Int

    var capitalPendiente: Double
    var interesesPendientes: Double

    var fechaInicio: Date
    var fechaPrimerPago: Date?
    var periodicidad: String?
    var notas: String?

    var proximoVencimiento: Date?

    @Relationship(deleteRule: .cascade)
    var pagos: [PagoPrestamoOtorgado] = []

    init(
        empresaNombre: String,
        nombre: String,
        apellido: String? = nil,
        esEmpleado: Bool,
        numeroEmpleado: String? = nil,
        direccion: String? = nil,
        telefono: String? = nil,
        correo: String? = nil,
        montoPrestado: Double,
        tasaAnual: Double,
        plazoMeses: Int,
        fechaInicio: Date = Date(),
        fechaPrimerPago: Date? = nil,
        periodicidad: String? = "Mensual",
        notas: String? = nil
    ) {
        self.empresaNombre = empresaNombre
        self.nombre = nombre
        self.apellido = apellido
        self.esEmpleado = esEmpleado
        self.numeroEmpleado = numeroEmpleado
        self.direccion = direccion
        self.telefono = telefono
        self.correo = correo
        self.montoPrestado = montoPrestado
        self.tasaAnual = tasaAnual
        self.plazoMeses = plazoMeses

        self.capitalPendiente = montoPrestado
        self.interesesPendientes = 0

        self.fechaInicio = fechaInicio
        self.fechaPrimerPago = fechaPrimerPago
        self.periodicidad = periodicidad
        self.notas = notas

        self.proximoVencimiento = fechaPrimerPago
    }

}  // 👈 ESTA LLAVE CIERRA LA CLASE


// MARK: - CÁLCULOS

extension PrestamoOtorgado {
    
    var tasaMensual: Double {
        tasaAnual / 12 / 100
    }
    
    var costoDiarioActual: Double {
        (capitalPendiente * tasaAnual / 100) / 365
    }
    
    func interesParaVencimiento(offset: Int) -> Double {
        capitalPendiente * tasaMensual
    }
    
    var totalInteresPagado: Double {
        pagos
            .filter { !$0.eliminado && !$0.esCapital }
            .map { $0.monto }
            .reduce(0, +)
    }
    
    var estaAtrasado: Bool {
        guard let vencimiento = proximoVencimiento else { return false }
        return Date() > vencimiento
    }
}
