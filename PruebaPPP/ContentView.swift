import SwiftUI
import Charts
import FirebaseFirestore


// MARK: - EXTENSIONS
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (1, 1, 1, 0)
        }

        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
    
    func toHex() -> String? {
        let uic = UIColor(self)
        guard let components = uic.cgColor.components, components.count >= 3 else {
            return nil
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        var a = Float(1.0)
        
        if components.count >= 4 {
            a = Float(components[3])
        }
        
        if a != 1.0 {
            return String(format: "%02lX%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255), lroundf(a * 255))
        } else {
            return String(format: "%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
        }
    }
}

// MARK: - MODELOS DE DATOS FLEXIBLES

enum MuscleGroup: String, CaseIterable, Codable {
    case chest = "Pecho"
    case back = "Espalda"
    case legs = "Pierna"
    case shoulders = "Hombro"
    case arms = "Brazos"
    case core = "Core"
    case cardio = "Cardio"
    case other = "Otro"
    
    var color: Color {
        switch self {
        case .chest: return .red
        case .back: return .blue
        case .legs: return .green
        case .shoulders: return .orange
        case .arms: return .purple
        case .core: return .yellow
        case .cardio: return .pink
        case .other: return .gray
        }
    }
}

// Define qué es un ejercicio (Nombre y Color de identificación)
struct ExerciseDefinition: Identifiable, Hashable, Codable {
    var id = UUID()
    var name: String
    var colorHex: String // Stored as Hex
    var muscleGroup: MuscleGroup
    var targetWeight: Double?
    var targetReps: Int?
    var targetSets: Int?
    
    var color: Color {
        get { Color(hex: colorHex) }
        set { colorHex = newValue.toHex() ?? "FFFFFF" }
    }
    
    init(id: UUID = UUID(), name: String, color: Color, muscleGroup: MuscleGroup, targetWeight: Double? = nil, targetReps: Int? = nil, targetSets: Int? = nil) {
        self.id = id
        self.name = name
        self.colorHex = color.toHex() ?? "FFFFFF"
        self.muscleGroup = muscleGroup
        self.targetWeight = targetWeight
        self.targetReps = targetReps
        self.targetSets = targetSets
    }
}

// Representa un set individual
struct ExerciseSet: Identifiable, Hashable, Codable {
    var id = UUID()
    var weight: Double
    var reps: Int
    var rpe: Int? // Rate of Perceived Exertion (1-10)
    var isDropSet: Bool = false
    var isSuperSet: Bool = false
}

// Representa un ejercicio realizado en una sesión (colección de sets)
struct Exercise: Identifiable, Hashable, Codable {
    var id = UUID()
    let definition: ExerciseDefinition // Link al tipo de ejercicio
    var sets: [ExerciseSet] // Lista de sets realizados
}

struct WorkoutSession: Identifiable, Hashable, Codable {
    var id = UUID()
    let date: Date
    var duration: TimeInterval = 0 // Duration in seconds
    let exercises: [Exercise]
    
    var totalVolume: Double {
        exercises.reduce(0) { exerciseTotal, exercise in
            exerciseTotal + exercise.sets.reduce(0) { setTotal, set in
                setTotal + (set.weight * Double(set.reps))
            }
        }
    }
}

// MARK: - TEMPLATES (RUTINAS)

struct TemplateExercise: Identifiable, Hashable, Codable {
    let id = UUID()
    let definitionID: UUID
    let sets: Int
    let reps: Int
}

struct WorkoutTemplate: Identifiable, Hashable, Codable {
    let id = UUID()
    var name: String
    var exercises: [TemplateExercise]
}

// MARK: - VIEW MODEL

import FirebaseAuth

// ... (previous code)

class GymViewModel: ObservableObject {
    @Published var sessions: [WorkoutSession] = []
    @Published var availableExercises: [ExerciseDefinition] = []
    @Published var templates: [WorkoutTemplate] = [] // Nuevas plantillas
    @Published var muscleGoals: [MuscleGroup: Int] = [:] // Metas semanales (sets)
    @AppStorage("weightUnit") var weightUnit: String = "kg" // "kg" or "lbs"
    @AppStorage("defaultRestTime") var defaultRestTime: Int = 90
    @AppStorage("enableSound") var enableSound: Bool = true
    @AppStorage("enableHaptics") var enableHaptics: Bool = true
    
    private var db = Firestore.firestore()
    private var userId: String? { Auth.auth().currentUser?.uid }
    
    init() {
        fetchData()
        initializeGoals()
    }
    
    func fetchData() {
        guard let uid = userId else { return }
        
        // Listen to Exercises
        db.collection("users").document(uid).collection("exercises").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else { return }
            self.availableExercises = documents.compactMap { try? $0.data(as: ExerciseDefinition.self) }
            
            // If no exercises, create defaults
            if self.availableExercises.isEmpty {
                self.createDefaultExercises()
            } else {
                // Clean up duplicates if any exist
                self.deduplicateExercises()
            }
        }
        
        // Listen to Sessions
        db.collection("users").document(uid).collection("sessions").order(by: "date", descending: true).addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else { return }
            self.sessions = documents.compactMap { try? $0.data(as: WorkoutSession.self) }
        }
        
        // Listen to Templates
        db.collection("users").document(uid).collection("templates").addSnapshotListener { querySnapshot, error in
            guard let documents = querySnapshot?.documents else { return }
            self.templates = documents.compactMap { try? $0.data(as: WorkoutTemplate.self) }
        }
    }
    
    func initializeGoals() {
        for group in MuscleGroup.allCases {
            muscleGoals[group] = 10 // Default 10 sets per week
        }
    }
    
    // MARK: - Unit Helpers
    func displayWeight(_ kg: Double) -> String {
        if weightUnit == "lbs" {
            return String(format: "%.1f", kg * 2.20462)
        } else {
            return String(format: "%.1f", kg)
        }
    }
    
    func inputWeight(_ value: Double) -> Double {
        if weightUnit == "lbs" {
            return value / 2.20462
        } else {
            return value
        }
    }
    
    func unitLabel() -> String {
        return weightUnit == "lbs" ? "lbs" : "kg"
    }
    
    func convertWeight(_ kg: Double) -> Double {
        if weightUnit == "lbs" {
            return kg * 2.20462
        } else {
            return kg
        }
    }
    
    // 1. Cargar ejercicios predeterminados
    private func createDefaultExercises() {
        let defaults = [
            ExerciseDefinition(name: "Press Banca", color: .neonBlue, muscleGroup: .chest),
            ExerciseDefinition(name: "Sentadilla", color: .neonGreen, muscleGroup: .legs),
            ExerciseDefinition(name: "Peso Muerto", color: .red, muscleGroup: .back),
            ExerciseDefinition(name: "Press Militar", color: .orange, muscleGroup: .shoulders),
            ExerciseDefinition(name: "Remo con Barra", color: .purple, muscleGroup: .back),
            ExerciseDefinition(name: "Curl de Bíceps", color: .pink, muscleGroup: .arms)
        ]
        
        for ex in defaults {
            addNewExercise(name: ex.name, muscleGroup: ex.muscleGroup, color: ex.color)
        }
    }
    
    // 2. Crear un nuevo ejercicio personalizado
    func addNewExercise(name: String, muscleGroup: MuscleGroup = .other, color: Color? = nil) {
        guard let uid = userId else { return }
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Prevent duplicates (Robust check: Case insensitive, Diacritic insensitive, Trimmed)
        if availableExercises.contains(where: { 
            $0.name.trimmingCharacters(in: .whitespacesAndNewlines)
                .compare(trimmedName, options: [.caseInsensitive, .diacriticInsensitive]) == .orderedSame 
        }) {
            return
        }
        
        let colors: [Color] = [.blue, .green, .orange, .pink, .purple, .yellow, .teal]
        let newExercise = ExerciseDefinition(name: trimmedName, color: color ?? (colors.randomElement() ?? .neonGreen), muscleGroup: muscleGroup)
        
        do {
            try db.collection("users").document(uid).collection("exercises").addDocument(from: newExercise)
        } catch {
            print("Error adding exercise: \(error)")
        }
    }
    
    // Función para limpiar duplicados existentes
    func deduplicateExercises() {
        guard let uid = userId else { return }
        
        var uniqueNames = Set<String>()
        var duplicates = [ExerciseDefinition]()
        
        for exercise in availableExercises {
            let normalizedName = exercise.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() 
            // Could use more robust normalization key if needed, but lowercased+trimmed is usually enough for exact dupes
            
            if uniqueNames.contains(normalizedName) {
                duplicates.append(exercise)
            } else {
                uniqueNames.insert(normalizedName)
            }
        }
        
        // Delete duplicates from Firestore
        for duplicate in duplicates {
            db.collection("users").document(uid).collection("exercises").whereField("id", isEqualTo: duplicate.id.uuidString).getDocuments { snapshot, error in
                snapshot?.documents.first?.reference.delete()
            }
        }
    }
    
    func updateExercise(_ exercise: ExerciseDefinition) {
        guard let uid = userId else { return }
        
        // Find the document with the matching internal ID field
        db.collection("users").document(uid).collection("exercises")
            .whereField("id", isEqualTo: exercise.id.uuidString)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("Error finding exercise to update: \(error)")
                    return
                }
                
                if let document = snapshot?.documents.first {
                    // Update the existing document found
                    do {
                        try document.reference.setData(from: exercise)
                        print("Exercise updated successfully")
                    } catch {
                        print("Error writing exercise update: \(error)")
                    }
                } else {
                    print("Exercise document not found for update. ID: \(exercise.id)")
                }
            }
    }
    
    // 3. Borrar ejercicios de la lista
    func deleteExercise(at offsets: IndexSet) {
        guard let uid = userId else { return }
        offsets.map { availableExercises[$0] }.forEach { exercise in
            db.collection("users").document(uid).collection("exercises").whereField("id", isEqualTo: exercise.id.uuidString).getDocuments { snapshot, error in
                snapshot?.documents.first?.reference.delete()
            }
        }
    }
    
    // 4. Gestión de Plantillas
    func addTemplate(_ template: WorkoutTemplate) {
        guard let uid = userId else { return }
        do {
            try db.collection("users").document(uid).collection("templates").addDocument(from: template)
        } catch {
            print("Error adding template: \(error)")
        }
    }
    
    func deleteTemplate(at offsets: IndexSet) {
        guard let uid = userId else { return }
        offsets.map { templates[$0] }.forEach { template in
            db.collection("users").document(uid).collection("templates").whereField("id", isEqualTo: template.id.uuidString).getDocuments { snapshot, error in
                snapshot?.documents.first?.reference.delete()
            }
        }
    }
    
    func addSession(_ session: WorkoutSession) {
        guard let uid = userId else { return }
        do {
            try db.collection("users").document(uid).collection("sessions").addDocument(from: session)
        } catch {
            print("Error adding session: \(error)")
        }
    }
    
    func deleteSession(_ session: WorkoutSession) {
        guard let uid = userId else { return }
        guard let sessionID = session.id.uuidString as String? else { return }
        
        db.collection("users").document(uid).collection("sessions").whereField("id", isEqualTo: sessionID).getDocuments { snapshot, error in
            snapshot?.documents.first?.reference.delete()
        }
    }
    
    func getProgress(for definition: ExerciseDefinition) -> [(date: Date, weight: Double)] {
        var data: [(Date, Double)] = []
        for session in sessions.reversed() {
            // Buscamos si este ejercicio específico se hizo en esta sesión
            if let exercise = session.exercises.first(where: { $0.definition.id == definition.id }) {
                // Usamos el peso máximo de la sesión
                let maxWeight = exercise.sets.map { $0.weight }.max() ?? 0
                data.append((session.date, maxWeight))
            }
        }
        return data
    }
    
    func isNewPR(exercise: Exercise) -> Bool {
        let history = getProgress(for: exercise.definition)
        // Si no hay historial previo, es PR
        guard !history.isEmpty else { return true }
        
        // El maximo anterior
        let maxWeight = history.map { $0.weight }.max() ?? 0
        let currentMax = exercise.sets.map { $0.weight }.max() ?? 0
        return currentMax > maxWeight
    }
    
    // Helper para Ghost Text
    func getLastSessionData(for exerciseID: UUID) -> Exercise? {
        for session in sessions { // sessions está ordenada por fecha descendente (más reciente primero)
            if let lastExercise = session.exercises.first(where: { $0.definition.id == exerciseID }) {
                return lastExercise
            }
        }
        return nil
    }
    
    func getWeeklySetsData() -> [MuscleGroup: Double] {
        var data: [MuscleGroup: Double] = [:]
        let calendar = Calendar.current
        let oneWeekAgo = calendar.date(byAdding: .day, value: -7, to: Date())!
        
        for session in sessions where session.date >= oneWeekAgo {
            for exercise in session.exercises {
                data[exercise.definition.muscleGroup, default: 0] += Double(exercise.sets.count)
            }
        }
        return data
    }
    
    func getSessionsGroupedByMonth() -> [(key: String, sessions: [WorkoutSession])] {
        let grouped = Dictionary(grouping: sessions) { session in
            session.date.formatted(.dateTime.month(.wide).year())
        }
        
        // Sort keys by date (needs a bit of logic or just sort sessions first)
        // Since sessions are already sorted by date desc, we can just iterate and group manually to preserve order
        // Or sort the dictionary keys based on a date parser.
        
        // Simpler approach:
        var result: [(String, [WorkoutSession])] = []
        var currentKey = ""
        var currentSessions: [WorkoutSession] = []
        
        for session in sessions { // Assumes sessions are sorted desc
            let key = session.date.formatted(.dateTime.month(.wide).year().locale(Locale(identifier: "es_ES")))
            if key != currentKey {
                if !currentKey.isEmpty {
                    result.append((currentKey, currentSessions))
                }
                currentKey = key
                currentSessions = [session]
            } else {
                currentSessions.append(session)
            }
        }
        if !currentKey.isEmpty {
            result.append((currentKey, currentSessions))
        }
        return result
    }
    
    func getWeeklySummary() -> (currentVolume: Double, previousVolume: Double, currentTime: TimeInterval, previousTime: TimeInterval) {
        let calendar = Calendar.current
        let now = Date()
        let startOfThisWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now))!
        let startOfLastWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: startOfThisWeek)!
        let endOfLastWeek = startOfThisWeek
        
        var currentVol: Double = 0
        var prevVol: Double = 0
        var currentTime: TimeInterval = 0
        var prevTime: TimeInterval = 0
        
        for session in sessions {
            if session.date >= startOfThisWeek {
                currentVol += session.totalVolume
                currentTime += session.duration
            } else if session.date >= startOfLastWeek && session.date < endOfLastWeek {
                prevVol += session.totalVolume
                prevTime += session.duration
            }
        }
        
        return (currentVol, prevVol, currentTime, prevTime)
    }
    
    func addMockData() {
        // Solo añadir datos si está vacío
        if !sessions.isEmpty { return }
        
        let benchPress = availableExercises.first(where: { $0.name == "Press Banca" })!
        let squat = availableExercises.first(where: { $0.name == "Sentadilla" })!
        
        // Sesión 1: Hace 3 días
        let session1 = WorkoutSession(
            date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!,
            duration: 3600,
            exercises: [
                Exercise(definition: benchPress, sets: [
                    ExerciseSet(weight: 60, reps: 10, rpe: 7),
                    ExerciseSet(weight: 60, reps: 10, rpe: 8),
                    ExerciseSet(weight: 60, reps: 10, rpe: 8)
                ]),
                Exercise(definition: squat, sets: [
                    ExerciseSet(weight: 80, reps: 8, rpe: 8),
                    ExerciseSet(weight: 80, reps: 8, rpe: 9),
                    ExerciseSet(weight: 80, reps: 8, rpe: 9)
                ])
            ]
        )
        
        // Sesión 2: Hoy
        let session2 = WorkoutSession(
            date: Date(),
            duration: 4200,
            exercises: [
                Exercise(definition: benchPress, sets: [
                    ExerciseSet(weight: 65, reps: 8, rpe: 8),
                    ExerciseSet(weight: 65, reps: 8, rpe: 9),
                    ExerciseSet(weight: 65, reps: 8, rpe: 9)
                ]),
                Exercise(definition: squat, sets: [
                    ExerciseSet(weight: 85, reps: 5, rpe: 9),
                    ExerciseSet(weight: 85, reps: 5, rpe: 9),
                    ExerciseSet(weight: 85, reps: 5, rpe: 10)
                ])
            ]
        )
        
        sessions = [session1, session2]
    }
}

