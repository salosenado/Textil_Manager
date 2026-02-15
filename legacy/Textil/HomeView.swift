//
//  HomeView.swift
//  Textil
//
//  Created by Salomon Senado on 2/9/26.
//
import SwiftUI

struct HomeView: View {

    var body: some View {
        TabView {

            // TAB 1
            VStack {
                Text("Inventario")
                    .font(.largeTitle)
                Text("Aquí va InventariosView")
            }
            .tabItem {
                Label("Inventario", systemImage: "cube.box")
            }

            // TAB 2
            VStack {
                Text("Perfil")
                    .font(.largeTitle)
                Text("Tab de prueba")
            }
            .tabItem {
                Label("Perfil", systemImage: "person")
            }
        }
    }
}

#Preview {
    HomeView()
}
