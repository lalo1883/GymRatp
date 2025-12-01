import SwiftUI

struct OneRepMaxView: View {
    @State private var weight: String = ""
    @State private var reps: String = ""
    @State private var oneRepMax: Double = 0
    @State private var percentages: [(Int, Double)] = []
    
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Input Section
                VStack(spacing: 15) {
                    Text("Calculadora de 1RM")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Peso")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("0", text: $weight)
                                .keyboardType(.decimalPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                        
                        VStack(alignment: .leading) {
                            Text("Reps")
                                .font(.caption)
                                .foregroundColor(.gray)
                            TextField("0", text: $reps)
                                .keyboardType(.numberPad)
                                .textFieldStyle(RoundedBorderTextFieldStyle())
                        }
                    }
                    
                    Button(action: calculate1RM) {
                        Text("Calcular")
                            .fontWeight(.bold)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.neonGreen)
                            .foregroundColor(.black)
                            .cornerRadius(10)
                    }
                }
                .padding()
                .background(Color.cardBackground)
                .cornerRadius(15)
                
                // Result Section
                if oneRepMax > 0 {
                    VStack(spacing: 10) {
                        Text("Tu 1RM Estimado")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text(String(format: "%.1f", oneRepMax))
                            .font(.system(size: 60, weight: .bold, design: .rounded))
                            .foregroundColor(.neonBlue)
                        
                        Divider().background(Color.gray)
                        
                        // Percentages Grid
                        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                            ForEach(percentages, id: \.0) { percentage, value in
                                HStack {
                                    Text("\(percentage)%")
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Text(String(format: "%.1f", value))
                                        .foregroundColor(.gray)
                                }
                                .padding()
                                .background(Color.white.opacity(0.05))
                                .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(15)
                    .transition(.scale.combined(with: .opacity))
                }
                
                Spacer()
            }
            .padding()
            .background(Color.appBackground)
            .navigationTitle("Fuerza Máxima")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                }
            }
        }
    }
    
    func calculate1RM() {
        guard let w = Double(weight), let r = Double(reps), r > 0 else { return }
        
        // Brzycki Formula
        let max = w * (36 / (37 - r))
        oneRepMax = max
        
        // Calculate percentages
        let percents = [95, 90, 85, 80, 75, 70, 60, 50]
        percentages = percents.map { ($0, max * Double($0) / 100.0) }
        
        // Hide keyboard
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    OneRepMaxView()
        .preferredColorScheme(.dark)
}