// MARK: - VISTAS PRINCIPALES

struct ContentView: View {
    @StateObject var viewModel = GymViewModel()
    @StateObject var timerManager = TimerManager()
    @State private var showConfetti = false
    
    init() {
        UITabBar.appearance().unselectedItemTintColor = UIColor.gray
    }
    
    var body: some View {
        ZStack(alignment: .top) {
            TabView {
                DashboardView(viewModel: viewModel)
                    .tabItem {
                        Label("Progreso", systemImage: "chart.xyaxis.line")
                    }
                
                HistoryView(viewModel: viewModel)
                    .tabItem {
                        Label("Historial", systemImage: "list.bullet.clipboard")
                    }
                
                AddWorkoutView(viewModel: viewModel, timerManager: timerManager, showConfetti: $showConfetti)
                    .tabItem {
                        Label("Registrar", systemImage: "plus.circle.fill")
                    }
                
                ExercisesListView(viewModel: viewModel) // Nueva pestaña
                    .tabItem {
                        Label("Ejercicios", systemImage: "dumbbell.fill")
                    }
                
                TemplatesListView(viewModel: viewModel)
                    .tabItem {
                        Label("Rutinas", systemImage: "clipboard.fill")
                    }
            }
            .preferredColorScheme(.dark)
            .tint(Color.neonGreen)
            
            // Rest Timer Overlay
            if timerManager.isActive {
                RestTimerView(timerManager: timerManager)
                    .padding(.top, 50) // Adjust for dynamic island / notch
                    .zIndex(1)
            }
            
            // Confetti Overlay
            if showConfetti {
                ConfettiView()
                    .allowsHitTesting(false)
                    .zIndex(2)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            showConfetti = false
                        }
                    }
            }
        }
        .onOpenURL { url in
            if url.absoluteString == "gymapp://startRest" {
                timerManager.startTimer()
            }
        }
    }
}

