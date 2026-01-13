//
//  RCAHubView.swift
//  test25B
//
//  Created by Andreas Pelczer on 12.01.26.
//


import SwiftUI

struct RCAHubView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "pencil.and.scribble")
                .font(.system(size: 44))
            Text("RCA (MVP)")
                .font(.headline)
            Text("Nächster Schritt: Foto aufnehmen → Marker/Annotation → Speichern pro Mission (Event).")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .navigationTitle("RCA")
    }
}
