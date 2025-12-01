import SwiftUI

struct ExerciseSelectorView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var viewModel: GymViewModel
    @Binding var selectedExerciseID: UUID?
    
    @State private var searchText = ""
    @State private var selectedMuscle: MuscleGroup? = nil
    @State private var showingAddSheet = false
    @State private var newExerciseName = ""
    @State private var newExerciseMuscle: MuscleGroup = .chest
    
    var filteredExercises: [ExerciseDefinition] {
        let exercises = selectedMuscle == nil ? viewModel.availableExercises : viewModel.availableExercises.filter { $0.muscleGroup == selectedMuscle }
        
        if searchText.isEmpty {
            return exercises
        } else {
            return exercises.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                // Search Bar Custom
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    TextField("Buscar ejercicio...", text: $searchText)
                        .foregroundColor(.white)
                    if !searchText.isEmpty {
                        Button(action: { searchText = "" }) {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color(hex: "1C1C1E"))
                .cornerRadius(10)
                .padding()
                
                // Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Button(action: { selectedMuscle = nil }) {
                            Text("Todos")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(selectedMuscle == nil ? Color.neonGreen : Color(hex: "1C1C1E"))
                                .foregroundColor(selectedMuscle == nil ? .black : .white)
                                .cornerRadius(20)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 20)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: selectedMuscle == nil ? 0 : 1)
                                )
                        }
                        
                        ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                            Button(action: { selectedMuscle = muscle }) {
                                Text(muscle.rawValue)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(selectedMuscle == muscle ? muscle.color : Color(hex: "1C1C1E"))
                                    .foregroundColor(selectedMuscle == muscle ? .black : .white)
                                    .cornerRadius(20)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 20)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: selectedMuscle == muscle ? 0 : 1)
                                    )
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 10)
                }
                
                // List
                List {
                    ForEach(filteredExercises) { exercise in
                        Button(action: {
                            selectedExerciseID = exercise.id
                            dismiss()
                        }) {
                            HStack {
                                Circle()
                                    .fill(exercise.color)
                                    .frame(width: 12, height: 12)
                                
                                Text(exercise.name)
                                    .font(.body)
                                    .foregroundColor(.white)
                                
                                Spacer()
                                
                                if selectedExerciseID == exercise.id {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.neonGreen)
                                }
                            }
                            .padding(.vertical, 4)
                        }
                        .listRowBackground(Color.clear)
                        .listRowSeparatorTint(Color.gray.opacity(0.2))
                    }
                }
                .listStyle(.plain)
            }
            .background(Color.appBackground)
            .navigationTitle("Seleccionar Ejercicio")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancelar") {
                        dismiss()
                    }
                    .foregroundColor(.white)
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        newExerciseMuscle = selectedMuscle ?? .chest
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                            .foregroundColor(.neonGreen)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationView {
                    Form {
                        Section(header: Text("Detalles")) {
                            TextField("Nombre (ej: Press Banca)", text: $newExerciseName)
                            Picker("Grupo Muscular", selection: $newExerciseMuscle) {
                                ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                                    Text(muscle.rawValue).tag(muscle)
                                }
                            }
                        }
                    }
                    .navigationTitle("Nuevo Ejercicio")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .cancellationAction) {
                            Button("Cancelar") {
                                showingAddSheet = false
                                newExerciseName = ""
                            }
                        }
                        ToolbarItem(placement: .confirmationAction) {
                            Button("Guardar") {
                                saveNewExercise()
                            }
                            .disabled(newExerciseName.isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    func saveNewExercise() {
        guard !newExerciseName.isEmpty else { return }
        
        viewModel.addNewExercise(name: newExerciseName, muscleGroup: newExerciseMuscle)
        
        // Optionally select it immediately
        // We might need a slight delay or check if it was added successfully, 
        // but for now we assume it works as per previous logic.
        // Re-fetching or finding the new one might be tricky if it's async, 
        // but local array usually updates fast if it's a snapshot listener.
        // Let's try to find it.
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            if let newEx = viewModel.availableExercises.first(where: { $0.name == newExerciseName }) {
                selectedExerciseID = newEx.id
                dismiss()
            }
        }
        
        newExerciseName = ""
        showingAddSheet = false
    }
}
