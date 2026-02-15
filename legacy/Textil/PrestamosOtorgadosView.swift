//
//  PrestamosOtorgadosView.swift
//  Textil
//
//  Created by Salomon Senado on 2/14/26.
//
import SwiftUI
import SwiftData

struct PrestamosOtorgadosView: View {
    
    @Environment(\.modelContext) private var context
    
    @Query(sort: \PrestamoOtorgado.nombre)
    private var prestamos: [PrestamoOtorgado]
    
    @State private var showingNuevoPrestamo = false
    @State private var busqueda = ""
    
    @State private var filtroStatus = "Todos"
    @State private var filtroTipo = "Todos"
    
    private let opcionesStatus = ["Todos", "Al día", "Vencido", "Finalizado"]
    private let opcionesTipo = ["Todos", "Empleado", "Particular"]
    
    var body: some View {
        
        NavigationStack {
            
            VStack(spacing: 0) {
                
                // 🔍 BUSCADOR
                TextField("Buscar nombre o apellido...", text: $busqueda)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .padding()
                
                // 🔽 PICKER STATUS
                HStack {
                    Text("Status")
                        .font(.body)

                    Spacer()

                    Picker("", selection: $filtroStatus) {
                        ForEach(opcionesStatus, id: \.self) { opcion in
                            Text(opcion)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.primary) // 🔥 quita azul
                }
                .padding(.horizontal)

                
                // 🔽 PICKER TIPO
                HStack {
                    Text("Tipo")
                        .font(.body)

                    Spacer()

                    Picker("", selection: $filtroTipo) {
                        ForEach(opcionesTipo, id: \.self) { opcion in
                            Text(opcion)
                        }
                    }
                    .pickerStyle(.menu)
                    .tint(.primary) // 🔥 quita azul
                }
                .padding(.horizontal)
                .padding(.bottom, 8)

                
                ScrollView {
                    
                    VStack(spacing: 16) {
                        
                        resumenGlobal
                        
                        ForEach(prestamosFiltrados) { prestamo in
                            
                            NavigationLink {
                                DetallePrestamoOtorgadoView(prestamo: prestamo)
                            } label: {
                                tarjetaPrestamo(prestamo)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
                .background(Color(.systemGroupedBackground))
            }
            .navigationTitle("Préstamos Otorgados")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showingNuevoPrestamo = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingNuevoPrestamo) {
                NuevoPrestamoOtorgadoView()
            }
        }
    }
    
    // MARK: - FILTRO
    
    private var prestamosFiltrados: [PrestamoOtorgado] {
        
        prestamos.filter { prestamo in
            
            let apellido = prestamo.apellido ?? ""
            
            let coincideBusqueda =
            busqueda.isEmpty ||
            prestamo.nombre.localizedCaseInsensitiveContains(busqueda) ||
            apellido.localizedCaseInsensitiveContains(busqueda)
            
            let coincideStatus =
            filtroStatus == "Todos" ||
            (filtroStatus == "Al día" && !prestamo.estaAtrasado && prestamo.capitalPendiente > 0) ||
            (filtroStatus == "Vencido" && prestamo.estaAtrasado) ||
            (filtroStatus == "Finalizado" && prestamo.capitalPendiente <= 0)
            
            let coincideTipo =
            filtroTipo == "Todos" ||
            (filtroTipo == "Empleado" && prestamo.esEmpleado) ||
            (filtroTipo == "Particular" && !prestamo.esEmpleado)
            
            return coincideBusqueda && coincideStatus && coincideTipo
        }
    }
    
    // MARK: - TARJETA
    
    private func tarjetaPrestamo(_ prestamo: PrestamoOtorgado) -> some View {
        
        VStack(alignment: .leading, spacing: 10) {
            
            HStack {
                VStack(alignment: .leading) {
                    
                    Text("\(prestamo.nombre) \(prestamo.apellido ?? "")")
                        .font(.headline)
                    
                    Text(prestamo.esEmpleado ? "Empleado" : "Particular")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                estadoBadge(prestamo)
            }
            
            Divider()
            
            HStack {
                Text("Capital pendiente")
                Spacer()
                Text(formatoMoneda(prestamo.capitalPendiente))
                    .foregroundColor(.red)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
        )
    }
    
    // MARK: - RESUMEN GLOBAL
    
    private var resumenGlobal: some View {
        
        let totalPrestado = prestamosFiltrados.map { $0.montoPrestado }.reduce(0, +)
        let totalCapital = prestamosFiltrados.map { $0.capitalPendiente }.reduce(0, +)
        
        return VStack(spacing: 8) {
            
            HStack {
                Text("Total Prestado")
                Spacer()
                Text(formatoMoneda(totalPrestado))
            }
            
            HStack {
                Text("Capital Pendiente")
                Spacer()
                Text(formatoMoneda(totalCapital))
                    .foregroundColor(.red)
            }
            
            Divider()
            
            HStack {
                Text("Deuda Total")
                    .fontWeight(.bold)
                Spacer()
                Text(formatoMoneda(totalCapital))
                    .foregroundColor(.blue)
                    .fontWeight(.bold)
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 18)
                .fill(Color.white)
        )
    }
    
    // MARK: - BADGE
    
    private func estadoBadge(_ prestamo: PrestamoOtorgado) -> some View {
        
        let texto: String
        let color: Color
        
        if prestamo.capitalPendiente <= 0 {
            texto = "FINALIZADO"
            color = .blue
        } else if prestamo.estaAtrasado {
            texto = "VENCIDO"
            color = .red
        } else {
            texto = "AL DÍA"
            color = .green
        }
        
        return Text(texto)
            .font(.caption)
            .fontWeight(.bold)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(color)
            .foregroundColor(.white)
            .cornerRadius(12)
    }

    // MARK: - FORMATO
    
    private func formatoMoneda(_ valor: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.currencyCode = "MXN"
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: NSNumber(value: valor)) ?? "MX$0.00"
    }
}
