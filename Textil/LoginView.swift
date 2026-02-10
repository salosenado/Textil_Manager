//
//  LoginView.swift
//  Textil
//
//  Created by Salomon Senado on 2/9/26.
//
//
//  LoginView.swift
//  Textil
//
//  Created by Salomon Senado on 2/9/26.
//

import SwiftUI
import Supabase

struct LoginView: View {

    // MARK: - ENV
    @EnvironmentObject var authVM: AuthViewModel

    // MARK: - State
    @State private var email: String = ""
    @State private var password: String = ""
    @State private var isLoading: Bool = false
    @State private var errorMessage: String?

    // MARK: - UI
    var body: some View {
        VStack(spacing: 20) {

            Spacer()

            Text("Iniciar sesión")
                .font(.largeTitle)
                .bold()

            // EMAIL
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

            // PASSWORD
            SecureField("Contraseña", text: $password)
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(10)

            // ERROR
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            // LOGIN BUTTON
            Button {
                Task {
                    await iniciarSesion()
                }
            } label: {
                if isLoading {
                    ProgressView()
                        .frame(maxWidth: .infinity)
                } else {
                    Text("Entrar")
                        .frame(maxWidth: .infinity)
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(isLoading)

            Spacer()
        }
        .padding()
    }

    // MARK: - LOGIN
    func iniciarSesion() async {

        let emailLimpio = email
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()

        guard !emailLimpio.isEmpty else {
            errorMessage = "Ingresa tu email"
            return
        }

        guard !password.isEmpty else {
            errorMessage = "Ingresa tu contraseña"
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let session = try await supabase.auth.signIn(
                email: emailLimpio,
                password: password
            )

            print("✅ LOGIN OK")
            print("USER ID:", session.user.id)

            // 🔥 AQUÍ ES DONDE ENTRA A LA APP
            authVM.isLoggedIn = true

        } catch {
            print("❌ LOGIN ERROR:", error)

            let mensaje = error.localizedDescription.lowercased()

            if mensaje.contains("invalid login credentials") {
                errorMessage = "Email o contraseña incorrectos"
            } else if mensaje.contains("email not confirmed") {
                errorMessage = "Debes confirmar tu email primero"
            } else if mensaje.contains("missing email") {
                errorMessage = "Falta el email"
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}
