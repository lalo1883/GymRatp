import SwiftUI

struct VisualPlateCalculatorView: View {
    @Binding var isPresented: Bool
    @ObservedObject var viewModel: GymViewModel
    @State private var targetWeightString: String = ""
    @State private var barWeight: Double = 20.0 // Default 20kg / 45lbs
    
    // Plate Definition
    struct Plate: Identifiable {
        let id = UUID()
        let weight: Double
        let color: Color
        let heightRatio: CGFloat
    }
    
    // Available Plates (Kg)
    let kgPlates: [Plate] = [
        Plate(weight: 25.0, color: .red, heightRatio: 1.0),
        Plate(weight: 20.0, color: .blue, heightRatio: 1.0),
        Plate(weight: 15.0, color: .yellow, heightRatio: 0.9),
        Plate(weight: 10.0, color: .green, heightRatio: 0.8),
        Plate(weight: 5.0, color: .white, heightRatio: 0.6),
        Plate(weight: 2.5, color: .black, heightRatio: 0.5),
        Plate(weight: 1.25, color: .gray, heightRatio: 0.4)
    ]
    
    // Available Plates (Lbs)
    let lbsPlates: [Plate] = [
        Plate(weight: 45.0, color: .blue, heightRatio: 1.0),
        Plate(weight: 35.0, color: .yellow, heightRatio: 0.9),
        Plate(weight: 25.0, color: .green, heightRatio: 0.8),
        Plate(weight: 10.0, color: .white, heightRatio: 0.6),
        Plate(weight: 5.0, color: .black, heightRatio: 0.5),
        Plate(weight: 2.5, color: .gray, heightRatio: 0.4)
    ]
    
    var currentPlates: [Plate] {
        viewModel.weightUnit == "lbs" ? lbsPlates : kgPlates
    }
    
    var calculatedPlates: [Plate] {
        guard let target = Double(targetWeightString), target > barWeight else { return [] }
        var remainingWeight = (target - barWeight) / 2.0
        var result: [Plate] = []
        
        for plate in currentPlates {
            while remainingWeight >= plate.weight {
                result.append(plate)
                remainingWeight -= plate.weight
            }
        }
        return result
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 30) {
                // Input Section
                VStack {
                    Text("Peso Objetivo (\(viewModel.unitLabel()))")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    TextField("0", text: $targetWeightString)
                        .font(.system(size: 50, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)
                        .foregroundColor(.white)
                }
                
                // Bar Selection
                Picker("Peso de la Barra", selection: $barWeight) {
                    if viewModel.weightUnit == "lbs" {
                        Text("Barra 45 lbs").tag(45.0)
                        Text("Barra 35 lbs").tag(35.0)
                    } else {
                        Text("Barra 20 kg").tag(20.0)
                        Text("Barra 15 kg").tag(15.0)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                .onChange(of: viewModel.weightUnit) { newValue in
                    barWeight = newValue == "lbs" ? 45.0 : 20.0
                }
                
                Spacer()
                
                // Visual Representation
                ZStack {
                    // Barbell Shaft
                    Rectangle()
                        .fill(Color.gray)
                        .frame(height: 15)
                    
                    // Barbell Sleeve (Right Side)
                    HStack(spacing: 0) {
                        Spacer()
                        Rectangle()
                            .fill(Color.gray.opacity(0.8))
                            .frame(width: 20, height: 25) // Inner collar
                        
                        // Plates
                        HStack(spacing: 2) {
                            ForEach(calculatedPlates) { plate in
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(plate.color)
                                    .frame(width: 15, height: 120 * plate.heightRatio)
                                    .overlay(
                                        Text(String(format: "%.0f", plate.weight))
                                            .font(.caption2)
                                            .foregroundColor(plate.color == .white ? .black : .white)
                                            .rotationEffect(.degrees(-90))
                                            .fixedSize()
                                    )
                            }
                        }
                        
                        Rectangle() // Remaining sleeve
                            .fill(Color.gray)
                            .frame(height: 20)
                    }
                }
                .frame(height: 150)
                .padding(.horizontal)
                
                Spacer()
                
                // Text Summary
                if !calculatedPlates.isEmpty {
                    VStack {
                        Text("Por lado:")
                            .font(.headline)
                            .foregroundColor(.gray)
                        Text(calculatedPlates.map { "\(String(format: "%g", $0.weight))" }.joined(separator: " + "))
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.neonGreen)
                    }
                } else if let target = Double(targetWeightString), target < barWeight {
                    Text("El peso debe ser mayor a la barra")
                        .foregroundColor(.red)
                }
                
                Spacer()
            }
            .background(Color.appBackground)
            .navigationTitle("Calculadora Visual")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cerrar") { isPresented = false }
                }
            }
        }
    }
}
