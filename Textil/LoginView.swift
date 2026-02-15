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

            // MARK: - TITLE
            Text("Iniciar sesión")
                .font(.largeTitle)
                .bold()

            // MARK: - EMAIL
            TextField("Email", text: $email)
                .keyboardType(.emailAddress)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            // MARK: - PASSWORD
            SecureField("Contraseña", text: $password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(10)

            // MARK: - ERROR
            if let errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
                    .multilineTextAlignment(.center)
            }

            // MARK: - LOGIN BUTTON
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

            // MARK: - REGISTRO
            NavigationLink("Crear cuenta") {
                RegistroView()
            }
            .padding(.top, 5)

            Spacer()

            Divider()
                .padding(.vertical, 10)

            // =========================
            // 📞 CONTACTO EMPRESARIAL
            // =========================
            VStack(spacing: 12) {

                Text("¿No tienes cuenta?")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                Text("Contáctanos para solicitar acceso")
                    .font(.footnote)
                    .foregroundStyle(.secondary)

                HStack(spacing: 25) {

                    // WhatsApp
                    Button {
                        openURL("https://wa.me/5215591019101?text=Hola%20AppIndustri,%20quiero%20información%20sobre%20la%20plataforma.")
                    } label: {
                        VStack {
                            Image(systemName: "message.fill")
                                .font(.title2)
                                .foregroundStyle(.green)
                            Text("WhatsApp")
                                .font(.caption)
                        }
                    }

                    // Email
                    Button {
                        openURL("mailto:sales@appindustri.com")
                    } label: {
                        VStack {
                            Image(systemName: "envelope.fill")
                                .font(.title2)
                                .foregroundStyle(.blue)
                            Text("Email")
                                .font(.caption)
                        }
                    }

                    // Llamar
                    Button {
                        openURL("tel://+525591019101")
                    } label: {
                        VStack {
                            Image(systemName: "phone.fill")
                                .font(.title2)
                                .foregroundStyle(.orange)
                            Text("Llamar")
                                .font(.caption)
                        }
                    }
                }
            }

            // =========================
            // 📄 LEGAL
            // =========================
            VStack(spacing: 8) {

                NavigationLink("Política de Privacidad") {
                    PrivacyPolicyView()
                }
                .font(.footnote)

                NavigationLink("Términos y Condiciones") {
                    TermsView()
                }
                .font(.footnote)
            }
            .foregroundStyle(.secondary)
            .padding(.top, 10)
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

            authVM.isLoggedIn = true

        } catch {
            print("❌ LOGIN ERROR:", error)

            let mensaje = error.localizedDescription.lowercased()

            if mensaje.contains("invalid login credentials") {
                errorMessage = "Email o contraseña incorrectos"
            } else if mensaje.contains("email not confirmed") {
                errorMessage = "Debes confirmar tu email primero"
            } else {
                errorMessage = error.localizedDescription
            }
        }

        isLoading = false
    }

    // MARK: - Open URL
    private func openURL(_ string: String) {
        guard let url = URL(string: string) else { return }
        UIApplication.shared.open(url)
    }
}

#Preview {
    NavigationStack {
        LoginView()
            .environmentObject(AuthViewModel())
    }
}
