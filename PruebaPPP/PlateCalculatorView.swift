import SwiftUI

struct PlateCalculatorView: View {
    @Binding var isPresented: Bool
    @Binding var weightInput: String // Binding to update the parent's weight field
    
    @State private var selectedBarWeight: Double = 20.0 // Default Olympic bar
    @State private var addedPlates: [Double] = []
    
    let availablePlates: [Double] = [20, 15, 10, 5, 2.5, 1.25] // Kg
    // If user uses Lbs, we might need to adjust, but for now assuming Kg based on previous context or making it generic.
    // The user screenshot shows "lbs", so we should probably support units or just generic values.
    // Let's stick to the values in the screenshot/context. If the app is in Lbs, these might be 45, 35, 25, 10, 5, 2.5.
    // For now, I'll use a generic approach or stick to what was there. The user mentioned "Barra 45 lbs" in the screenshot.
    // Let's try to detect unit or provide options.
    // To keep it simple and consistent with the user's request "Barra 45 lbs | Barra 35 lbs", I will use Lbs values for the UI if the user seems to be using Lbs, or just generic.
    // However, the previous code used Kg. I'll add a toggle or just use the values from the screenshot.
    // Screenshot shows: 45, 35, 25, 10, 5, 2.5.
    
    // Let's use a standard set of plates that can represent both or just generic "Plates".
    // Better yet, let's make it adaptable or just use the screenshot values as default for "Lbs" mode if we can detect it, otherwise Kg.
    // Since I don't have easy access to the global unit setting here without passing it, I'll assume standard Olympic plates (20kg/45lbs).
    // I'll use a "Unit" enum or just simple values.
    
    // Let's implement the visual interaction: Tap plate -> Add to list.
    
    var totalWeight: Double {
        selectedBarWeight + (addedPlates.reduce(0, +) * 2)
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                // Header & Total
                VStack {
                    Text("Calculadora Visual")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    
                    Text("Peso Objetivo")
                        .font(.caption)
                        .foregroundColor(.gray)
                    
                    Text("\(String(format: "%.1f", totalWeight))")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }
                .padding(.top)
                
                // Bar Selection
                Picker("Peso de Barra", selection: $selectedBarWeight) {
                    Text("Barra 45 lbs / 20 kg").tag(20.0) // Using 20kg as base, or 45lbs.
                    // If the app is strictly Kg/Lbs, this might be confusing.
                    // Let's assume the user wants Lbs based on the screenshot "Barra 45 lbs".
                    // But the previous code was Kg.
                    // I'll use 45.0 for Lbs and 20.0 for Kg if I could.
                    // Let's just use the values from the screenshot for now: 45 and 35.
                    Text("Barra 45 lbs").tag(45.0)
                    Text("Barra 35 lbs").tag(35.0)
                }
                .pickerStyle(.segmented)
                .padding()
                
                Spacer()
                
                // Visualization (Bar + Plates)
                ZStack {
                    // Bar
                    Rectangle()
                        .fill(Color.gray)
                        .frame(height: 12)
                    
                    // Plates on the bar (One side shown or both? Screenshot shows one side or center?)
                    // Screenshot shows a bar at the bottom.
                    // Let's show the full bar with plates mirroring.
                    
                    HStack(spacing: 1) {
                        Spacer()
                        // Left side (reversed)
                        ForEach(addedPlates.reversed(), id: \.self) { weight in
                            PlateVisual(weight: weight)
                        }
                        
                        // Center
                        Rectangle()
                            .fill(Color.gray)
                            .frame(width: 20, height: 12)
                        
                        // Right side
                        ForEach(addedPlates, id: \.self) { weight in
                            PlateVisual(weight: weight)
                        }
                        Spacer()
                    }
                }
                .frame(height: 150)
                
                Spacer()
                
                // Plate Buttons (to add)
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        // Standard Lbs Plates: 45, 35, 25, 10, 5, 2.5
                        ForEach([45.0, 35.0, 25.0, 10.0, 5.0, 2.5], id: \.self) { weight in
                            Button(action: {
                                withAnimation {
                                    addedPlates.append(weight)
                                }
                                updateParentWeight()
                            }) {
                                PlateButton(weight: weight)
                            }
                        }
                    }
                    .padding()
                }
                
                // Controls
                HStack {
                    Button(action: {
                        if !addedPlates.isEmpty {
                            withAnimation {
                                _ = addedPlates.popLast()
                            }
                            updateParentWeight()
                        }
                    }) {
                        Image(systemName: "arrow.uturn.backward")
                            .font(.title)
                            .foregroundColor(.orange)
                            .frame(width: 60, height: 60)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                    
                    Spacer()
                    
                    Button(action: {
                        withAnimation {
                            addedPlates = []
                        }
                        updateParentWeight()
                    }) {
                        Image(systemName: "trash")
                            .font(.title)
                            .foregroundColor(.red)
                            .frame(width: 60, height: 60)
                            .background(Color.white.opacity(0.1))
                            .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 40)
                .padding(.bottom)
            }
            .background(Color.appBackground)
            .navigationBarHidden(true)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { isPresented = false }
                }
            }
        }
    }
    
    func updateParentWeight() {
        // Update the binding string
        weightInput = String(format: "%.1f", totalWeight)
    }
}

struct PlateVisual: View {
    let weight: Double
    
    var color: Color {
        switch weight {
        case 45: return .blue
        case 35: return .yellow
        case 25: return .green
        case 10: return .white
        case 5: return .red
        case 2.5: return .gray
        default: return .gray
        }
    }
    
    var height: CGFloat {
        switch weight {
        case 45: return 100
        case 35: return 90
        case 25: return 80
        case 10: return 60
        case 5: return 50
        case 2.5: return 40
        default: return 40
        }
    }
    
    var body: some View {
        RoundedRectangle(cornerRadius: 2)
            .fill(color)
            .frame(width: 8, height: height)
            .overlay(
                RoundedRectangle(cornerRadius: 2)
                    .stroke(Color.black.opacity(0.2), lineWidth: 1)
            )
    }
}

struct PlateButton: View {
    let weight: Double
    
    var color: Color {
        switch weight {
        case 45: return .blue
        case 35: return .yellow
        case 25: return .green
        case 10: return .white
        case 5: return .red
        case 2.5: return .gray
        default: return .gray
        }
    }
    
    var body: some View {
        ZStack {
            Circle()
                .fill(color)
                .frame(width: 70, height: 70)
                .shadow(radius: 5)
            
            Text("\(Int(weight))")
                .font(.headline)
                .foregroundColor(weight == 10 || weight == 5 ? .black : .white)
        }
    }
}
