//
//  RootView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  RootView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
import SwiftUI
import SwiftData

struct RootView: View {

    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {

        TabView {

            // =====================================================
            // 🟢 1. OPERACIÓN
            // =====================================================

            NavigationStack {
                List {

                    NavigationLink("Inicio") {
                        InicioDashboardView()
                    }

                    if authVM.esAdmin {

                        NavigationLink("Costos") {
                            CostosGeneralListView()
                        }

                        NavigationLink("Mezclilla") {
                            CostosMezclillaListView()
                        }

                        NavigationLink("Costeos") {
                            CosteosListView()
                        }
                    }

                    NavigationLink("Producción") {
                        ProduccionListView()
                    }

                    NavigationLink("Recibo Producción") {
                        ReciboListView()
                    }

                    NavigationLink("Centro Impresión") {
                        CentroImpresionView()
                    }

                    NavigationLink("Inventarios") {
                        InventariosView()
                    }

                    NavigationLink("Diseño y Trazo") {
                        DisenoTrazoView()
                    }
                }
                .navigationTitle("Operación")
            }
            .tabItem {
                Label("Operación", systemImage: "gearshape.2.fill")
            }


            // =====================================================
            // 🔵 2. COMPRAS
            // =====================================================

            NavigationStack {
                List {

                    NavigationLink("Compras Clientes") {
                        ComprasClientesListView()
                    }

                    NavigationLink("Compras Insumos") {
                        ComprasInsumosListView()
                    }

                    if authVM.esAdmin {

                        NavigationLink("Servicios") {
                            SolicitudesServiciosListView()
                        }

                        NavigationLink("Recibo Compras y Servicios") {
                            ReciboComprasServiciosListView()
                        }
                    }
                }
                .navigationTitle("Compras")
            }
            .tabItem {
                Label("Compras", systemImage: "cart.fill")
            }


            // =====================================================
            // 🟣 3. VENTAS
            // =====================================================

            NavigationStack {
                List {

                    NavigationLink("Órdenes Clietes") {
                        OrdenesClientesView()
                    }

                    if authVM.esAdmin {

                        NavigationLink("Ventas") {
                            VentasClientesListView()
                        }

                        NavigationLink("Salidas De Insumos") {
                            SalidasInsumosListView()
                        }

                        NavigationLink("Reingresos") {
                            ReingresosListView()
                        }

                        NavigationLink("Regalías Marcas") {
                            RegaliasView()
                        }

                        NavigationLink("Comisiones Ventas") {
                            ComisionesView()
                        }
                    }
                }
                .navigationTitle("Ventas")
            }
            .tabItem {
                Label("Ventas", systemImage: "creditcard.fill")
            }


            // =====================================================
            // 🔴 4. FINANZAS
            // =====================================================

            NavigationStack {
                List {

                    if authVM.esAdmin {

                        NavigationLink("Cuentas por Cobrar") {
                            CuentasPorCobrarView()
                        }

                        NavigationLink("Cuentas por Pagar") {
                            ZStack {
                                CuentasPorPagarView()
                                CxPTabBadgeView()
                            }
                        }

                        NavigationLink("Bancos") {
                            MovimientosBancosView()
                        }

                        NavigationLink("Flujo") {
                            FlujoEfectivoView()
                        }
                        
                        NavigationLink("Saldos Facturas Adelantadas") {
                            SaldosFacturasView()
                        }
                        
                        // 🔵 NUEVO MÓDULO (Nosotros prestamos)
                        NavigationLink("Préstamos Otorgados") {
                            PrestamosOtorgadosView()
                        }

                        // 🔥 MÓDULO CRÉDITOS (Nos prestan)
                        NavigationLink("Creditos") {
                            PrestamosView()
                        }

                    }

                    if authVM.esSuperAdmin {
                        NavigationLink("Dispersión") {
                            DispersionesView()
                        }
                    }
                }
                .navigationTitle("Finanzas")
            }
            .tabItem {
                Label("Finanzas", systemImage: "dollarsign.circle.fill")
            }


            // =====================================================
            // 🟡 5. ADMIN
            // =====================================================

            NavigationStack {
                List {

                    if authVM.esSuperAdmin {
                        NavigationLink("Resumen Producción") {
                            ResumenProduccionView()
                        }
                    }

                    if authVM.esAdmin {

                        NavigationLink("Resumen Compras Clientes") {
                            ResumenComprasClientesView()
                        }

                        NavigationLink("Resumen Insumos") {
                            ResumenComprasInsumosView()
                        }

                        NavigationLink("Resumen Servicios") {
                            ResumenComprasServiciosView()
                        }

                        NavigationLink("Activos") {
                            ActivosEmpresaView()
                        }
                    }

                    NavigationLink("Catálogos") {
                        CatalogosView()
                    }

                    if authVM.esSuperAdmin {
                        NavigationLink("Usuarios") {
                            UsuariosAdminView()
                        }
                    }

                    Divider()

                    NavigationLink("Perfil") {
                        PerfilView()
                    }

                    NavigationLink("Ajustes") {
                        AjustesView()
                    }

                    NavigationLink("Licencia") {
                        LicenciaView()
                    }

                    NavigationLink("Contacto") {
                        ContactoView()
                    }
                }
                .navigationTitle("Administración")
            }
            .tabItem {
                Label("Admin", systemImage: "building.2.fill")
            }
        }
    }
}
#Preview {
    RootView()
        .environmentObject(AuthViewModel())
}
    
