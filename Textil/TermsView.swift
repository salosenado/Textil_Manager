//
//  TermsView.swift
//  Textil
//
//  Created by Salomon Senado on 2/13/26.
//


import SwiftUI

struct TermsView: View {

    var body: some View {
        ScrollView {
            Text("""
TÉRMINOS Y CONDICIONES

Esta aplicación otorga una licencia anual de uso.

No se transfiere propiedad del software.

El usuario es responsable de la información capturada.

La empresa no es responsable por decisiones financieras tomadas con base en datos ingresados por el usuario.

La licencia puede suspenderse por incumplimiento de pago.
""")
            .padding()
        }
        .navigationTitle("Términos")
    }
}
