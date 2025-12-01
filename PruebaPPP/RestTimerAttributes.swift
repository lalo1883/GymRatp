import ActivityKit
import SwiftUI

struct RestTimerAttributes: ActivityAttributes {
    public struct ContentState: Codable, Hashable {
        var timeRemaining: Int
        var progress: Double
    }
    
    var totalDuration: Int
}