// MARK: - NUEVA PANTALLA: LISTA DE EJERCICIOS

struct ExercisesListView: View {
    @ObservedObject var viewModel: GymViewModel
    @State private var showingAddSheet = false
    @State private var newExerciseName = ""
    @State private var newExerciseMuscle: MuscleGroup = .chest
    @State private var selectedExerciseToEdit: ExerciseDefinition?
    
    @State private var selectedMuscle: MuscleGroup? = nil
    @State private var searchText = "" // 1. Search Text
    
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
            VStack {
                // Filter Chips
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 10) {
                        Button(action: { selectedMuscle = nil }) {
                            Text("Todos")
                                .font(.caption)
                                .fontWeight(.bold)
                                .padding(.vertical, 8)
                                .padding(.horizontal, 16)
                                .background(selectedMuscle == nil ? Color.neonGreen : Color.cardBackground)
                                .foregroundColor(selectedMuscle == nil ? .black : .white)
                                .cornerRadius(20)
                        }
                        
                        ForEach(MuscleGroup.allCases, id: \.self) { muscle in
                            Button(action: { selectedMuscle = muscle }) {
                                Text(muscle.rawValue)
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .padding(.vertical, 8)
                                    .padding(.horizontal, 16)
                                    .background(selectedMuscle == muscle ? muscle.color : Color.cardBackground)
                                    .foregroundColor(selectedMuscle == muscle ? .black : .white)
                                    .cornerRadius(20)
                            }
                        }
                    }
                    .padding(.horizontal)
                    .padding(.top, 10)
                }
                
                // 2. List with Card Style
                List {
                    ForEach(filteredExercises) { exercise in
                        Button(action: {
                            selectedExerciseToEdit = exercise
                        }) {
                            HStack(spacing: 15) {
                                // Icon / Color Indicator
                                ZStack {
                                    Circle()
                                        .fill(exercise.color.opacity(0.2))
                                        .frame(width: 45, height: 45)
                                    
                                    Circle()
                                        .fill(exercise.color)
                                        .frame(width: 15, height: 15)
                                        .shadow(color: exercise.color.opacity(0.5), radius: 5)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(exercise.name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    
                                    Text(exercise.muscleGroup.rawValue)
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                
                                Spacer()
                                
                                // Goal Indicator
                                if exercise.targetWeight != nil {
                                    HStack(spacing: 4) {
                                        Image(systemName: "flag.fill")
                                            .font(.caption2)
                                        Text("Meta")
                                            .font(.caption2)
                                            .fontWeight(.bold)
                                    }
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(Color.neonGreen.opacity(0.2))
                                    .foregroundColor(.neonGreen)
                                    .cornerRadius(8)
                                }
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.gray.opacity(0.5))
                            }
                            .padding()
                            .background(Color(hex: "1C1C1E")) // Card Background
                            .cornerRadius(16)
                            .shadow(color: Color.black.opacity(0.2), radius: 5, x: 0, y: 2)
                        }
                        .listRowBackground(Color.clear) // Transparent row
                        .listRowSeparator(.hidden) // No separators
                        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16)) // Spacing
                    }
                    .onDelete(perform: viewModel.deleteExercise) // 3. Swipe to Delete
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
                .background(Color.appBackground)
            }
            .background(Color.appBackground)
            .navigationTitle("Ejercicios")
            .searchable(text: $searchText, placement: .navigationBarDrawer(displayMode: .always), prompt: "Buscar ejercicio...") // 4. Search Bar
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        newExerciseMuscle = selectedMuscle ?? .chest
                        showingAddSheet = true
                    }) {
                        Image(systemName: "plus")
                            .fontWeight(.bold)
                            .foregroundColor(.neonGreen)
                    }
                }
                ToolbarItem(placement: .navigationBarLeading) {
                    EditButton() // Botón nativo para borrar
                        .foregroundColor(.neonBlue)
                }
            }
            // Alerta para añadir nuevo ejercicio
            // Sheet para añadir nuevo ejercicio
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
                                    newExerciseName = ""
                                    showingAddSheet = false
                                }
                            }
                            .disabled(newExerciseName.isEmpty)
                        }
                    }
                }
                .presentationDetents([.medium])
            }
            }
                .sheet(item: $selectedExerciseToEdit) { exercise in
                if let index = viewModel.availableExercises.firstIndex(where: { $0.id == exercise.id }) {
                    ExerciseDetailView(exercise: $viewModel.availableExercises[index], viewModel: viewModel)
                }
            }
        }
    }


