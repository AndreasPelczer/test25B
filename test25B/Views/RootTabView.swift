//
//  RootTabView.swift
//  test25B
//
//  Created by Andreas Pelczer on 12.01.26.
//


import SwiftUI

/// Root Tabs: Mission (Events), Crew, RCA, Scan, Settings.
/// Mission = Event (test25B).
@available(iOS 16.0, *)
struct RootTabView: View {
    @EnvironmentObject private var session: AppSession

    var body: some View {
        TabView {
            // TAB 1: Mission Control (Events)
            if #available(iOS 16.0, *) {
                NavigationStack {
                    ContentView() // aus test25B
                }
                .tabItem {
                    Label("Zu erledigen", systemImage: "target")
                }
            } else {
                // Fallback on earlier versions
            }

            // TAB 2: Crew (Planung / Zuweisung) – Platzhalter für MVP
            if session.role == .dispatcher || session.role == .director {
                NavigationStack {
                    CrewPlanningView()
                }
                .tabItem {
                    Label("Mitarbeiter", systemImage: "person.2.fill")
                }
            }

            // TAB 3: RCA (Remote Chef Annotation) – Platzhalter für MVP
            NavigationStack {
                RCAHubView()
            }
            .tabItem {
                Label("RCA", systemImage: "pencil.and.scribble")
            }

            // TAB 4: Vision-Kit Scan – Platzhalter für MVP
            NavigationStack {
                VisionScanView()
            }
            .tabItem {
                Label("Scan", systemImage: "viewfinder")
            }
            NavigationStack {
                KnowledgeHomeView()            }
            .tabItem {
                Label("Wissen", systemImage: "book.fill")
            }


            // TAB 5: Settings (Rolle/Sprache)
            if #available(iOS 16.0, *) {
                NavigationStack {
                    SettingsView()
                }
                .tabItem {
                    Label("Settings", systemImage: "gearshape.fill")
                }
            } else {
                // Fallback on earlier versions
            }
        }
        .environment(\.locale, session.locale)
    }
}
