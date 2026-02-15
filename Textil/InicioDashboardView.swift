//
//  InicioDashboardView.swift
//  Textil
//
//  Created by Salomon Senado on 2/13/26.
//
//
//  InicioDashboardView.swift
//  Textil
//

import SwiftUI

struct InicioDashboardView: View {

    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {

        ScrollView {

            VStack(spacing: 30) {

                // =========================
                // HEADER
                // =========================

                VStack(spacing: 8) {

                    Text("Bienvenido a")
                        .font(.headline)
                        .foregroundColor(.secondary)

                    Text("Textil Manager")
                        .font(.largeTitle.bold())
                        .foregroundColor(.primary)

                    if let nombre = authVM.perfil?.nombre {
                        Text(nombre)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                // =========================
                // ACCESOS RÁPIDOS
                // =========================

                Text("Accesos rápidos")
                    .font(.title3.bold())
                    .frame(maxWidth: .infinity, alignment: .leading)

                LazyVGrid(columns: [
                    GridItem(.flexible()),
                    GridItem(.flexible())
                ], spacing: 20) {

                    // =========================
                    // ORDEN ALFABÉTICO
                    // =========================

                    acceso("Activos", "building.2") { ActivosEmpresaView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("Ajustes", "gear") { AjustesView() }

                    acceso("Bancos", "building.columns") { MovimientosBancosView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("Catálogos", "square.grid.2x2") { CatalogosView() }

                    acceso("Centro Impresión", "printer.fill") { CentroImpresionView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("Comisiones", "person.badge.clock.fill") { ComisionesView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("Compras Clientes", "cart") { ComprasClientesListView() }

                    acceso("Compras Insumos", "cart.badge.plus") { ComprasInsumosListView() }

                    acceso("Contacto", "phone.fill") { ContactoView() }

                    acceso("Costeos", "chart.line.uptrend.xyaxis") { CosteosListView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("Costos", "dollarsign.circle") { CostosGeneralListView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("Creditos", "arrow.down.circle.fill") { PrestamosView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("CxC", "tray.and.arrow.down.fill") { CuentasPorCobrarView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("CxP", "tray.full.fill") { CuentasPorPagarView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("Diseño & Trazo", "pencil.and.ruler.fill") { DisenoTrazoView() }

                    acceso("Dispersión", "arrow.triangle.2.circlepath.circle.fill") { DispersionesView() }
                        .mostrarSi(authVM.esSuperAdmin)

                    acceso("Flujo", "dollarsign.circle.fill") { FlujoEfectivoView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("Inventarios", "archivebox") { InventariosView() }

                    acceso("Licencia", "key.fill") { LicenciaView() }

                    acceso("Mezclilla", "scissors") { CostosMezclillaListView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("Órdenes", "doc.text") { OrdenesClientesView() }

                    acceso("Perfil", "person.circle") { PerfilView() }

                    acceso("Producción", "gearshape.2") { ProduccionListView() }

                    acceso("Préstamos Otorgados", "arrow.up.circle.fill") { PrestamosOtorgadosView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("Recibo Compras", "shippingbox") { ReciboComprasServiciosListView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("Recibo Producción", "shippingbox") { ReciboListView() }

                    acceso("Reingresos", "arrow.down.square") { ReingresosListView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("Regalías", "crown.fill") { RegaliasView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("Resumen Compras Clientes", "doc.text.magnifyingglass") { ResumenComprasClientesView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("Resumen Compras Insumos", "shippingbox.fill") { ResumenComprasInsumosView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("Resumen Compras Servicios", "wrench.and.screwdriver.fill") { ResumenComprasServiciosView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("Resumen Producción", "chart.bar.fill") { ResumenProduccionView() }
                        .mostrarSi(authVM.esSuperAdmin)

                    acceso("Saldos Facturas Adelantadas", "doc.text.fill") { SaldosFacturasView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("Salidas", "arrow.up.square") { SalidasInsumosListView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("Servicios", "wrench.and.screwdriver") { SolicitudesServiciosListView() }
                        .mostrarSi(authVM.esAdmin)

                    acceso("Usuarios", "person.3.fill") { UsuariosAdminView() }
                        .mostrarSi(authVM.esSuperAdmin)

                    acceso("Ventas", "creditcard") { VentasClientesListView() }
                        .mostrarSi(authVM.esAdmin)
                }

                Color.clear.frame(height: 60)
            }
            .padding()
        }
        .navigationTitle("Inicio")
    }

    // =========================
    // TARJETA ACCESO
    // =========================

    func acceso<Destino: View>(
        _ titulo: String,
        _ icono: String,
        @ViewBuilder destino: @escaping () -> Destino
    ) -> some View {

        NavigationLink {
            destino()
        } label: {

            VStack(spacing: 14) {

                Image(systemName: icono)
                    .font(.title2.bold())
                    .foregroundColor(.white)

                Text(titulo)
                    .font(.subheadline.bold())
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                LinearGradient(
                    colors: coloresParaModulo(titulo),
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.15), radius: 6, x: 0, y: 4)
        }
        .buttonStyle(.plain)
    }

    // =========================
    // COLORES DINÁMICOS
    // =========================

    func coloresParaModulo(_ titulo: String) -> [Color] {

        switch titulo {

        case "Ventas", "Dispersión", "Flujo":
            return [.green, .teal]

        case "Producción", "Resumen Producción", "Saldos Facturas Adelantadas":
            return [.blue, .indigo]

        case "Inventarios", "Salidas", "Reingresos", "Creditos":
            return [.orange, .red]

        case "Costos", "Costeos", "Mezclilla":
            return [.purple, .pink]

        case "CxC", "CxP", "Bancos":
            return [.cyan, .blue]

        case "Centro Impresión", "Ajustes":
            return [.gray, .black.opacity(0.7)]

        case "Usuarios", "Perfil":
            return [.mint, .green]

        case "Diseño & Trazo":
            return [.cyan, .blue]

        case "Licencia":
            return [.yellow, .orange]

        case "Contacto":
            return [.mint, .green]

        case "Préstamos Otorgados":
            return [.green, .teal]

        default:
            return [.gray, .secondary]
        }
    }
}

// =========================
// EXTENSIÓN CONDICIONAL
// =========================

extension View {
    @ViewBuilder
    func mostrarSi(_ condicion: Bool) -> some View {
        if condicion {
            self
        }
    }
}
