//
//  TextilApp.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  TextilApp.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  TextilApp.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//

import SwiftUI
import SwiftData

@main
struct TextilApp: App {

    @StateObject private var authVM = AuthViewModel()

    var body: some Scene {
        WindowGroup {
            Group {

                // ⏳ CARGANDO SESIÓN
                if authVM.isCheckingSession {
                    ProgressView()
                }

                // 🔒 USUARIO BLOQUEADO
                else if authVM.usuarioBloqueado {
                    UsuarioBloqueadoView()
                }

                // ✅ SESIÓN ACTIVA
                else if authVM.isLoggedIn {
                    RootView()          // 🔥 AQUÍ ESTÁN TUS 20 TABS
                }

                // 🔑 LOGIN
                else {
                    LoginView()
                }
            }
            .environmentObject(authVM)
        }
        .modelContainer(for: [
            Agente.self,
            Cliente.self,
            Empresa.self,
            Proveedor.self,
            Articulo.self,
            ColorModelo.self,
            Modelo.self,
            Talla.self,
            Tela.self,
            PrecioTela.self,
            Departamento.self,
            Linea.self,
            Marca.self,
            Unidad.self,
            Maquilero.self,
            Servicio.self,
            TipoTela.self,
            CostoMezclillaEntity.self,
            CostoGeneralEntity.self,
            OrdenCliente.self,
            OrdenClienteDetalle.self,
            OrdenCompra.self,
            OrdenCompraDetalle.self,
            CompraCliente.self,
            CompraClienteDetalle.self,
            ReciboCompra.self,
            ReciboCompraPago.self,
            Produccion.self,
            ReciboProduccion.self,
            ReciboCompraDetalle.self,
            PagoRecibo.self,
            ProduccionFirma.self,
            VentaCliente.self,
            VentaClienteDetalle.self,
            SalidaInsumo.self,
            SalidaInsumoDetalle.self,
            Reingreso.self,
            ReingresoDetalle.self,
            ReingresoMovimiento.self
        ])
    }
}
