//
//  ContentView.swift
//  easyshortcut
//
//  Main SwiftUI view displayed inside the popover.
//  Contains the search field and shortcuts list.
//

internal import SwiftUI

struct ContentView: View {
    @State private var searchQuery = ""
    @State private var shortcuts: [String] = []
    
    var body: some View {
        VStack {
            TextField("Search shortcuts...", text: $searchQuery)
                .textFieldStyle(.roundedBorder)
            
            Text("Shortcuts will appear here")
                .foregroundColor(.secondary)
                .padding()
            
            Spacer()
        }
        .padding(12)
        .frame(width: 360, height: 500)
    }
}

#Preview {
    ContentView()
}

