//
//  EventFilterPicker.swift
//  test25B
//
//  Created by Andreas Pelczer on 15.12.25.
//

import SwiftUI

struct EventFilterPicker: View {
    // Nimmt die Bindung vom ContentView entgegen
    @Binding var selectedFilter: EventFilter
    
    var body: some View {
        Picker("Filter", selection: $selectedFilter) {
            ForEach(EventFilter.allCases) { filter in
                Text(filter.rawValue).tag(filter)
            }
        }
        .pickerStyle(SegmentedPickerStyle())
    }
}
