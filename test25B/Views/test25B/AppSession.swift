//
//  AppSession.swift
//  test25B
//
//  Created by Andreas Pelczer on 12.01.26.
//


import Foundation
import SwiftUI

/// Globale Session: Rolle, Sprache, später Login/Benutzer.
final class AppSession: ObservableObject {

    enum Role: String, CaseIterable, Identifiable {
        case crew
        case dispatcher
        case director

        var id: String { rawValue }

        var title: String {
            switch self {
            case .crew: return "Crew"
            case .dispatcher: return "Dispatcher"
            case .director: return "Director"
            }
        }

        var sfSymbol: String {
            switch self {
            case .crew: return "person.2.fill"
            case .dispatcher: return "app.badge.checkmark"
            case .director: return "crown.fill"
            }
        }
    }

    @Published var role: Role = .crew

    // Optional: Sprache wie in GastroGrid gedacht – kann später ausgebaut werden
    @Published var languageCode: String = "de" {
        didSet { locale = Locale(identifier: languageCode) }
    }
    @Published var locale: Locale = Locale(identifier: "de")
}
