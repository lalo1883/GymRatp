import SwiftUI

struct CustomStepper: View {
    let title: String
    @Binding var value: Double
    let step: Double
    let decimals: Int
    var unit: String = ""
    
    // Gesture State
    @State private var timer: Timer?
    @State private var isPressing = false
    
    var body: some View {
        VStack(spacing: 5) {
            Text(title)
                .font(.caption2)
                .fontWeight(.bold)
                .foregroundColor(.gray)
                .textCase(.uppercase)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
            
            HStack(spacing: 10) {
                // Minus Button
                StepperButton(systemName: "minus", color: .white, backgroundColor: Color(hex: "2C2C2E")) {
                    decrement()
                } startTimer: {
                    startTimer(direction: -1)
                } stopTimer: {
                    stopTimer()
                }
                
                // Value Display
                VStack(spacing: 0) {
                    Text(String(format: "%.\(decimals)f", value))
                        .font(.system(size: 24, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .minimumScaleFactor(0.5)
                        .lineLimit(1)
                    
                    if !unit.isEmpty {
                        Text(unit)
                            .font(.caption2)
                            .fontWeight(.bold)
                            .foregroundColor(.neonGreen)
                    }
                }
                .frame(minWidth: 50)
                
                // Plus Button
                StepperButton(systemName: "plus", color: .black, backgroundColor: .neonGreen) {
                    increment()
                } startTimer: {
                    startTimer(direction: 1)
                } stopTimer: {
                    stopTimer()
                }
            }
        }
        .padding(10)
        .background(Color(hex: "1C1C1E"))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
    
    func increment() {
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
        value += step
    }
    
    func decrement() {
        let impactMed = UIImpactFeedbackGenerator(style: .medium)
        impactMed.impactOccurred()
        if value - step >= 0 {
            value -= step
        } else {
            value = 0
        }
    }
    
    func startTimer(direction: Double) {
        timer?.invalidate()
        timer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            if direction > 0 {
                value += step
            } else {
                if value - step >= 0 {
                    value -= step
                } else {
                    value = 0
                }
            }
            let impactLight = UIImpactFeedbackGenerator(style: .light)
            impactLight.impactOccurred()
        }
    }
    
    func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct StepperButton: View {
    let systemName: String
    let color: Color
    let backgroundColor: Color
    let action: () -> Void
    let startTimer: () -> Void
    let stopTimer: () -> Void
    
    @State private var isPressed = false
    
    var body: some View {
        Image(systemName: systemName)
            .font(.headline)
            .fontWeight(.bold)
            .foregroundColor(color)
            .frame(width: 35, height: 35)
            .background(backgroundColor)
            .clipShape(Circle())
            .scaleEffect(isPressed ? 0.9 : 1.0)
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onChanged { _ in
                        if !isPressed {
                            isPressed = true
                            action() // Initial tap
                            // Delay before rapid fire
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                                if isPressed {
                                    startTimer()
                                }
                            }
                        }
                    }
                    .onEnded { _ in
                        isPressed = false
                        stopTimer()
                    }
            )
    }
}
