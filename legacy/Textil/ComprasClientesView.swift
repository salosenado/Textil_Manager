//
//  ComprasClientesView.swift
//  Textil
//
//  Created by Salomon Senado on 1/31/26.
//


import SwiftUI

struct ComprasClientesView: View {
    var body: some View {
        NavigationStack {
            Text("Compras de Clientes")
                .font(.title2)
                .fontWeight(.semibold)
                .navigationTitle("Compras Clientes")
        }
    }
}

#Preview {
    ComprasClientesView()
}
