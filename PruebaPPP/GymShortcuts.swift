import AppIntents
import SwiftUI

struct StartRestIntent: AppIntent {
    static var title: LocalizedStringResource = "Empezar Descanso"
    static var description = IntentDescription("Inicia el temporizador de descanso en GymApp.")
    static var openAppWhenRun: Bool = true
    
    @MainActor
    func perform() async throws -> some IntentResult {
        // Abrimos la app via URL Scheme para que ContentView lo maneje
        if let url = URL(string: "gymapp://startRest") {
            await UIApplication.shared.open(url)
        }
        return .result()
    }
}

struct GymShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: StartRestIntent(),
            phrases: [
                "Empezar descanso en \(.applicationName)",
                "Start rest in \(.applicationName)",
                "Descanso \(.applicationName)"
            ],
            shortTitle: "Empezar Descanso",
            systemImageName: "timer"
        )
    }
}
