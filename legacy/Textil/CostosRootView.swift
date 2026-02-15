//
//  CostosRootView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//


//
//  CostosRootView.swift
//  Textil
//
//  Created by Salomon Senado on 1/29/26.
//

import SwiftUI

struct CostosRootView: View {

    var body: some View {
        NavigationStack {
            CostosGeneralListView()
                .navigationTitle("Costos")
        }
    }
}

#Preview {
    CostosRootView()
}
