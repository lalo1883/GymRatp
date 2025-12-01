import SwiftUI

struct InversePlateCalculatorView: View {
    @Binding var isPresented: Bool
    @State private var selectedBarWeight: Double = 20.0
    @State private var platesOnOneSide: [Double] = []
    
    let barOptions: [Double] = [20, 15, 10, 0]
    let plateOptions: [Double] = [25, 20, 15, 10, 5, 2.5, 1.25]
    
    var totalWeight: Double {
        selectedBarWeight + (platesOnOneSide.reduce(0, +) * 2)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Display Total Weight
                VStack {
                    Text("Peso Total")
                        .font(.headline)
                        .foregroundColor(.gray)
                    Text(String(format: "%.1f kg", totalWeight))
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(.neonGreen)
                }
                .padding(.top, 20)
                
                // Bar Selection
                VStack(alignment: .leading) {
                    Text("Peso de la Barra")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.horizontal)
                    
                    Picker("Barra", selection: $selectedBarWeight) {
                        ForEach(barOptions, id: \.self) { weight in
                            Text("\(Int(weight))kg").tag(weight)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }
                
                Divider()
                
                // Plates on Bar Visualization (One Side)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 2) {
                        // Bar end
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 20, height: 10)
                        
                        ForEach(platesOnOneSide.indices, id: \.self) { index in
                            let weight = platesOnOneSide[index]
                            InversePlateView(weight: weight)
                                .onTapGesture {
                                    removePlate(at: index)
                                }
                        }
                        
                        // Bar remaining
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 50, height: 10)
                    }
                    .padding()
                    .frame(height: 120)
                    .background(Color.cardBackground)
                    .cornerRadius(15)
                }
                .padding(.horizontal)
                
                Text("Toca un disco en la barra para quitarlo")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                Divider()
                
                // Add Plates Buttons
                Text("Añadir Discos (por lado)")
                    .font(.headline)
                    .foregroundColor(.white)
                
                LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 15) {
                    ForEach(plateOptions, id: \.self) { weight in
                        Button(action: { addPlate(weight) }) {
                            VStack {
                                Text("\(String(format: "%g", weight))")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                Text("kg")
                                    .font(.caption2)
                            }
                            .frame(width: 70, height: 70)
                            .background(plateColor(weight))
                            .foregroundColor(.white)
                            .clipShape(Circle())
                            .shadow(radius: 3)
                        }
                    }
                }
                .padding()
                
                Spacer()
                
                Button(action: { platesOnOneSide.removeAll() }) {
                    Text("Limpiar Todo")
                        .foregroundColor(.red)
                        .padding()
                }
            }
            .background(Color.appBackground)
            .navigationTitle("Calculadora Inversa")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Listo") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    func addPlate(_ weight: Double) {
        withAnimation(.spring()) {
            platesOnOneSide.append(weight)
        }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func removePlate(at index: Int) {
        withAnimation(.spring()) {
            platesOnOneSide.remove(at: index)
        }
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func plateColor(_ weight: Double) -> Color {
        switch weight {
        case 25: return .red
        case 20: return .blue
        case 15: return .yellow
        case 10: return .green
        case 5: return .white.opacity(0.8)
        case 2.5: return .black.opacity(0.8)
        default: return .gray
        }
    }
}

struct InversePlateView: View {
    let weight: Double
    
    var height: CGFloat {
        switch weight {
        case 25: return 100
        case 20: return 90
        case 15: return 80
        case 10: return 70
        case 5: return 50
        case 2.5: return 40
        default: return 30
        }
    }
    
    var color: Color {
        switch weight {
        case 25: return .red
        case 20: return .blue
        case 15: return .yellow
        case 10: return .green
        case 5: return .white.opacity(0.8)
        case 2.5: return .black.opacity(0.8) // Black plates usually
        default: return .gray
        }
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(color)
            .frame(width: 15, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 4)
                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
            )
    }
}