// MARK: - DASHBOARD VIEW

struct DashboardView: View {
    @ObservedObject var viewModel: GymViewModel
    // Ahora seleccionamos un ExerciseDefinition en lugar de un Enum
    @State private var selectedExerciseID: UUID?
    @State private var showExerciseSelector = false
    @State private var showSettings = false
    @State private var showHelp = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 25) {
                    
                    // Selector de ejercicio Dinámico
                    if !viewModel.availableExercises.isEmpty {
                        Button(action: { showExerciseSelector = true }) {
                            HStack {
                                Text(getSelectedExerciseName())
                                    .font(.title2)
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .foregroundColor(.neonGreen)
                            }
                            .padding()
                            .background(Color.cardBackground)
                            .cornerRadius(12)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.neonGreen.opacity(0.3), lineWidth: 1)
                            )
                        }
                        .sheet(isPresented: $showExerciseSelector) {
                            ExerciseSelectorView(viewModel: viewModel, selectedExerciseID: $selectedExerciseID)
                        }
                    } else {
                        Text("Añade ejercicios para ver tu progreso")
                            .foregroundColor(.gray)
                            .padding()
                    }
                    
                    // TARGET PROGRESS CARD
                    if let exercise = getSelectedExercise(),
                       let targetWeight = exercise.targetWeight {
                        
                        let currentMax = viewModel.getProgress(for: exercise).last?.weight ?? 0
                        let progress = min(currentMax / targetWeight, 1.0)
                        
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Image(systemName: "target")
                                    .foregroundColor(.neonGreen)
                                Text("Meta: \(viewModel.displayWeight(targetWeight)) \(viewModel.unitLabel())")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                                Text("\(Int(progress * 100))%")
                                    .font(.title3)
                                    .fontWeight(.bold)
                                    .foregroundColor(.neonGreen)
                            }
                            
                            GeometryReader { geometry in
                                ZStack(alignment: .leading) {
                                    Rectangle()
                                        .frame(width: geometry.size.width, height: 10)
                                        .opacity(0.3)
                                        .foregroundColor(.gray)
                                    
                                    Rectangle()
                                        .frame(width: min(CGFloat(progress) * geometry.size.width, geometry.size.width), height: 10)
                                        .foregroundColor(.neonGreen)
                                }
                                .cornerRadius(5)
                            }
                            .frame(height: 10)
                            
                            if let reps = exercise.targetReps, let sets = exercise.targetSets {
                                Text("Objetivo: \(sets) sets de \(reps) reps")
                                    .font(.caption)
                                    .foregroundColor(.gray)
                            }
                        }
                        .padding()
                        .background(Color.cardBackground)
                        .cornerRadius(15)
                        .padding(.horizontal)
                    }
                    
                    // Weekly Summary
                    WeeklySummaryCard(summary: viewModel.getWeeklySummary(), unitLabel: viewModel.unitLabel())
                        .padding(.horizontal)
                    
                    // Heatmap
                    ConsistencyHeatmap(viewModel: viewModel)
                        .padding(.horizontal)
                    
                    // Radar Chart (Sets Semanales)
                    VStack(alignment: .leading) {
                        HStack {
                            Text("Sets Semanales vs Meta")
                                .font(.headline)
                                .foregroundColor(.gray)
                            Spacer()
                            Text("Últimos 7 días")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                        .padding(.bottom, 10)
                        
                        let muscleData = viewModel.getWeeklySetsData()
                        // Calculamos el máximo para escalar el gráfico
                        let maxSets = muscleData.values.max() ?? 10
                        let maxGoal = viewModel.muscleGoals.values.max() ?? 10
                        let maxValue = max(Double(maxSets), Double(maxGoal)) + 5 // Un poco de margen
                        
                        RadarChartView(data: muscleData, goals: viewModel.muscleGoals, maxValue: maxValue)
                            .frame(height: 300)
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // Time Chart


                    
                    // Tarjeta de Gráfica
                    VStack(alignment: .leading) {
                        Text("Progreso de Fuerza")
                            .font(.headline)
                            .foregroundColor(.gray)
                        
                        Text("Peso Máximo (\(viewModel.unitLabel()))")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        if let selected = getSelectedExercise(),
                           let data = Optional(viewModel.getProgress(for: selected)),
                           !data.isEmpty {
                            
                            Chart {
                                ForEach(data, id: \.date) { item in
                                    LineMark(
                                        x: .value("Fecha", item.date, unit: .day),
                                        y: .value("Peso", viewModel.convertWeight(item.weight))
                                    )
                                    .interpolationMethod(.catmullRom)
                                    .symbol(Circle())
                                    .foregroundStyle(LinearGradient(colors: [selected.color, selected.color.opacity(0.5)], startPoint: .top, endPoint: .bottom))
                                    
                                    AreaMark(
                                        x: .value("Fecha", item.date, unit: .day),
                                        y: .value("Peso", viewModel.convertWeight(item.weight))
                                    )
                                    .foregroundStyle(selected.color.opacity(0.1))
                                    .interpolationMethod(.catmullRom)
                                }
                                
                                if let target = selected.targetWeight {
                                    RuleMark(y: .value("Meta", viewModel.convertWeight(target)))
                                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5]))
                                        .foregroundStyle(Color.neonGreen)
                                        .annotation(position: .top, alignment: .leading) {
                                            Text("Meta")
                                                .font(.caption)
                                                .foregroundColor(.neonGreen)
                                        }
                                }
                            }
                            .frame(height: 250)
                            .chartYAxis { AxisMarks(position: .leading) }
                            
                        } else {
                            ContentUnavailableView("Sin datos", systemImage: "chart.line.downtrend.xyaxis", description: Text("No hay registros para este ejercicio."))
                                .frame(height: 250)
                        }
                    }
                    .padding()
                    .background(Color.cardBackground)
                    .cornerRadius(20)
                    .padding(.horizontal)
                    
                    // Stats
                    HStack(spacing: 15) {
                        StatCard(title: "Total Entrenos", value: "\(viewModel.sessions.count)", icon: "dumbbell.fill", color: .neonGreen)
                        StatCard(title: "Volumen Total", value: calculateTotalVolumeString(), icon: "scalemass.fill", color: .neonBlue)
                    }
                    .padding(.horizontal)
                    .padding(.bottom, 20)
                }
                .padding(.top)
            }
            .background(Color.appBackground)
            .navigationTitle("Dashboard")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showHelp = true }) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.neonBlue)
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showSettings = true }) {
                        Image(systemName: "gearshape.fill")
                            .foregroundColor(.neonGreen)
                    }
                }
            }
            .sheet(isPresented: $showSettings) {
                SettingsView(viewModel: viewModel)
            }
            .sheet(isPresented: $showHelp) {
                HelpView()
            }
            .onAppear {
                // Selecciona el primer ejercicio por defecto si no hay nada seleccionado
                if selectedExerciseID == nil, let first = viewModel.availableExercises.first {
                    selectedExerciseID = first.id
                }
            }
        }
    }
    
    // Helpers para obtener el objeto seleccionado basado en el ID
    func getSelectedExercise() -> ExerciseDefinition? {
        viewModel.availableExercises.first(where: { $0.id == selectedExerciseID })
    }
    
    func getSelectedExerciseName() -> String {
        getSelectedExercise()?.name ?? "Seleccionar Ejercicio"
    }
    
    func calculateTotalVolumeString() -> String {
        let total = viewModel.sessions.reduce(0) { $0 + $1.totalVolume }
        return String(format: "%.0f kg", total)
    }
}


