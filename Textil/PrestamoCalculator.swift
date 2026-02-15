//
//  PrestamoCalculator.swift
//  Textil
//
//  Created by Salomon Senado on 2/14/26.
//
import Foundation

struct PrestamoCalculator {

    static func calcularInteresTotal(
        monto: Double,
        tasaAnual: Double,
        plazoMeses: Int,
        fechaInicio: Date,
        primeraFechaPago: Date
    ) -> Double {

        // Base 360
        let interesDiario = (tasaAnual / 100) / 360

        // Días del primer periodo
        let diasPrimerPeriodo = Calendar.current.dateComponents(
            [.day],
            from: fechaInicio,
            to: primeraFechaPago
        ).day ?? 0

        let interesPrimerPeriodo =
            monto * interesDiario * Double(diasPrimerPeriodo)

        // Interés mensual normal
        let interesMensual =
            monto * (tasaAnual / 100) / 12

        // Meses restantes después del primero
        let interesRestante =
            interesMensual * Double(plazoMeses - 1)

        return interesPrimerPeriodo + interesRestante
    }
}
