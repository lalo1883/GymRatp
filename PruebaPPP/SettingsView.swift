import SwiftUI
import FirebaseAuth

struct SettingsView: View {
    @ObservedObject var viewModel: GymViewModel
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Unidades")) {
                    Picker("Unidad de Peso", selection: $viewModel.weightUnit) {
                        Text("Kilogramos (kg)").tag("kg")
                        Text("Libras (lbs)").tag("lbs")
                    }
                    .pickerStyle(.segmented)
                }
                
                Section(header: Text("Temporizador")) {
                    Picker("Tiempo de Descanso", selection: $viewModel.defaultRestTime) {
                        Text("60 segundos").tag(60)
                        Text("90 segundos").tag(90)
                        Text("120 segundos").tag(120)
                        Text("180 segundos").tag(180)
                    }
                }
                
                Section(header: Text("Preferencias")) {
                    Toggle("Efectos de Sonido", isOn: $viewModel.enableSound)
                        .tint(.neonGreen)
                    
                    Toggle("Vibración (Haptics)", isOn: $viewModel.enableHaptics)
                        .tint(.neonGreen)
                }
                
                Section(footer: Text("GymApp v1.0.0\nHecho con 💪 por Eduardo")) {
                    Button(action: {
                        do {
                            try Auth.auth().signOut()
                            // Dismiss settings to show login if handled by parent, 
                            // but usually ContentView needs to react to Auth state.
                            // Assuming ContentView observes Auth or similar.
                            dismiss()
                        } catch {
                            print("Error signing out: \(error)")
                        }
                    }) {
                        HStack {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
                            Text("Cerrar Sesión")
                        }
                        .foregroundColor(.red)
                    }
                }
            }
            .navigationTitle("Ajustes")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") { dismiss() }
                }
            }
        }
    }
}

#Preview {
    SettingsView(viewModel: GymViewModel())
}
