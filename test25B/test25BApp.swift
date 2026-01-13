// test25BApp.swift (KORRIGIERT)

import SwiftUI

@main
struct test25BApp: App {
    let persistenceController = PersistenceController.shared

    @StateObject private var eventListVM: EventListViewModel
    @StateObject private var session = AppSession()

    init() {
        let ctx = PersistenceController.shared.container.viewContext
        _eventListVM = StateObject(wrappedValue: EventListViewModel(context: ctx))
    }

    var body: some Scene {
        WindowGroup {
            if #available(iOS 16.0, *) {
                RootTabView()
                    .environment(\.managedObjectContext, persistenceController.container.viewContext)
                    .environmentObject(eventListVM)
                    .environmentObject(session)
            } else {
                // Fallback on earlier versions
            }
        }
    }
}
