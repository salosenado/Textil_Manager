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
                    RootView()
                }

                // 🔑 LOGIN
                else {
                    NavigationStack {
                        LoginView()
                    }
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
            CobroVenta.self,
            MovimientoFinancieroVenta.self,
            SalidaInsumo.self,
            SalidaInsumoDetalle.self,
            Reingreso.self,
            ReingresoDetalle.self,
            ReingresoMovimiento.self,
            ActivoEmpresa.self,
            MovimientoCaja.self,
            MovimientoBanco.self,
            PagoRegalia.self,
            PagoComision.self,
            Dispersion.self,
            DispersionSalida.self,
            ControlDisenoTrazo.self,
            Prestamo.self,
            PrestamoOtorgado.self,
            PagoPrestamo.self,
            PagoPrestamoOtorgado.self,

            // 🔥 NUEVO MÓDULO
            SaldoFacturaAdelantada.self,
            PagoSaldoFactura.self
        ])

    }
}
