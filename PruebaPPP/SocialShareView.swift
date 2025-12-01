import SwiftUI

struct SocialShareView: View {
    let session: WorkoutSession
    @Environment(\.dismiss) var dismiss
    @State private var selectedColor: Color = .black
    
    // Stats calculados (simulados por ahora, idealmente vendrían del ViewModel)
    @State private var streak: Int = 3 // Ejemplo
    @State private var workoutsLast30Days: Int = 12 // Ejemplo
    
    let colors: [Color] = [.black, .blue, .purple, .red, .orange, .green, .gray]
    
    var body: some View {
        NavigationView {
            VStack {
                Spacer()
                
                // Card to Share
                WorkoutSummaryCard(session: session, backgroundColor: selectedColor, streak: streak, workoutsLast30Days: workoutsLast30Days)
                    .padding()
                    .shadow(color: selectedColor.opacity(0.3), radius: 20, x: 0, y: 10)
                
                // Color Picker
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 15) {
                        ForEach(colors, id: \.self) { color in
                            Circle()
                                .fill(color)
                                .frame(width: 40, height: 40)
                                .overlay(
                                    Circle()
                                        .stroke(Color.white, lineWidth: selectedColor == color ? 3 : 0)
                                )
                                .onTapGesture {
                                    withAnimation {
                                        selectedColor = color
                                    }
                                }
                        }
                    }
                    .padding()
                }
                
                Spacer()
                
                // Action Buttons
                HStack(spacing: 15) {
                    // Save Image Button
                    Button(action: saveImage) {
                        Label("Guardar Imagen", systemImage: "arrow.down.to.line")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.gray.opacity(0.3))
                            .cornerRadius(15)
                    }
                    
                    // Share Link Button
                    ShareLink(item: generateSnapshot(), preview: SharePreview("Entrenamiento GymApp", image: generateSnapshot())) {
                        Label("Compartir", systemImage: "square.and.arrow.up")
                            .font(.headline)
                            .foregroundColor(.black)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.neonGreen)
                            .cornerRadius(15)
                    }
                }
                .padding()
            }
            .background(Color.appBackground)
            .navigationTitle("Compartir Logro")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cerrar") { dismiss() }
                        .foregroundColor(.white)
                }
            }
        }
    }
    
    @MainActor
    func generateSnapshot() -> Image {
        let renderer = ImageRenderer(content: WorkoutSummaryCard(session: session, backgroundColor: selectedColor, streak: streak, workoutsLast30Days: workoutsLast30Days).frame(width: 350, height: 500))
        renderer.scale = 3.0 // High resolution
        
        if let uiImage = renderer.uiImage {
            return Image(uiImage: uiImage)
        }
        return Image(systemName: "photo")
    }
    
    @MainActor
    func saveImage() {
        let renderer = ImageRenderer(content: WorkoutSummaryCard(session: session, backgroundColor: selectedColor, streak: streak, workoutsLast30Days: workoutsLast30Days).frame(width: 350, height: 500))
        renderer.scale = 3.0
        
        if let uiImage = renderer.uiImage {
            UIImageWriteToSavedPhotosAlbum(uiImage, nil, nil, nil)
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        }
    }
}

struct WorkoutSummaryCard: View {
    let session: WorkoutSession
    var backgroundColor: Color = .black
    var streak: Int
    var workoutsLast30Days: Int
    
    var body: some View {
        ZStack {
            // Background
            LinearGradient(gradient: Gradient(colors: [Color.appBackground, backgroundColor]), startPoint: .top, endPoint: .bottom)
            
            // Overlay Pattern (Optional)
            Circle()
                .stroke(Color.white.opacity(0.05), lineWidth: 50)
                .frame(width: 400, height: 400)
                .offset(x: 150, y: -200)
            
            VStack(spacing: 25) {
                // Header
                HStack {
                    Image("Logo")
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 40, height: 40)
                    Text("GymRatp")
                        .font(.title2)
                        .fontWeight(.black)
                        .foregroundColor(.white)
                        .tracking(1)
                    Spacer()
                    Text(session.date.formatted(date: .abbreviated, time: .omitted).uppercased())
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color.white.opacity(0.1))
                        .cornerRadius(5)
                }
                
                // Main Stats (Strava Style)
                HStack(spacing: 40) {
                    VStack(alignment: .leading) {
                        Text("VOLUMEN")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        Text("\(Int(session.totalVolume))kg")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading) {
                        Text("EJERCICIOS")
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.gray)
                        Text("\(session.exercises.count)")
                            .font(.system(size: 32, weight: .heavy, design: .rounded))
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                
                // Highlighted Exercise (The one with max weight)
                if let bestExercise = session.exercises.max(by: { 
                    ($0.sets.map{$0.weight}.max() ?? 0) < ($1.sets.map{$0.weight}.max() ?? 0) 
                }) {
                    HStack {
                        VStack(alignment: .leading, spacing: 5) {
                            Text("MEJOR LEVANTAMIENTO")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(.neonGreen)
                            
                            Text(bestExercise.definition.name)
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            Text("\(Int(bestExercise.sets.map{$0.weight}.max() ?? 0))kg")
                                .font(.title3)
                                .fontWeight(.bold)
                                .foregroundColor(.white)
                        }
                        Spacer()
                        Image(systemName: "trophy.fill")
                            .font(.largeTitle)
                            .foregroundColor(.yellow)
                            .shadow(color: .yellow.opacity(0.5), radius: 10)
                    }
                    .padding()
                    .background(Color.white.opacity(0.05))
                    .cornerRadius(15)
                    .overlay(
                        RoundedRectangle(cornerRadius: 15)
                            .stroke(Color.neonGreen.opacity(0.3), lineWidth: 1)
                    )
                }
                
                Spacer()
                
                // Monthly Stats Footer
                HStack(spacing: 20) {
                    VStack {
                        Text("\(streak)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Días Racha")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                    
                    Rectangle()
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 1, height: 30)
                    
                    VStack {
                        Text("\(workoutsLast30Days)")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        Text("Últimos 30 días")
                            .font(.caption2)
                            .foregroundColor(.gray)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.black.opacity(0.3))
                .cornerRadius(15)
                
                // Branding Footer
                HStack {
                    Spacer()
                    Text("Generado por GymRatp")
                        .font(.system(size: 10))
                        .foregroundColor(.white.opacity(0.4))
                }
            }
            .padding(25)
        }
        .frame(width: 350, height: 500)
        .cornerRadius(25)
        .overlay(
            RoundedRectangle(cornerRadius: 25)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}
