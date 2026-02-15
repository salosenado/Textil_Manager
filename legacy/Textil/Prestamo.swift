//
//  Prestamo.swift
//  Textil
//
//  Created by Salomon Senado on 2/14/26.
//
import Foundation
import SwiftData

@Model
class Prestamo {

    // =========================
    // IDENTIFICACIÓN CLIENTE
    // =========================

    var nombre: String
    var esPersonaMoral: Bool
    var representante: String
    var telefono: String
    var correo: String
    var notas: String

    // =========================
    // CONDICIONES FINANCIERAS
    // =========================

    var tasaAnual: Double
    var montoPrestado: Double
    var plazoMeses: Int
    var fechaInicio: Date
    var primeraFechaPago: Date

    // =========================
    // ESTADO FINANCIERO
    // =========================

    var capitalPendiente: Double
    var interesesPendientes: Double

    // =========================
    // RELACIONES
    // =========================

    @Relationship(deleteRule: .nullify)
    var empresa: Empresa   // 👈 NUEVA RELACIÓN

    @Relationship(deleteRule: .cascade)
    var pagos: [PagoPrestamo] = []

    // =========================
    // INIT
    // =========================

    init(
        nombre: String,
        esPersonaMoral: Bool,
        tasaAnual: Double,
        montoPrestado: Double,
        plazoMeses: Int,
        telefono: String,
        correo: String,
        representante: String,
        notas: String,
        primeraFechaPago: Date,
        fechaInicio: Date = Date(),
        empresa: Empresa   // 👈 NUEVO PARÁMETRO
    ) {

        self.nombre = nombre
        self.esPersonaMoral = esPersonaMoral
        self.tasaAnual = tasaAnual
        self.montoPrestado = montoPrestado
        self.plazoMeses = plazoMeses
        self.telefono = telefono
        self.correo = correo
        self.representante = representante
        self.notas = notas
        self.primeraFechaPago = primeraFechaPago
        self.fechaInicio = fechaInicio
        self.empresa = empresa   // 👈 ASIGNACIÓN

        self.capitalPendiente = montoPrestado

        let totalIntereses = PrestamoCalculator.calcularInteresTotal(
            monto: montoPrestado,
            tasaAnual: tasaAnual,
            plazoMeses: plazoMeses,
            fechaInicio: fechaInicio,
            primeraFechaPago: primeraFechaPago
        )

        self.interesesPendientes = totalIntereses
    }

    // =========================
    // PROPIEDADES FINANCIERAS
    // =========================

    var estaLiquidado: Bool {
        capitalPendiente <= 0 && interesesPendientes <= 0
    }

    var interesDiario: Double {
        (tasaAnual / 100) / 360
    }

    var costoDiarioActual: Double {
        capitalPendiente * interesDiario
    }

    var pagoMensualInteres: Double {
        capitalPendiente * (tasaAnual / 100) / 12
    }

    var interesPrimerPeriodo: Double {

        let dias = Calendar.current.dateComponents(
            [.day],
            from: fechaInicio,
            to: primeraFechaPago
        ).day ?? 0

        return capitalPendiente * interesDiario * Double(dias)
    }

    var totalInteresPagado: Double {
        pagos
            .filter { !$0.esCapital }
            .map { $0.monto }
            .reduce(0, +)
    }

    func interesParaVencimiento(offset: Int) -> Double {
        offset == 0 ? interesPrimerPeriodo : pagoMensualInteres
    }

    var mesesVencidos: Int {

        let hoy = Calendar.current.startOfDay(for: Date())
        let primer = Calendar.current.startOfDay(for: primeraFechaPago)

        if hoy <= primer { return 0 }

        return Calendar.current.dateComponents(
            [.month],
            from: primer,
            to: hoy
        ).month ?? 0
    }

    var proximoVencimiento: Date? {
        Calendar.current.date(
            byAdding: .month,
            value: mesesVencidos,
            to: primeraFechaPago
        )
    }

    var interesEsperadoHastaHoy: Double {

        if mesesVencidos == 0 { return 0 }

        var total = interesPrimerPeriodo

        if mesesVencidos > 1 {
            total += Double(mesesVencidos - 1) * pagoMensualInteres
        }

        return total
    }

    var estaAtrasado: Bool {

        guard let vencimiento = proximoVencimiento else { return false }

        let hoy = Calendar.current.startOfDay(for: Date())
        let fechaVenc = Calendar.current.startOfDay(for: vencimiento)

        if hoy > fechaVenc {
            return totalInteresPagado < interesEsperadoHastaHoy
        }

        return false
    }

    var mesesDeAtraso: Int {

        if !estaAtrasado { return 0 }

        let diferencia = interesEsperadoHastaHoy - totalInteresPagado

        guard pagoMensualInteres > 0 else { return 0 }

        return Int(ceil(diferencia / pagoMensualInteres))
    }

    var fechaInicioFormateada: String {
        fechaInicio.formatted(.dateTime.month(.abbreviated).day().year())
    }

    var primeraFechaPagoFormateada: String {
        primeraFechaPago.formatted(.dateTime.month(.abbreviated).day().year())
    }

    var proximoVencimientoFormateado: String? {
        guard let fecha = proximoVencimiento else { return nil }
        return fecha.formatted(.dateTime.month(.abbreviated).day().year())
    }

    var porcentajePagadoCapital: Double {
        guard montoPrestado > 0 else { return 0 }
        let pagado = montoPrestado - capitalPendiente
        return (pagado / montoPrestado) * 100
    }
}
