//
//  RunningApp.swift
//  Running
//
//  Created by Ryan on 1/23/26.
//

import SwiftUI

@main
struct RunningApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
