import SwiftUI

struct HelpView: View {
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // Intro
                    Text("Guía Rápida")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    Text("Aprende a interpretar tus datos y sacar el máximo provecho a GymApp.")
                        .font(.body)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.horizontal)
                    
                    // 1. Resumen Semanal
                    HelpCard(
                        icon: "calendar.badge.clock",
                        color: .neonBlue,
                        title: "Resumen Semanal",
                        description: "Esta tarjeta al inicio del Dashboard compara tu volumen total (peso levantado) y tiempo de entrenamiento de esta semana contra la anterior. Úsalo para saber si estás progresando o descansando más."
                    )
                    
                    // 2. Gráfica de Radar (Telaraña)
                    HelpCard(
                        icon: "hexagon.fill",
                        color: .neonGreen,
                        title: "Sets Semanales (Radar)",
                        description: "Muestra el equilibrio de tu entrenamiento. Cada punta es un grupo muscular. La línea punteada es tu meta semanal (10 sets por defecto). Si el área verde cubre la línea punteada, ¡cumpliste tu meta!"
                    )
                    
                    // 3. Gráfica de Tiempo
                    HelpCard(
                        icon: "chart.bar.fill",
                        color: .orange,
                        title: "Tiempo de Entrenamiento",
                        description: "Barras verticales que indican cuántos minutos entrenaste cada día de la semana. Ideal para ver tu consistencia."
                    )
                    
                    // 4. Progreso de Fuerza
                    HelpCard(
                        icon: "chart.xyaxis.line",
                        color: .purple,
                        title: "Progreso de Fuerza",
                        description: "Selecciona un ejercicio en el menú superior para ver esta gráfica. Muestra cómo ha subido (o bajado) el peso máximo que has levantado en ese ejercicio a lo largo del tiempo."
                    )
                    
                    // 5. Herramientas
                    HelpCard(
                        icon: "wrench.and.screwdriver.fill",
                        color: .yellow,
                        title: "Herramientas Útiles",
                        description: "En la pestaña 'Registrar', usa el menú de herramientas para acceder a la Calculadora de Placas, Calculadora Inversa y la nueva Calculadora de 1RM (Fuerza Máxima)."
                    )
                    
                    Spacer()
                }
                .padding(.vertical)
            }
            .background(Color.appBackground)
            .navigationTitle("Ayuda")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Entendido") { dismiss() }
                }
            }
        }
    }
}

struct HelpCard: View {
    let icon: String
    let color: Color
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 30)
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.cardBackground)
        .cornerRadius(15)
        .padding(.horizontal)
    }
}

#Preview {
    HelpView()
        .preferredColorScheme(.dark)
}