// MARK: - HISTORIAL VIEW

struct HistoryView: View {
    @ObservedObject var viewModel: GymViewModel
    // @State private var sessionToShare: WorkoutSession? // Moved to DetailView
    
    var body: some View {
        NavigationView {
            List {
                if viewModel.sessions.isEmpty {
                    ContentUnavailableView("Sin Historial", systemImage: "clock.arrow.circlepath", description: Text("Tus entrenamientos guardados aparecerán aquí."))
                } else {
                    ForEach(viewModel.getSessionsGroupedByMonth(), id: \.key) { group in
                        Section(header: Text(group.key.capitalized).foregroundColor(.neonGreen)) {
                            ForEach(group.sessions) { session in
                                NavigationLink(destination: WorkoutDetailView(session: session, viewModel: viewModel)) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(session.date.formatted(date: .numeric, time: .shortened))
                                                .font(.headline)
                                                .foregroundColor(.white)
                                            
                                            Text("\(session.exercises.count) Ejercicios • \(formatDuration(session.duration))")
                                                .font(.caption)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                    }
                                    .padding(.vertical, 4)
                                }
                                .listRowBackground(Color.cardBackground)
                            }
                            .onDelete { indexSet in
                                for index in indexSet {
                                    let sessionToDelete = group.sessions[index]
                                    viewModel.deleteSession(sessionToDelete)
                                }
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(Color.appBackground)
            .navigationTitle("Historial")
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0m"
    }
}

struct WorkoutDetailView: View {
    let session: WorkoutSession
    @ObservedObject var viewModel: GymViewModel
    @State private var isSharing = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Header Stats
                HStack(spacing: 20) {
                    StatBadge(icon: "clock", value: formatDuration(session.duration), label: "Duración")
                    StatBadge(icon: "dumbbell.fill", value: "\(Int(session.totalVolume)) \(viewModel.unitLabel())", label: "Volumen")
                    StatBadge(icon: "flame.fill", value: "\(session.exercises.count)", label: "Ejercicios")
                }
                .padding(.top)
                
                // Exercises List
                VStack(spacing: 15) {
                    ForEach(session.exercises) { exercise in
                        VStack(alignment: .leading, spacing: 12) {
                            // Exercise Header
                            HStack {
                                Circle()
                                    .fill(exercise.definition.color)
                                    .frame(width: 10, height: 10)
                                Text(exercise.definition.name)
                                    .font(.headline)
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            
                            // Sets Grid
                            VStack(spacing: 8) {
                                ForEach(exercise.sets) { set in
                                    HStack {
                                        Text("\(viewModel.displayWeight(set.weight)) \(viewModel.unitLabel())")
                                            .fontWeight(.semibold)
                                            .foregroundColor(.white)
                                            .frame(width: 80, alignment: .leading)
                                        
                                        Text("x \(set.reps)")
                                            .foregroundColor(.gray)
                                        
                                        Spacer()
                                        
                                        if let rpe = set.rpe {
                                            Text("RPE \(rpe)")
                                                .font(.caption2)
                                                .padding(4)
                                                .background(rpeColor(rpe).opacity(0.2))
                                                .foregroundColor(rpeColor(rpe))
                                                .cornerRadius(4)
                                        }
                                    }
                                    .font(.subheadline)
                                }
                            }
                            .padding(.leading, 18)
                        }
                        .padding()
                        .background(Color(hex: "1C1C1E"))
                        .cornerRadius(12)
                    }
                }
                .padding(.horizontal)
            }
        }
        .background(Color.appBackground)
        .navigationTitle(session.date.formatted(date: .abbreviated, time: .shortened))
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { isSharing = true }) {
                    Image(systemName: "square.and.arrow.up")
                        .foregroundColor(.neonGreen)
                }
            }
        }
        .sheet(isPresented: $isSharing) {
            SocialShareView(session: session)
        }
    }
    
    func formatDuration(_ duration: TimeInterval) -> String {
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour, .minute]
        formatter.unitsStyle = .abbreviated
        return formatter.string(from: duration) ?? "0m"
    }
    
    func rpeColor(_ rpe: Int) -> Color {
        Double(rpe) > 8 ? .red : (Double(rpe) > 5 ? .yellow : .green)
    }
}

