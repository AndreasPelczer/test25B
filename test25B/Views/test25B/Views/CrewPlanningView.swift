//
//  CrewPlanningView.swift
//  test25B
//
//  Created by Andreas Pelczer on 12.01.26.
//


import SwiftUI

struct CrewPlanningView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.2.fill")
                .font(.system(size: 44))
            Text("Crew Planning (MVP)")
                .font(.headline)
            Text("Hier kommt Drag & Drop Zuweisung: Crew → Stationen → Mission (Event).")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .navigationTitle("Crew")
    }
}
