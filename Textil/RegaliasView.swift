//
//  RegaliasView.swift
//  Textil
//
//  Created by Salomon Senado on 2/11/26.
//
//
//  RegaliasView.swift
//  Textil
//

import SwiftUI
import SwiftData

struct RegaliasView: View {

    @Environment(\.modelContext) private var context

    @Query private var ventas: [VentaCliente]
    @Query private var marcas: [Marca]
    @Query private var pagos: [PagoRegalia]

    var body: some View {

        NavigationStack {

            List {

                ForEach(marcas.filter { $0.activo }) { marca in

                    let resumen = calcularResumen(marca: marca)

                    NavigationLink {
                        RegaliaDetalleView(
                            marca: marca,
                            ventasMarca: resumen.ventas
                        )
                    } label: {

                        VStack(alignment: .leading, spacing: 6) {

                            Text(marca.nombre)
                                .font(.headline)

                            Text("Dueño: \(marca.dueno)")
                                .font(.caption)
                                .foregroundStyle(.secondary)

                            Divider()

                            Text("Piezas: \(resumen.piezas)")
                                .font(.caption)

                            Text("Regalía sin IVA: MX$ \(resumen.totalRegaliaSinIVA.formatoMoneda)")
                                .font(.caption)

                            Text("Regalía con IVA: MX$ \(resumen.totalRegaliaConIVA.formatoMoneda)")
                                .font(.caption)

                            Text("Pagado: MX$ \(resumen.totalPagado.formatoMoneda)")
                                .font(.caption)

                            Divider()

                            Text("Saldo sin IVA: MX$ \(resumen.saldoSinIVA.formatoMoneda)")
                                .font(.headline)
                                .foregroundStyle(
                                    resumen.saldoSinIVA > 0 ? .red : .green
                                )

                            Text("Saldo con IVA: MX$ \(resumen.saldoConIVA.formatoMoneda)")
                                .font(.headline)
                                .foregroundStyle(
                                    resumen.saldoConIVA > 0 ? .red : .green
                                )
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            .navigationTitle("Regalías")
        }
    }

    // 🔥 CÁLCULO CONTABLE CORRECTO (APLICA PORCENTAJE)
    func calcularResumen(marca: Marca) -> (
        piezas: Int,
        totalRegaliaSinIVA: Double,
        totalRegaliaConIVA: Double,
        totalPagado: Double,
        saldoSinIVA: Double,
        saldoConIVA: Double,
        ventas: [VentaCliente]
    ) {

        let ventasEnviadas = ventas.filter {
            $0.mercanciaEnviada && !$0.cancelada
        }

        var piezas = 0
        var totalRegaliaSinIVA: Double = 0
        var totalRegaliaConIVA: Double = 0

        // 🔥 Convertimos porcentaje (String → Double)
        let porcentaje = Double(marca.regaliaPorcentaje) ?? 0
        let factor = porcentaje / 100

        for venta in ventasEnviadas {

            let detallesMarca = venta.detalles.filter {
                $0.marca?.persistentModelID == marca.persistentModelID
            }

            let subtotal = detallesMarca.reduce(0) { parcial, detalle in
                piezas += detalle.cantidad
                return parcial + (Double(detalle.cantidad) * detalle.costoUnitario)
            }

            if subtotal > 0 {

                let totalVenta = venta.aplicaIVA
                    ? subtotal * 1.16
                    : subtotal

                // 🔥 AQUÍ SE APLICA EL %
                totalRegaliaSinIVA += subtotal * factor
                totalRegaliaConIVA += totalVenta * factor
            }
        }

        let pagosMarca = pagos.filter {
            $0.marca?.persistentModelID == marca.persistentModelID
        }

        let totalPagado = pagosMarca.reduce(0) { $0 + $1.monto }

        let saldoSinIVA = totalRegaliaSinIVA - totalPagado
        let saldoConIVA = totalRegaliaConIVA - totalPagado

        return (
            piezas,
            totalRegaliaSinIVA,
            totalRegaliaConIVA,
            totalPagado,
            saldoSinIVA,
            saldoConIVA,
            ventasEnviadas
        )
    }
}
