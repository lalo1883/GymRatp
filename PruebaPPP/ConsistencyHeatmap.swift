import SwiftUI

struct ConsistencyHeatmap: View {
    @ObservedObject var viewModel: GymViewModel
    @State private var selectedDate: Date?
    @State private var showDetails = false
    
    let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7) // 7 days a week
    
    // Generar fechas para el calendario (mes actual + relleno)
    var calendarDays: [Date] {
        let calendar = Calendar.current
        let today = Date()
        
        // Inicio del mes actual
        guard let monthInterval = calendar.dateInterval(of: .month, for: today) else { return [] }
        let monthStart = monthInterval.start
        
        // Encontrar el primer día de la semana (Lunes o Domingo según región, aquí forzamos Lunes para consistencia visual si se desea, o usar current)
        // Vamos a usar el start de la semana del monthStart
        let startOfWeek = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: monthStart))!
        
        // Queremos mostrar por lo menos 5 o 6 semanas
        // Vamos a generar 42 días (6 semanas) desde el startOfWeek
        var days: [Date] = []
        for i in 0..<42 {
            if let date = calendar.date(byAdding: .day, value: i, to: startOfWeek) {
                days.append(date)
            }
        }
        return days
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Consistencia")
                    .font(.headline)
                    .foregroundColor(.gray)
                Spacer()
                Text(Date().formatted(.dateTime.month().year()))
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.neonGreen)
            }
            
            // Días de la semana headers
            HStack {
                ForEach(["D", "L", "M", "M", "J", "V", "S"], id: \.self) { day in
                    Text(day)
                        .font(.caption2)
                        .fontWeight(.bold)
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(calendarDays, id: \.self) { date in
                    let isToday = Calendar.current.isDateInToday(date)
                    let isSameMonth = Calendar.current.isDate(date, equalTo: Date(), toGranularity: .month)
                    
                    Button(action: {
                        selectedDate = date
                        showDetails = true
                    }) {
                        ZStack {
                            RoundedRectangle(cornerRadius: 6)
                                .fill(getColor(for: date))
                                .aspectRatio(1, contentMode: .fit)
                                .opacity(isSameMonth ? 1.0 : 0.3) // Dim days outside current month
                            
                            Text("\(Calendar.current.component(.day, from: date))")
                                .font(.caption2)
                                .fontWeight(.bold)
                                .foregroundColor(getTextColor(for: date))
                            
                            if isToday {
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color.white, lineWidth: 1)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.cardBackground)
        .cornerRadius(15)
        .sheet(isPresented: $showDetails) {
            if let date = selectedDate {
                SessionDetailsView(date: date, viewModel: viewModel)
                    .presentationDetents([.medium, .fraction(0.4)])
            }
        }
    }
    
    func getColor(for date: Date) -> Color {
        let calendar = Calendar.current
        let hasWorkout = viewModel.sessions.contains { session in
            calendar.isDate(session.date, inSameDayAs: date)
        }
        
        if hasWorkout {
            return Color.neonGreen
        } else {
            return Color.white.opacity(0.1)
        }
    }
    
    func getTextColor(for date: Date) -> Color {
        let calendar = Calendar.current
        let hasWorkout = viewModel.sessions.contains { session in
            calendar.isDate(session.date, inSameDayAs: date)
        }
        
        return hasWorkout ? .black : .white.opacity(0.7)
    }
}

struct SessionDetailsView: View {
    let date: Date
    @ObservedObject var viewModel: GymViewModel
    
    var session: WorkoutSession? {
        viewModel.sessions.first(where: { Calendar.current.isDate($0.date, inSameDayAs: date) })
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text(date.formatted(date: .complete, time: .omitted))
                .font(.headline)
                .padding(.top)
            
            if let session = session {
                List {
                    ForEach(session.exercises) { exercise in
                        HStack {
                            Circle().fill(exercise.definition.color).frame(width: 8, height: 8)
                            Text(exercise.definition.name)
                            Spacer()
                            Text("\(exercise.sets.count) sets | Max: \(Int(exercise.sets.map{$0.weight}.max() ?? 0))kg")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .listStyle(.plain)
            } else {
                ContentUnavailableView("Descanso", systemImage: "moon.zzz.fill", description: Text("No entrenaste este día."))
            }
        }
        .padding()
        .background(Color.appBackground)
    }
}
