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

struct RootView: View {

    @EnvironmentObject var authVM: AuthViewModel

    var body: some View {

        TabView {

            // =========================
            // 📦 CATÁLOGOS (TODOS)
            // =========================
            NavigationStack {
                CatalogosView()
            }
            .tabItem {
                Label("Catálogos", systemImage: "square.grid.2x2")
            }

            // =========================
            // 💲 COSTOS (ADMIN / SUPERADMIN)
            // =========================
            if authVM.esAdmin {

                NavigationStack {
                    CostosGeneralListView()
                }
                .tabItem {
                    Label("Costos", systemImage: "dollarsign.circle")
                }

                NavigationStack {
                    CostosMezclillaListView()
                }
                .tabItem {
                    Label("Mezclilla", systemImage: "scissors")
                }

                NavigationStack {
                    CosteosListView()
                }
                .tabItem {
                    Label("Costeos", systemImage: "chart.line.uptrend.xyaxis")
                }
            }

            // =========================
            // ⚙️ PRODUCCIÓN (TODOS)
            // =========================
            NavigationStack {
                ProduccionListView()
            }
            .tabItem {
                Label("Producción", systemImage: "gearshape.2")
            }

            NavigationStack {
                ReciboListView()
            }
            .tabItem {
                Label("Recibo Prod.", systemImage: "shippingbox")
            }

            // =========================
            // 📄 ÓRDENES / COMPRAS (TODOS)
            // =========================
            NavigationStack {
                OrdenesClientesView()
            }
            .tabItem {
                Label("Órdenes", systemImage: "doc.text")
            }

            NavigationStack {
                ComprasClientesListView()
            }
            .tabItem {
                Label("Compras Cli.", systemImage: "cart")
            }

            NavigationStack {
                ComprasInsumosListView()
            }
            .tabItem {
                Label("Compras Ins.", systemImage: "cart.badge.plus")
            }

            // =========================
            // 🔧 SERVICIOS (ADMIN+)
            // =========================
            if authVM.esAdmin {

                NavigationStack {
                    SolicitudesServiciosListView()
                }
                .tabItem {
                    Label("Servicios", systemImage: "wrench.and.screwdriver")
                }

                NavigationStack {
                    ReciboComprasServiciosListView()
                }
                .tabItem {
                    Label("Recibos", systemImage: "shippingbox")
                }
            }

            // =========================
            // 📦 INVENTARIOS (TODOS)
            // =========================
            NavigationStack {
                InventariosView()
            }
            .tabItem {
                Label("Inventarios", systemImage: "archivebox")
            }

            // =========================
            // 💳 VENTAS / MOVIMIENTOS (ADMIN+)
            // =========================
            if authVM.esAdmin {

                NavigationStack {
                    VentasClientesListView()
                }
                .tabItem {
                    Label("Ventas", systemImage: "creditcard")
                }

                NavigationStack {
                    SalidasInsumosListView()
                }
                .tabItem {
                    Label("Salidas", systemImage: "arrow.up.square")
                }

                NavigationStack {
                    ReingresosListView()
                }
                .tabItem {
                    Label("Reingresos", systemImage: "arrow.down.square")
                }
            }

            // =========================
            // 👥 USUARIOS (SOLO SUPERADMIN) 🔥
            // =========================
            if authVM.esSuperAdmin {

                NavigationStack {
                    UsuariosAdminView()
                }
                .tabItem {
                    Label("Usuarios", systemImage: "person.3.fill")
                }
            }

            // =========================
            // 📊 RESÚMENES (SOLO SUPERADMIN)
            // =========================
            if authVM.esSuperAdmin {

                NavigationStack {
                    ResumenProduccionView()
                }
                .tabItem {
                    Label("Resumen Prod.", systemImage: "chart.bar.fill")
                }

                NavigationStack {
                    ResumenComprasClienteView()
                }
                .tabItem {
                    Label("Resumen Compras", systemImage: "cart.fill")
                }
            }

            // =========================
            // 👤 PERFIL (SIEMPRE)
            // =========================
            NavigationStack {
                PerfilView()
            }
            .tabItem {
                Label("Perfil", systemImage: "person.circle")
            }
        }
    }
}

#Preview {
    RootView()
        .environmentObject(AuthViewModel())
}
