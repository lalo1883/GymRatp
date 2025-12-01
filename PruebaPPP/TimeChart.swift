import SwiftUI
import Charts

struct TimeChart: View {
    let sessions: [WorkoutSession]
    
    var dailyDurations: [(date: Date, minutes: Double)] {
        let calendar = Calendar.current
        let today = Date()
        let oneWeekAgo = calendar.date(byAdding: .day, value: -6, to: today)!
        
        // Group sessions by day
        var grouped: [Date: Double] = [:]
        
        // Initialize last 7 days with 0
        for i in 0...6 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let startOfDay = calendar.startOfDay(for: date)
                grouped[startOfDay] = 0
            }
        }
        
        for session in sessions {
            let startOfDay = calendar.startOfDay(for: session.date)
            if startOfDay >= calendar.startOfDay(for: oneWeekAgo) {
                grouped[startOfDay, default: 0] += session.duration / 60.0 // Convert to minutes
            }
        }
        
        return grouped.sorted { $0.key < $1.key }.map { (date: $0.key, minutes: $0.value) }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Tiempo de Entrenamiento")
                .font(.headline)
                .foregroundColor(.gray)
            
            Text("Últimos 7 días (min)")
                .font(.caption)
                .foregroundColor(.gray)
                .padding(.bottom, 10)
            
            if dailyDurations.isEmpty {
                Text("No hay datos recientes")
                    .foregroundColor(.gray)
                    .frame(height: 200)
            } else {
                Chart {
                    ForEach(dailyDurations, id: \.date) { item in
                        BarMark(
                            x: .value("Día", item.date, unit: .day),
                            y: .value("Minutos", item.minutes)
                        )
                        .foregroundStyle(Color.neonBlue.gradient)
                        .cornerRadius(5)
                    }
                }
                .frame(height: 200)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day)) { value in
                        AxisValueLabel(format: .dateTime.weekday(.abbreviated))
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(20)
    }
}
