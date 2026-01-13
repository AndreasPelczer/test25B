//
//  VisionScanView.swift
//  test25B
//
//  Created by Andreas Pelczer on 12.01.26.
//


import SwiftUI

struct VisionScanView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "viewfinder")
                .font(.system(size: 44))
            Text("Vision Scan (MVP)")
                .font(.headline)
            Text("Nächster Schritt: Etikett/Barcode Scan → Matching gegen Auftrag/Station → Ampel.")
                .multilineTextAlignment(.center)
                .foregroundStyle(.secondary)
                .padding(.horizontal)
        }
        .navigationTitle("Scan")
    }
}