struct StatBadge: View {
    let icon: String
    let value: String
    let label: String
    
    var body: some View {
        VStack(spacing: 5) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.neonGreen)
            Text(value)
                .font(.headline)
                .foregroundColor(.white)
            Text(label)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(12)
    }
}

// MARK: - ADD WORKOUT VIEW

struct AddWorkoutView: View {
    @ObservedObject var viewModel: GymViewModel
    @ObservedObject var timerManager: TimerManager
    @Binding var showConfetti: Bool
    
    // Ahora almacenamos el ejercicio seleccionado, no el Enum
    @State private var selectedExerciseID: UUID?
    @State private var weightValue: Double = 0.0
    @State private var repsValue: Double = 0.0
    
    @State private var currentSets: [ExerciseSet] = [] // Sets del ejercicio actual
    
    @State private var currentDate = Date()
    @State private var tempExercises: [Exercise] = []
    @State private var showAlert = false
    @State private var showPlateCalculator = false
    @State private var showInverseCalculator = false
    @State private var show1RMCalculator = false
    
    // Nuevos Estados
    @State private var rpe: Double = 7.0 // 1-10
    @State private var isDropSet: Bool = false
    @State private var isSuperSet: Bool = false
    @State private var isFocusMode: Bool = false
    
    // New Exercise Alert
    @State private var showingAddExerciseAlert = false
    @State private var showExerciseSelector = false // New state for sheet
    @State private var newExerciseName = ""
    
    // Session Tracking
    @State private var sessionStartTime: Date?
    
    @State private var editingSetIndex: Int? = nil // Index of set being edited
    
    // Ghost Data (Previous session)
    var ghostData: Exercise? {
        guard let id = selectedExerciseID else { return nil }
        // Logic to find last session's exercise data
        // For simplicity, just finding the last occurrence in history
        for session in viewModel.sessions.reversed() {
            if let exercise = session.exercises.first(where: { $0.definition.id == id }) {
                return exercise
            }
        }
        return nil
    }
    
