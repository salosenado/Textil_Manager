//
//  ProduccionListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/30/26.
//
//
//  ProduccionListView.swift
//  Textil
//
//  Created by Salomon Senado on 1/30/26.
import SwiftUI
import SwiftData

struct ProduccionListView: View {

    @Environment(\.modelContext) private var context

    @Query private var detalles: [OrdenClienteDetalle]

    @State private var produccionSeleccionada: Produccion?
    @State private var textoBusqueda: String = ""

    // 🔑 DESDUPLICACIÓN REAL
    var detallesUnicos: [OrdenClienteDetalle] {
        var vistos = Set<PersistentIdentifier>()
        return detalles.filter { detalle in
            if vistos.contains(detalle.persistentModelID) {
                return false
            } else {
                vistos.insert(detalle.persistentModelID)
                return true
            }
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 12) {

                    ForEach(detallesFiltrados, id: \.persistentModelID) { detalle in
                        Button {

                            // 🔑 Crear o usar Producción REAL
                            if let produccion = detalle.produccion {
                                produccionSeleccionada = produccion
                            } else {
                                let nueva = Produccion(detalle: detalle)
                                detalle.produccion = nueva
                                context.insert(nueva)
                                try? context.save()
                                produccionSeleccionada = nueva
                            }

                        } label: {

                            // 🔹 UI pasiva (sin crear modelos)
                            if let produccion = detalle.produccion {
                                ProduccionCardView(produccion: produccion)
                            } else {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(detalle.modelo)
                                        .font(.headline)

                                    Text("Producción pendiente")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding()
            }
            .navigationTitle("Producción")
            .searchable(
                text: $textoBusqueda,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: "Buscar por modelo, cliente, pedido…"
            )
            .sheet(item: $produccionSeleccionada) { produccion in
                ProduccionDetalleView(produccion: produccion)
            }
        }
    }

    // MARK: - FILTRO DE BÚSQUEDA (SOBRE LISTA LIMPIA)

    var detallesFiltrados: [OrdenClienteDetalle] {
        let base = detallesUnicos

        guard !textoBusqueda.isEmpty else {
            return base
        }

        let texto = textoBusqueda.lowercased()

        return base.filter { detalle in
            detalle.modelo.lowercased().contains(texto)
            || detalle.articulo.lowercased().contains(texto)
            || (detalle.orden?.numeroPedidoCliente.lowercased().contains(texto) ?? false)
            || (detalle.orden?.cliente.lowercased().contains(texto) ?? false)
            || (detalle.produccion?.maquilero.lowercased().contains(texto) ?? false)
        }
    }
}
