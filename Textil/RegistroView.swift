//
//  RegistroView.swift
//  Textil
//
//  Created by Salomon Senado on 2/13/26.
//


import SwiftUI
import Supabase

struct RegistroView: View {

    @EnvironmentObject var authVM: AuthViewModel
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var confirmarPassword = ""
    @State private var aceptarTerminos = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {

        ScrollView {
            VStack(spacing: 20) {

                Text("Crear Cuenta")
                    .font(.largeTitle)
                    .bold()

                // EMAIL
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                // PASSWORD
                SecureField("Contraseña", text: $password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                // CONFIRMAR PASSWORD
                SecureField("Confirmar contraseña", text: $confirmarPassword)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(10)

                // CHECKBOX TÉRMINOS
                Toggle(isOn: $aceptarTerminos) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Acepto los Términos y Condiciones")
                            .font(.footnote)

                        HStack {
                            NavigationLink("Ver Términos") {
                                TermsView()
                            }

                            NavigationLink("Política de Privacidad") {
                                PrivacyPolicyView()
                            }
                        }
                        .font(.footnote)
                    }
                }

                if let errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                }

                // BOTÓN REGISTRAR
                Button {
                    Task {
                        await registrar()
                    }
                } label: {
                    if isLoading {
                        ProgressView()
                            .frame(maxWidth: .infinity)
                    } else {
                        Text("Crear Cuenta")
                            .frame(maxWidth: .infinity)
                    }
                }
                .buttonStyle(.borderedProminent)
                .disabled(isLoading || !aceptarTerminos)

                Spacer()
            }
            .padding()
        }
    }

    // MARK: - REGISTRO
    func registrar() async {

        let emailLimpio = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !emailLimpio.isEmpty else {
            errorMessage = "Ingresa tu email"
            return
        }

        guard password.count >= 6 else {
            errorMessage = "La contraseña debe tener mínimo 6 caracteres"
            return
        }

        guard password == confirmarPassword else {
            errorMessage = "Las contraseñas no coinciden"
            return
        }

        guard aceptarTerminos else {
            errorMessage = "Debes aceptar los términos"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            try await supabase.auth.signUp(
                email: emailLimpio,
                password: password
            )

            dismiss()

        } catch {
            errorMessage = error.localizedDescription
        }

        isLoading = false
    }
}
