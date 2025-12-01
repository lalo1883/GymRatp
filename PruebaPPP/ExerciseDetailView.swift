import SwiftUI

struct ExerciseDetailView: View {
    @Binding var exercise: ExerciseDefinition
    // Inject ViewModel to save changes
    var viewModel: GymViewModel?
    @Environment(\.dismiss) var dismiss
    
    @State private var targetWeight: String = ""
    @State private var targetReps: String = ""
    @State private var targetSets: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Información")) {
                    TextField("Nombre del Ejercicio", text: $exercise.name)
                    Picker("Grupo Muscular", selection: $exercise.muscleGroup) {
                        ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                            Text(muscle.rawValue).tag(muscle)
                        }
                    }
                    ColorPicker("Color", selection: $exercise.color)
                }
                
                Section(header: Text("Meta Personal")) {
                    Text("Define un objetivo para este ejercicio y sigue tu progreso en el Dashboard.")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .listRowBackground(Color.clear)
                    
                    HStack {
                        Text("Peso Objetivo")
                        Spacer()
                        TextField("0", text: $targetWeight)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Reps Objetivo")
                        Spacer()
                        TextField("0", text: $targetReps)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("Sets Objetivo")
                        Spacer()
                        TextField("0", text: $targetSets)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
            }
            .toolbar {
                ToolbarItemGroup(placement: .keyboard) {
                    Spacer()
                    Button("Listo") {
                        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                    }
                    .foregroundColor(.neonGreen)
                }
            }
            .navigationTitle("Editar Ejercicio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Guardar") {
                        saveChanges()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") { dismiss() }
                }
            }
            .onAppear {
                if let w = exercise.targetWeight {
                    // Convert stored Kg to user unit for display
                    if let vm = viewModel, vm.weightUnit == "lbs" {
                        let lbs = w * 2.20462
                        targetWeight = String(format: "%.1f", lbs)
                    } else {
                        targetWeight = String(format: "%.1f", w)
                    }
                }
                if let r = exercise.targetReps { targetReps = String(r) }
                if let s = exercise.targetSets { targetSets = String(s) }
            }
        }
    }
    
    func saveChanges() {
        // 1. Clean inputs
        let wString = targetWeight.trimmingCharacters(in: .whitespacesAndNewlines)
            .replacingOccurrences(of: ",", with: ".")
        let rString = targetReps.trimmingCharacters(in: .whitespacesAndNewlines)
        let sString = targetSets.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // 2. Parse Weight (Always treat dot as decimal)
        if wString.isEmpty {
            exercise.targetWeight = nil
        } else if let w = Double(wString) {
            // Convert input to Kg if user is in Lbs
            if let vm = viewModel, vm.weightUnit == "lbs" {
                exercise.targetWeight = w / 2.20462
            } else {
                exercise.targetWeight = w
            }
        }
        
        // 3. Parse Reps
        if rString.isEmpty {
            exercise.targetReps = nil
        } else if let r = Int(rString) {
            exercise.targetReps = r
        } else if let rDouble = Double(rString) { // Handle 10.0 case
            exercise.targetReps = Int(rDouble)
        }
        
        // 4. Parse Sets
        if sString.isEmpty {
            exercise.targetSets = nil
        } else if let s = Int(sString) {
            exercise.targetSets = s
        } else if let sDouble = Double(sString) { // Handle 4.0 case
            exercise.targetSets = Int(sDouble)
        }
        
        // 5. Save to Firestore
        if let vm = viewModel {
            vm.updateExercise(exercise)
        } else {
            print("Error: ViewModel is nil")
        }
    }
}