    var isAddSetDisabled: Bool {
        repsValue == 0 || selectedExerciseID == nil
    }
    
    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                ScrollView {
                    VStack(spacing: 20) {
                        // 1. Exercise Selector
                        if !viewModel.availableExercises.isEmpty {
                            Button(action: { showExerciseSelector = true }) {
                                HStack {
                                    Text(getSelectedExerciseName())
                                        .font(.title3)
                                        .fontWeight(.bold)
                                        .foregroundColor(.white)
                                        .multilineTextAlignment(.leading)
                                    Spacer()
                                    Image(systemName: "chevron.down")
                                        .foregroundColor(.neonGreen)
                                }
                                .padding()
                                .background(Color(hex: "1C1C1E"))
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                )
                            }
                            .sheet(isPresented: $showExerciseSelector) {
                                ExerciseSelectorView(viewModel: viewModel, selectedExerciseID: $selectedExerciseID)
                            }
                        }
                        
                        // 2. Ghost Data Hint
                        if let ghost = ghostData, let lastSet = ghost.sets.last {
                            Text("Anterior: \(viewModel.displayWeight(lastSet.weight))\(viewModel.unitLabel()) x \(lastSet.reps)")
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        
                        // 3. Steppers (Weight & Reps)
                        HStack(spacing: 15) {
                            CustomStepper(title: "Peso (\(viewModel.unitLabel()))", value: $weightValue, step: viewModel.weightUnit == "lbs" ? 5.0 : 2.5, decimals: 1, unit: viewModel.unitLabel())
                            CustomStepper(title: "Repeticiones", value: $repsValue, step: 1, decimals: 0)
                        }
                        
                        // 4. RPE Slider
                        VStack(alignment: .leading, spacing: 10) {
                            HStack {
                                Text("Esfuerzo (RPE)")
                                    .font(.caption)
                                    .fontWeight(.bold)
                                    .foregroundColor(.gray)
                                    .textCase(.uppercase)
                                Spacer()
                                Text("\(Int(rpe)) / 10")
                                    .font(.headline)
                                    .fontWeight(.bold)
                                    .foregroundColor(rpeColor)
                            }
                            
                            Slider(value: $rpe, in: 1...10, step: 1)
                                .accentColor(rpeColor)
                        }
                        .padding()
                        .background(Color(hex: "1C1C1E"))
                        .cornerRadius(16)
                        
                        // 5. Toggles (Drop Set / Super Set)
                        HStack(spacing: 15) {
                            Toggle(isOn: $isDropSet) {
                                Text("Drop Set")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(isDropSet ? .orange : .gray)
                            }
                            .toggleStyle(ButtonToggleStyle())
                            .tint(.orange)
                            
                            Toggle(isOn: $isSuperSet) {
                                Text("Super Set")
                                    .font(.subheadline)
                                    .fontWeight(.bold)
                                    .foregroundColor(isSuperSet ? .purple : .gray)
                            }
                            .toggleStyle(ButtonToggleStyle())
                            .tint(.purple)
                        }
                        
                        // 6. Add Set Button
                        Button(action: addOrUpdateSet) {
                            HStack {
                                Image(systemName: editingSetIndex != nil ? "pencil" : "plus.circle.fill")
                                Text(editingSetIndex != nil ? "Actualizar Set" : "Añadir Set")
                            }
                            .font(.headline)
                            .foregroundColor(.black)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(isAddSetDisabled ? Color.gray : Color.white)
                            .cornerRadius(16)
                        }
                        .disabled(isAddSetDisabled)
                        
                        // 7. Current Sets List
                        if !currentSets.isEmpty {
                            VStack(spacing: 10) {
                                ForEach(currentSets.indices, id: \.self) { index in
                                    let set = currentSets[index]
                                    HStack {
                                        Text("\(index + 1)")
                                            .font(.caption)
                                            .fontWeight(.bold)
                                            .foregroundColor(.gray)
                                            .frame(width: 20)
                                        
                                        Text("\(viewModel.displayWeight(set.weight)) \(viewModel.unitLabel())")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Text("x \(set.reps)")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                        
                                        Spacer()
                                        
                                        if let rpe = set.rpe {
                                            Text("RPE \(rpe)")
                                                .font(.caption2)
                                                .padding(4)
                                                .background(rpeColorFor(rpe).opacity(0.2))
                                                .foregroundColor(rpeColorFor(rpe))
                                                .cornerRadius(4)
                                        }
                                        
                                        if set.isDropSet {
                                            Image(systemName: "flame.fill")
                                                .foregroundColor(.orange)
                                                .font(.caption)
                                        }
                                        
                                        Button(action: { editSet(at: index) }) {
                                            Image(systemName: "pencil.circle.fill")
                                                .foregroundColor(.gray)
                                                .font(.title3)
                                        }
                                    }
                                    .padding()
                                    .background(Color(hex: "1C1C1E"))
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(editingSetIndex == index ? Color.neonGreen : Color.clear, lineWidth: 1)
                                    )
                                }
                                .onDelete(perform: removeSet)
                            }
                        }
                        
                        Divider().background(Color.gray.opacity(0.3))
                        
                        // 8. Session Summary (Previous Exercises)
                        if !tempExercises.isEmpty {
                            VStack(alignment: .leading, spacing: 15) {
                                Text("Resumen Sesión")
                                    .font(.headline)
                                    .foregroundColor(.gray)
                                
                                ForEach(tempExercises) { ex in
                                    Button(action: { resumeExercise(ex) }) {
                                        HStack {
                                            Circle()
                                                .fill(ex.definition.color)
                                                .frame(width: 10, height: 10)
                                            Text(ex.definition.name)
                                                .foregroundColor(.white)
                                            Spacer()
                                            Text("\(ex.sets.count) sets")
                                                .foregroundColor(.gray)
                                            Image(systemName: "pencil")
                                                .font(.caption)
                                                .foregroundColor(.neonGreen)
                                        }
                                        .padding()
                                        .background(Color(hex: "1C1C1E"))
                                        .cornerRadius(10)
                                    }
                                }
                            }
                        }
                        
                        Spacer(minLength: 50)
                    }
                    .padding()
                }
                
                // Bottom Action Bar
                if !tempExercises.isEmpty || !currentSets.isEmpty {
                    VStack {
                        Button(action: saveSession) {
                            Text("Terminar Entrenamiento")
                                .font(.headline)
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.neonBlue)
                                .cornerRadius(16)
                        }
                        .padding()
                    }
                    .background(Color(hex: "1C1C1E").ignoresSafeArea())
                }
            }
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Registrar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack {
                        toolbarButtons
                    }
                }
            }
            .alert("¡Guardado!", isPresented: $showAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Entrenamiento guardado con éxito.")
            }
            .onAppear {
                if selectedExerciseID == nil {
                    selectedExerciseID = viewModel.availableExercises.first?.id
                }
            }
            .sheet(isPresented: $showPlateCalculator) {
                // Binding workaround for Double to String
                PlateCalculatorView(isPresented: $showPlateCalculator, weightInput: Binding(
                    get: { String(format: "%.1f", weightValue) },
                    set: { if let val = Double($0) { weightValue = val } }
                ))
            }
            .toolbar(isFocusMode ? .hidden : .visible, for: .tabBar)
            .alert("Nuevo Ejercicio", isPresented: $showingAddExerciseAlert) {
                TextField("Nombre (ej: Curl de Bíceps)", text: $newExerciseName)
                Button("Cancelar", role: .cancel) { newExerciseName = "" }
                Button("Guardar") {
                    if !newExerciseName.isEmpty {
                        viewModel.addNewExercise(name: newExerciseName)
                        if let newEx = viewModel.availableExercises.last {
                            selectedExerciseID = newEx.id
                        }
                        newExerciseName = ""
                    }
                }
            } message: {
                Text("Escribe el nombre del ejercicio que quieres añadir a tu lista.")
            }
        }
    }
    
    var rpeColor: Color {
        rpeColorFor(Int(rpe))
    }
    
    func rpeColorFor(_ value: Int) -> Color {
        switch value {
        case 1...4: return .green
        case 5...7: return .yellow
        case 8...9: return .orange
        case 10: return .red
        default: return .gray
        }
    }
    
    func addOrUpdateSet() {
        // Use Double values directly
        let w = viewModel.inputWeight(weightValue)
        
        let newSet = ExerciseSet(
            weight: w,
            reps: Int(repsValue),
            rpe: Int(rpe),
            isDropSet: isDropSet,
            isSuperSet: isSuperSet
        )
        
        withAnimation {
            if let index = editingSetIndex {
                // Update existing set
                if index < currentSets.count {
                    currentSets[index] = newSet
                    editingSetIndex = nil // Exit edit mode
                }
            } else {
                // Add new set
                currentSets.append(newSet)
            }
        }
        
        // Haptic
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    func editSet(at index: Int) {
        guard index < currentSets.count else { return }
        let set = currentSets[index]
        weightValue = set.weight // Assuming stored as is or converted back? 
        // If stored in Kg and user uses Lbs, we might need conversion.
        // For now assuming direct mapping.
        repsValue = Double(set.reps)
        if let r = set.rpe { rpe = Double(r) }
        isDropSet = set.isDropSet
        isSuperSet = set.isSuperSet
        editingSetIndex = index
    }
        

    
    func removeSet(at offsets: IndexSet) {
        withAnimation {
            currentSets.remove(atOffsets: offsets)
            // Handle editing index if affected
            if let editing = editingSetIndex {
                if offsets.contains(editing) {
                    editingSetIndex = nil
                } else if offsets.contains(where: { $0 < editing }) {
                    editingSetIndex! -= 1
                }
            }
        }
    }
    
    func removeSet(at index: Int) {
        withAnimation {
            currentSets.remove(at: index)
            if editingSetIndex == index {
                editingSetIndex = nil
            } else if let editing = editingSetIndex, editing > index {
                editingSetIndex = editing - 1
            }
        }
    }
    
    func addSet() {
        addOrUpdateSet()
    }
    
    func finishExercise() {
        guard let exID = selectedExerciseID,
              let definition = viewModel.availableExercises.first(where: { $0.id == exID }),
              !currentSets.isEmpty
        else { return }
        
        let newExercise = Exercise(
            definition: definition,
            sets: currentSets
        )
        
        if tempExercises.isEmpty {
            sessionStartTime = Date()
        }
        
        withAnimation {
            tempExercises.append(newExercise)
            currentSets = [] // Clear sets for next exercise
            // Reset inputs
            weightValue = 0.0
            repsValue = 0.0
            rpe = 7.0
            isDropSet = false
            isSuperSet = false
        }
        
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    func resumeExercise(_ exercise: Exercise) {
        // 1. Save current work if any
        if !currentSets.isEmpty {
            finishExercise()
        }
        
        // 2. Remove from completed list
        if let index = tempExercises.firstIndex(where: { $0.id == exercise.id }) {
            withAnimation {
                tempExercises.remove(at: index)
            }
        }
        
        // 3. Load into active editing
        selectedExerciseID = exercise.definition.id
        currentSets = exercise.sets
        
        // 4. Pre-fill inputs with last set data for convenience
        if let lastSet = exercise.sets.last {
            // Convert back to user units if needed
            weightValue = viewModel.convertWeight(lastSet.weight)
            repsValue = Double(lastSet.reps)
            if let r = lastSet.rpe { rpe = Double(r) }
            isDropSet = lastSet.isDropSet
            isSuperSet = lastSet.isSuperSet
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
    }
    
    func saveSession() {
        guard !tempExercises.isEmpty else { return }
        
        let duration = sessionStartTime != nil ? Date().timeIntervalSince(sessionStartTime!) : 0
        
        let newSession = WorkoutSession(date: currentDate, duration: duration, exercises: tempExercises)
        viewModel.addSession(newSession)
        
        // Check for PRs and trigger confetti
        for exercise in tempExercises {
            if viewModel.isNewPR(exercise: exercise) {
                showConfetti = true
                // Haptic fuerte para PR
                let generator = UINotificationFeedbackGenerator()
                generator.notificationOccurred(.success)
                break // Trigger once per session
            }
        }
        
        // Reset
        tempExercises = []
        currentDate = Date()
        sessionStartTime = nil
        
        // Haptic normal para guardar si no hubo PR
        if !showConfetti {
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        }
        
        showAlert = true
        
        // Start Rest Timer
        timerManager.startTimer()
    }
    
    func loadTemplate(_ template: WorkoutTemplate) {
        for tempExercise in template.exercises {
            if let def = viewModel.availableExercises.first(where: { $0.id == tempExercise.definitionID }) {
                // Crear sets vacíos o con datos base según el template
                var initialSets: [ExerciseSet] = []
                for _ in 0..<tempExercise.sets {
                    initialSets.append(ExerciseSet(weight: 0, reps: tempExercise.reps))
                }
                
                let newExercise = Exercise(definition: def, sets: initialSets)
                tempExercises.append(newExercise)
            }
        }
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    



    
    func getSelectedExercise() -> ExerciseDefinition? {
        guard let id = selectedExerciseID else { return nil }
        return viewModel.availableExercises.first(where: { $0.id == id })
    }
    
    func getSelectedExerciseName() -> String {
        return getSelectedExercise()?.name ?? "Seleccionar Ejercicio"
    }

    var toolbarButtons: some View {
        HStack {
            // Load Template Button
            Menu {
                if viewModel.templates.isEmpty {
                    Text("No hay rutinas creadas")
                } else {
                    ForEach(viewModel.templates) { template in
                        Button(action: { loadTemplate(template) }) {
                            Label(template.name, systemImage: "clipboard")
                        }
                    }
                }
            } label: {
                Image(systemName: "arrow.down.doc.fill")
                    .foregroundColor(.neonGreen)
            }
            
            Button(action: { timerManager.startTimer() }) {
                Image(systemName: "timer")
                    .foregroundColor(.neonGreen)
            }
        }
    }
}

// MARK: - COMPONENTES UI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Spacer()
            }
            Text(value)
                .font(.system(.title3, design: .rounded))
                .fontWeight(.bold)
                .foregroundColor(.white)
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color.cardBackground)
        .cornerRadius(15)
    }
}

