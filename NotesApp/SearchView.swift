//
//  SearchView.swift
//  NotesApp
//
//  Created by Piyush on 03/10/25.
//

import SwiftUI

struct SearchView: View {
    @ObservedObject var notesManager: NotesManager
    @Environment(\.dismiss) var dismiss
    
    @State private var searchQuery = ""
    @State private var searchResults: [Note] = []
    @State private var isSearching = false
    
    private let semanticSearch = SemanticSearchService()
    
    var body: some View {
        ZStack {
            Color("background")
                .ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Search Bar
                HStack {
                    Image(systemName: "magnifyingglass")
                        .foregroundColor(.gray)
                    
                    TextField("Search notes...", text: $searchQuery)
                        .textFieldStyle(.plain)
                        .onChange(of: searchQuery) { oldValue, newValue in
                            performSearch()
                        }
                    
                    if !searchQuery.isEmpty {
                        Button {
                            searchQuery = ""
                            searchResults = []
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundColor(.gray)
                        }
                    }
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
                .padding()
                
                // Results
                if isSearching {
                    ProgressView("Searching...")
                        .padding()
                } else if searchQuery.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "doc.text.magnifyingglass")
                            .font(.system(size: 60))
                            .opacity(0.3)
                        Text("Semantic Search")
                            .font(.title3)
                            .opacity(0.5)
                        Text("Enter a query to search through your notes")
                            .font(.caption)
                            .opacity(0.4)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 100)
                } else if searchResults.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .opacity(0.3)
                        Text("No results found")
                            .font(.title3)
                            .opacity(0.5)
                    }
                    .padding(.top, 100)
                } else {
                    List {
                        ForEach(searchResults) { note in
                            ZStack {
                                NavigationLink(destination: NoteTakingView(notesManager: notesManager, note: note)) {
                                    EmptyView()
                                }
                                .opacity(0)
                                
                                NotesCardView(note: note)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
        }
        .navigationTitle("Search")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func performSearch() {
        guard !searchQuery.isEmpty else {
            searchResults = []
            return
        }
        
        isSearching = true
        
        // Perform search on background thread
        DispatchQueue.global(qos: .userInitiated).async {
            let results = semanticSearch.searchNotes(searchQuery, in: notesManager.notes)
            
            DispatchQueue.main.async {
                searchResults = results
                isSearching = false
            }
        }
    }
}

#Preview {
    NavigationStack {
        SearchView(notesManager: NotesManager())
    }
}
