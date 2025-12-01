import SwiftUI
import Combine
import AudioToolbox

import UserNotifications
import ActivityKit

enum TimerSound: String, CaseIterable, Identifiable {
    case classic = "Clásico"
    case zen = "Zen"
    case coach = "Entrenador"
    case future = "Futuro"
    
    var id: String { self.rawValue }
    
    var soundID: SystemSoundID {
        switch self {
        case .classic: return 1005 // Alarm
        case .zen: return 1000 // Mail Sent (softer)
        case .coach: return 1016 // Tweet (whistle-like)
        case .future: return 1103 // Tock
        }
    }
}

class TimerManager: ObservableObject {
    @Published var timeRemaining: Int = 0
    @Published var isActive: Bool = false
    @Published var totalTime: Int = 90
    @Published var progress: Double = 0.0
    @Published var defaultDuration: Int = 90 // Configurable default
    @Published var selectedSound: TimerSound = .classic
    
    private var timer: AnyCancellable?
    private var backgroundTask: UIBackgroundTaskIdentifier = .invalid
    
    #if canImport(ActivityKit)
    var activity: Activity<RestTimerAttributes>?
    #endif
    
    init() {
        requestNotificationPermission()
    }
    
    func startTimer(duration: Int? = nil) {
        // Cancelar timer anterior si existe
        stopTimer()
        
        let targetDuration = duration ?? defaultDuration
        self.timeRemaining = targetDuration
        self.totalTime = targetDuration
        self.isActive = true
        self.progress = 1.0
        
        // Background Task
        backgroundTask = UIApplication.shared.beginBackgroundTask { [weak self] in
            self?.endBackgroundTask()
        }
        
        // Schedule Notification
        scheduleNotification(seconds: Double(targetDuration))
        
        // Start Live Activity
        #if canImport(ActivityKit)
        if ActivityAuthorizationInfo().areActivitiesEnabled {
            let attributes = RestTimerAttributes(totalDuration: targetDuration)
            let state = RestTimerAttributes.ContentState(timeRemaining: targetDuration, progress: 1.0)
            do {
                activity = try Activity.request(attributes: attributes, contentState: state, pushType: nil)
            } catch {
                print("Error starting activity: \(error)")
            }
        }
        #endif
        
        timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
            .sink { [weak self] _ in
                guard let self = self else { return }
                
                if self.timeRemaining > 0 {
                    self.timeRemaining -= 1
                    withAnimation(.linear(duration: 1.0)) {
                        self.progress = Double(self.timeRemaining) / Double(self.totalTime)
                    }
                    self.updateActivity()
                } else {
                    self.stopTimer()
                    self.playSound()
                }
            }
    }
    
    func stopTimer() {
        isActive = false
        timer?.cancel()
        timer = nil
        endBackgroundTask()
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        // End Live Activity
        #if canImport(ActivityKit)
        Task {
            await activity?.end(using: nil, dismissalPolicy: .immediate)
            activity = nil
        }
        #endif
    }
    
    func addTime(_ seconds: Int) {
        timeRemaining += seconds
        totalTime += seconds // Ajustar total para que la barra de progreso no salte raro
        updateProgress()
        rescheduleNotification()
        updateActivity()
    }
    
    func subtractTime(_ seconds: Int) {
        if timeRemaining > seconds {
            timeRemaining -= seconds
            totalTime = max(totalTime - seconds, timeRemaining) // Ajustar total
            updateProgress()
            rescheduleNotification()
            updateActivity()
        } else {
            stopTimer()
        }
    }
    
    private func updateProgress() {
        withAnimation {
            progress = Double(timeRemaining) / Double(totalTime)
        }
    }
    
    private func updateActivity() {
        #if canImport(ActivityKit)
        let state = RestTimerAttributes.ContentState(timeRemaining: timeRemaining, progress: progress)
        Task {
            await activity?.update(using: state)
        }
        #endif
    }
    
    private func playSound() {
        AudioServicesPlaySystemSound(selectedSound.soundID)
        AudioServicesPlaySystemSound(kSystemSoundID_Vibrate)
    }
    
    func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in }
    }
    
    func scheduleNotification(seconds: Double) {
        let content = UNMutableNotificationContent()
        content.title = "¡Descanso Terminado!"
        content.body = "Es hora del siguiente set."
        content.sound = UNNotificationSound.default
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: seconds, repeats: false)
        let request = UNNotificationRequest(identifier: "RestTimer", content: content, trigger: trigger)
        
        UNUserNotificationCenter.current().add(request)
    }
    
    func rescheduleNotification() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        if timeRemaining > 0 {
            scheduleNotification(seconds: Double(timeRemaining))
        }
    }
    
    private func endBackgroundTask() {
        UIApplication.shared.endBackgroundTask(backgroundTask)
        backgroundTask = .invalid
    }
}