extension Color {
    static let appBackground = Color(UIColor.systemGroupedBackground)
    static let cardBackground = Color(UIColor.secondarySystemGroupedBackground)
    static let neonGreen = Color(red: 0.2, green: 0.8, blue: 0.4)
    static let neonBlue = Color(red: 0.2, green: 0.6, blue: 1.0)
}

struct WeeklySummaryCard: View {
    let summary: (currentVolume: Double, previousVolume: Double, currentTime: TimeInterval, previousTime: TimeInterval)
    let unitLabel: String
    
    var volumeChange: Double {
        guard summary.previousVolume > 0 else { return 100 }
        return ((summary.currentVolume - summary.previousVolume) / summary.previousVolume) * 100
    }
    
    var timeChange: Double {
        guard summary.previousTime > 0 else { return 100 }
        return ((summary.currentTime - summary.previousTime) / summary.previousTime) * 100
    }
    
    var body: some View {
        HStack(spacing: 15) {
            // Volume Stat
            VStack(alignment: .leading) {
                Text("Volumen Semanal")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack(alignment: .lastTextBaseline) {
                    Text("\(Int(summary.currentVolume))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text(unitLabel)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: volumeChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text("\(String(format: "%.1f", abs(volumeChange)))%")
                }
                .font(.caption2)
                .foregroundColor(volumeChange >= 0 ? .neonGreen : .red)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(15)
            
            // Time Stat
            VStack(alignment: .leading) {
                Text("Tiempo Semanal")
                    .font(.caption)
                    .foregroundColor(.gray)
                
                HStack(alignment: .lastTextBaseline) {
                    Text("\(Int(summary.currentTime / 60))")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                    Text("min")
                        .font(.caption)
                        .foregroundColor(.gray)
                }
                
                HStack(spacing: 4) {
                    Image(systemName: timeChange >= 0 ? "arrow.up.right" : "arrow.down.right")
                    Text("\(String(format: "%.1f", abs(timeChange)))%")
                }
                .font(.caption2)
                .foregroundColor(timeChange >= 0 ? .neonGreen : .red)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            .background(Color.cardBackground)
            .cornerRadius(15)
        }
    }
}

#Preview {
    ContentView()
}
