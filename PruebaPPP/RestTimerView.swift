import SwiftUI

struct RestTimerView: View {
    @ObservedObject var timerManager: TimerManager
    @State private var isExpanded = false
    
    var body: some View {
        if timerManager.isActive {
            ZStack(alignment: .top) {
                if isExpanded {
                    // Expanded View
                    VStack(spacing: 20) {
                        HStack {
                            Text("Descanso")
                                .font(.headline)
                                .foregroundColor(.gray)
                            
                            Spacer()
                            
                            Menu {
                                Picker("Sonido", selection: $timerManager.selectedSound) {
                                    ForEach(TimerSound.allCases) { sound in
                                        Text(sound.rawValue).tag(sound)
                                    }
                                }
                            } label: {
                                Image(systemName: "speaker.wave.2.fill")
                                    .foregroundColor(.neonGreen)
                                    .padding(8)
                                    .background(Color.cardBackground)
                                    .clipShape(Circle())
                            }
                        }
                        .padding(.horizontal)
                        
                        // Configuración rápida de tiempo
                        Menu {
                            Button("60s") { timerManager.defaultDuration = 60; if !timerManager.isActive { timerManager.startTimer() } }
                            Button("90s") { timerManager.defaultDuration = 90; if !timerManager.isActive { timerManager.startTimer() } }
                            Button("120s") { timerManager.defaultDuration = 120; if !timerManager.isActive { timerManager.startTimer() } }
                            Button("180s") { timerManager.defaultDuration = 180; if !timerManager.isActive { timerManager.startTimer() } }
                        } label: {
                            Text("Meta: \(timerManager.totalTime)s")
                                .font(.caption)
                                .padding(6)
                                .background(Color.cardBackground)
                                .cornerRadius(8)
                                .foregroundColor(.neonGreen)
                        }

                        ZStack {
                            Circle()
                                .stroke(lineWidth: 20) // Slightly thicker for better proportion
                                .opacity(0.2)
                                .foregroundColor(.gray)
                            
                            Circle()
                                .trim(from: 0.0, to: CGFloat(timerManager.progress))
                                .stroke(style: StrokeStyle(lineWidth: 20, lineCap: .round, lineJoin: .round))
                                .foregroundColor(.neonGreen)
                                .rotationEffect(Angle(degrees: 270.0))
                                .animation(.linear, value: timerManager.timeRemaining)
                            
                            VStack(spacing: 0) {
                                Text(formatTime(timerManager.timeRemaining))
                                    .font(.system(size: 60, weight: .bold, design: .rounded)) // Larger font
                                    .foregroundColor(.white)
                                    .monospacedDigit()
                                    .padding() // Add some breathing room
                            }
                        }
                        .frame(width: 240, height: 240) // Increased size
                        .padding(.vertical, 20)
                        
                        HStack {
                            Spacer()
                            
                            Button(action: { timerManager.subtractTime(10) }) {
                                Text("-10s")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.cardBackground)
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                            
                            Button(action: { timerManager.stopTimer() }) {
                                Text("Skip")
                                    .fontWeight(.bold)
                                    .foregroundColor(.red)
                                    .frame(width: 100, height: 50) // Fixed size to prevent wrapping
                                    .background(Color.cardBackground)
                                    .cornerRadius(25)
                            }
                            
                            Spacer()
                            
                            Button(action: { timerManager.addTime(10) }) {
                                Text("+10s")
                                    .fontWeight(.bold)
                                    .foregroundColor(.white)
                                    .frame(width: 60, height: 60)
                                    .background(Color.cardBackground)
                                    .clipShape(Circle())
                            }
                            
                            Spacer()
                        }
                        .padding(.horizontal)
                    }
                    .padding()
                    .background(Color.appBackground)
                    .cornerRadius(25)
                    .shadow(radius: 10)
                    .padding()
                    .transition(.scale)
                } else {
                    // Collapsed View (Pill)
                    HStack {
                        Circle()
                            .trim(from: 0.0, to: CGFloat(timerManager.progress))
                            .stroke(style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .foregroundColor(.neonGreen)
                            .rotationEffect(Angle(degrees: 270.0))
                            .frame(width: 20, height: 20)
                            .padding(4)
                        
                        Text(formatTime(timerManager.timeRemaining))
                            .font(.system(.body, design: .monospaced))
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                        
                        Image(systemName: "timer")
                            .foregroundColor(.gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(Color.cardBackground)
                    .clipShape(Capsule())
                    .shadow(radius: 5)
                    .transition(.move(edge: .top))
                }
            }
            .onTapGesture {
                withAnimation(.spring()) {
                    isExpanded.toggle()
                }
            }
            .frame(maxWidth: .infinity, alignment: .top)
            .padding(.top, 10) // Adjust for safe area if needed
        }
    }
    
    func formatTime(_ totalSeconds: Int) -> String {
        let minutes = totalSeconds / 60
        let seconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}
