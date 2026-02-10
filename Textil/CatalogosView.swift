//
//  CatalogosView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//
//
//  CatalogosView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//

import SwiftUI

struct CatalogosView: View {

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {

                    CatalogSection(
                        title: "Comerciales",
                        systemImage: "briefcase.fill",
                        items: [
                            "Agentes",
                            "Clientes",
                            "Empresas",
                            "Proveedores"
                        ]
                    )

                    CatalogSection(
                        title: "Artículo",
                        systemImage: "tag.fill",
                        items: [
                            "Artículos",
                            "Colores",
                            "Departamentos",
                            "Líneas",
                            "Marcas",
                            "Modelos",
                            "Tallas",
                            "Telas",
                            "Unidades"
                        ]
                    )

                    CatalogSection(
                        title: "Operativos",
                        systemImage: "gearshape.fill",
                        items: [
                            "Maquileros"
                        ]
                    )

                    CatalogSection(
                        title: "Servicios",
                        systemImage: "wrench.and.screwdriver.fill",
                        items: [
                            "Servicios"
                        ]
                    )
                }
                .padding(.vertical, 16)
            }
            .background(Color.gray.opacity(0.08))
            .navigationTitle("Catálogos")
        }
    }
}

struct CatalogSection: View {

    let title: String
    let systemImage: String
    let items: [String]

    private var sortedItems: [String] {
        items.sorted {
            $0.localizedCaseInsensitiveCompare($1) == .orderedAscending
        }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {

            Label(title, systemImage: systemImage)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .padding(.horizontal)

            VStack(spacing: 0) {
                ForEach(sortedItems, id: \.self) { item in
                    NavigationLink {
                        destinationView(for: item)
                    } label: {
                        HStack {
                            Text(item)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundColor(.secondary)
                        }
                        .padding()
                    }

                    if item != sortedItems.last {
                        Divider()
                            .padding(.leading)
                    }
                }
            }
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .padding(.horizontal)
        }
    }

    @ViewBuilder
    private func destinationView(for item: String) -> some View {
        switch item {

        // COMERCIALES
        case "Agentes":
            AgentesListView()

        case "Clientes":
            ClientesListView()

        case "Empresas":
            EmpresasListView()

        case "Proveedores":
            ProveedoresListView()

        // ARTÍCULO
        case "Artículos":
            ArticulosListView()

        case "Colores":
            ColoresListView()

        case "Departamentos":
            DepartamentosListView()

        case "Líneas":
            LineasListView()

        case "Marcas":
            MarcasListView()

        case "Modelos":
            ModelosListView()

        case "Tallas":
            TallasListView()

        case "Telas":
            TelasListView()

        case "Unidades":
            UnidadesListView()

        // OPERATIVOS
        case "Maquileros":
            MaquilerosListView()

        // SERVICIOS ✅ (ESTE FALTABA BIEN)
        case "Servicios":
            ServiciosListView()

        // OTROS
        default:
            Text(item)
                .navigationTitle(item)
        }
    }
}

#Preview {
    CatalogosView()
}
