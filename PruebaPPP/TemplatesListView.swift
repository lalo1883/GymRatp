import SwiftUI

struct TemplatesListView: View {
    @ObservedObject var viewModel: GymViewModel
    @State private var showingAddTemplate = false
    @State private var newTemplateName = ""
    @State private var selectedExercises: Set<UUID> = []
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.templates.isEmpty {
                    ContentUnavailableView("Sin Rutinas", systemImage: "clipboard", description: Text("Crea plantillas para tus entrenamientos frecuentes."))
                } else {
                    ForEach(viewModel.templates) { template in
                        VStack(alignment: .leading) {
                            Text(template.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("\(template.exercises.count) ejercicios")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .listRowBackground(Color.cardBackground)
                    }
                    .onDelete(perform: viewModel.deleteTemplate)
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Mis Rutinas")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddTemplate = true }) {
                        Image(systemName: "plus")
                            .fontWeight(.bold)
                            .foregroundColor(.neonGreen)
                    }
                }
            }
            .sheet(isPresented: $showingAddTemplate) {
                CreateTemplateView(viewModel: viewModel, isPresented: $showingAddTemplate)
            }
        }
    }
}

struct CreateTemplateView: View {
    @ObservedObject var viewModel: GymViewModel
    @Binding var isPresented: Bool
    @State private var templateName = ""
    @State private var showingAddExerciseAlert = false
    @State private var newExerciseName = ""
    @State private var selectedExercises: [UUID] = [] // Ordered list
    
    // Filtering & New Exercise
    @State private var selectedMuscle: MuscleGroup? = nil
    @State private var showingAddSheet = false
    @State private var newExerciseMuscle: MuscleGroup = .chest
    
    var filteredExercises: [ExerciseDefinition] {
        if let muscle = selectedMuscle {
            return viewModel.availableExercises.filter { $0.muscleGroup == muscle }
        } else {
            return viewModel.availableExercises
        }
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Nombre de la Rutina")) {
                    TextField("Ej: Pierna Lunes", text: $templateName)
                }
                
                Section(header: HStack {
                    Text("Ejercicios")
                    Spacer()
                    Button(action: {
                        newExerciseMuscle = selectedMuscle ?? .chest
                        showingAddSheet = true
                    }) {
                        Label("Nuevo", systemImage: "plus")
                            .font(.caption)
                            .foregroundColor(.neonGreen)
                    }
                }) {
                    // Filter Chips
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            Button(action: { selectedMuscle = nil }) {
                                Text("Todos")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 6)
                                    .padding(.horizontal, 12)
                                    .background(selectedMuscle == nil ? Color.neonGreen : Color.gray.opacity(0.2))
                                    .foregroundColor(selectedMuscle == nil ? .black : .white)
                                    .cornerRadius(15)
                            }
                            
                            ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                                Button(action: { selectedMuscle = muscle }) {
                                    Text(muscle.rawValue)
                                        .font(.caption)
                                        .fontWeight(.bold)
                                        .padding(.vertical, 6)
                                        .padding(.horizontal, 12)
                                        .background(selectedMuscle == muscle ? muscle.color : Color.gray.opacity(0.2))
                                        .foregroundColor(selectedMuscle == muscle ? .black : .white)
                                        .cornerRadius(15)
                                }
                            }
                        }
                        .padding(.vertical, 5)
                    }
                    .listRowInsets(EdgeInsets())
                    .listRowBackground(Color.clear)
                    
                    ForEach(filteredExercises) { exercise in
                        HStack {
                            Text(exercise.name)
                            Spacer()
                            if selectedExercises.contains(exercise.id) {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundColor(.neonGreen)
                            } else {
                                Image(systemName: "circle")
                                    .foregroundColor(.gray)
                            }
                        }
                        .contentShape(Rectangle())
                        .onTapGesture {
                            if let index = selectedExercises.firstIndex(of: exercise.id) {
                                selectedExercises.remove(at: index)
                            } else {
                                selectedExercises.append(exercise.id)
                            }
                        }
                    }
                    
                    Button(action: {
                        newExerciseMuscle = selectedMuscle ?? .chest
                        showingAddSheet = true
                    }) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                                .foregroundColor(.neonGreen)
                            Text("Crear nuevo ejercicio")
                                .foregroundColor(.neonGreen)
                        }
                    }
                }
            }
            .navigationTitle("Nueva Rutina")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { isPresented = false }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveTemplate()
                    }
                    .disabled(templateName.isEmpty || selectedExercises.isEmpty)
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                NavigationView {
                    Form {
                        Section(header: Text("Detalles")) {
                            TextField("Nombre (ej: Curl de Bíceps)", text: $newExerciseName)
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
                                if !newExerciseName.isEmpty {
                                    viewModel.addNewExercise(name: newExerciseName, muscleGroup: newExerciseMuscle)
                                    // Auto-select the new exercise
                                    // We assume it's added to the end or we find it by name
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                        if let newEx = viewModel.availableExercises.first(where: { $0.name == newExerciseName }) {
                                            selectedExercises.append(newEx.id)
                                        }
                                        newExerciseName = ""
                                        showingAddSheet = false
                                    }
                                }
                            }
                            .disabled(newExerciseName.isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
        }
    }
    
    func saveTemplate() {
        let templateExercises = selectedExercises.map { id in
            TemplateExercise(definitionID: id, sets: 4, reps: 10) // Default values
        }
        let newTemplate = WorkoutTemplate(name: templateName, exercises: templateExercises)
        viewModel.addTemplate(newTemplate)
        isPresented = false
    }
}
