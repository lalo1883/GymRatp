//
//  PruebaPPPApp.swift
//  PruebaPPP
//
//  Created by Eduardo Nuñez on 24/11/25.
//

import SwiftUI
import FirebaseCore
import FirebaseAuth

class AppDelegate: NSObject, UIApplicationDelegate {
  func application(_ application: UIApplication,
                   didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
    FirebaseApp.configure()
    return true
  }
}

@main
struct PruebaPPPApp: App {
    // register app delegate for Firebase setup
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @State private var isLoggedIn = false

    var body: some Scene {
        WindowGroup {
            if isLoggedIn {
                ContentView()
            } else {
                LoginView()
                    .onAppear {
                        Auth.auth().addStateDidChangeListener { auth, user in
                            isLoggedIn = (user != nil)
                        }
                    }
            }
        }
    }
}
