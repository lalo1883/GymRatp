import SwiftUI

struct RadarChartView: View {
    let data: [MuscleGroup: Double]
    let goals: [MuscleGroup: Int] // New parameter
    let maxValue: Double
    
    var body: some View {
        GeometryReader { geometry in
            let center = CGPoint(x: geometry.size.width / 2, y: geometry.size.height / 2)
            let radius = min(geometry.size.width, geometry.size.height) / 2 - 30 // Padding for labels
            
            ZStack {
                // Background Web
                ForEach([0.25, 0.5, 0.75, 1.0], id: \.self) { scale in
                    Path { path in
                        for (index, _) in MuscleGroup.allCases.enumerated() {
                            let angle = angleFor(index: index, total: MuscleGroup.allCases.count)
                            let point = pointFor(angle: angle, radius: radius * scale, center: center)
                            
                            if index == 0 {
                                path.move(to: point)
                            } else {
                                path.addLine(to: point)
                            }
                        }
                        path.closeSubpath()
                    }
                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                }
                
                // Axes
                Path { path in
                    for (index, _) in MuscleGroup.allCases.enumerated() {
                        let angle = angleFor(index: index, total: MuscleGroup.allCases.count)
                        let point = pointFor(angle: angle, radius: radius, center: center)
                        path.move(to: center)
                        path.addLine(to: point)
                    }
                }
                .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                
                // Goal Polygon (Dashed)
                Path { path in
                    for (index, muscle) in MuscleGroup.allCases.enumerated() {
                        let value = Double(goals[muscle] ?? 10)
                        let normalizedValue = maxValue > 0 ? value / maxValue : 0
                        let angle = angleFor(index: index, total: MuscleGroup.allCases.count)
                        let point = pointFor(angle: angle, radius: radius * normalizedValue, center: center)
                        
                        if index == 0 {
                            path.move(to: point)
                        } else {
                            path.addLine(to: point)
                        }
                    }
                    path.closeSubpath()
                }
                .stroke(Color.white.opacity(0.5), style: StrokeStyle(lineWidth: 2, dash: [5]))
                
                // Data Polygon
                Path { path in
                    for (index, muscle) in MuscleGroup.allCases.enumerated() {
                        let value = data[muscle] ?? 0
                        let normalizedValue = maxValue > 0 ? value / maxValue : 0
                        let angle = angleFor(index: index, total: MuscleGroup.allCases.count)
                        let point = pointFor(angle: angle, radius: radius * normalizedValue, center: center)
                        
                        if index == 0 {
                            path.move(to: point)
                        } else {
                            path.addLine(to: point)
                        }
                    }
                    path.closeSubpath()
                }
                .fill(Color.neonGreen.opacity(0.3))
                
                Path { path in
                    for (index, muscle) in MuscleGroup.allCases.enumerated() {
                        let value = data[muscle] ?? 0
                        let normalizedValue = maxValue > 0 ? value / maxValue : 0
                        let angle = angleFor(index: index, total: MuscleGroup.allCases.count)
                        let point = pointFor(angle: angle, radius: radius * normalizedValue, center: center)
                        
                        if index == 0 {
                            path.move(to: point)
                        } else {
                            path.addLine(to: point)
                        }
                    }
                    path.closeSubpath()
                }
                .stroke(Color.neonGreen, lineWidth: 2)
                
                // Labels
                ForEach(Array(MuscleGroup.allCases.enumerated()), id: \.offset) { index, muscle in
                    let angle = angleFor(index: index, total: MuscleGroup.allCases.count)
                    let labelPoint = pointFor(angle: angle, radius: radius + 20, center: center)
                    
                    Text(muscle.rawValue)
                        .font(.caption2)
                        .foregroundColor(.gray)
                        .position(labelPoint)
                }
            }
        }
        .frame(height: 300)
    }
    
    func angleFor(index: Int, total: Int) -> Double {
        return (Double(index) / Double(total)) * 2 * .pi - .pi / 2
    }
    
    func pointFor(angle: Double, radius: Double, center: CGPoint) -> CGPoint {
        return CGPoint(
            x: center.x + CGFloat(cos(angle) * radius),
            y: center.y + CGFloat(sin(angle) * radius)
        )
    }
}
