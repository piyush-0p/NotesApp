//
//  NotesHomeView.swift
//  NotesApp
//
//  Created by Piyush on 02/10/25.
//

import SwiftUI

struct NotesHomeView: View {
    @StateObject private var notesManager = NotesManager()
    @State private var searchText = ""
    @State private var isSearching = false
    
    private let semanticSearch = SemanticSearchService()
    
    var filteredNotes: [Note] {
        if searchText.isEmpty {
            return notesManager.notes
        } else {
            // Perform semantic search
            return semanticSearch.searchNotes(searchText, in: notesManager.notes)
        }
    }
    
    var body: some View {
        NavigationStack{
            ZStack {
                Color("background")
                    .ignoresSafeArea()
                
                if notesManager.notes.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "note.text")
                            .font(.system(size: 60))
                            .opacity(0.3)
                        Text("No notes yet")
                            .font(.title3)
                            .opacity(0.5)
                        Text("Tap the + button to create a note")
                            .font(.caption)
                            .opacity(0.4)
                    }
                } else if !searchText.isEmpty && filteredNotes.isEmpty {
                    VStack(spacing: 10) {
                        Image(systemName: "doc.text")
                            .font(.system(size: 60))
                            .opacity(0.3)
                        Text("No results found")
                            .font(.title3)
                            .opacity(0.5)
                    }
                } else {
                    List {
                        ForEach(filteredNotes) { note in
                            ZStack {
                                NavigationLink(destination: NoteTakingView(notesManager: notesManager, note: note)) {
                                    EmptyView()
                                }
                                .opacity(0)
                                
                                NotesCardView(note: note)
                            }
                            .listRowBackground(Color.clear)
                            .listRowSeparator(.hidden)
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    notesManager.deleteNote(note)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }
                            }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle("Notes")
            .searchable(text: $searchText, isPresented: $isSearching, prompt: "Search notes")
            .onChange(of: isSearching) { oldValue, newValue in
                if !newValue {
                    searchText = ""
                }
            }
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing){
                    Button(action: {
                        isSearching = true
                    }){
                        Image(systemName: "magnifyingglass")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing){
                    NavigationLink(destination: NoteTakingView(notesManager: notesManager, note: nil)) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct NotesCardView: View {
    let note: Note
    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        VStack (alignment:.leading, spacing: 8){
            // Card background
            RoundedRectangle(cornerRadius: 20)
                .foregroundColor(.clear)
                .frame(height: 100)
                .background(colorScheme == .dark ? .white.opacity(0.2) : .white)
                .overlay(
                    VStack(alignment: .leading){
                        HStack{
                            Text(note.previewText)
                                .foregroundColor(.primary)
                                .opacity(0.7)
                                .lineLimit(3)
                            
                            Spacer()
                        }
                        Spacer()
                    }
                        .padding([.top, .leading, .trailing])
                )
                .cornerRadius(20)
            
            //Date
            Text(note.formattedDate)
                .font(.system(size: 12))
                .foregroundColor(.primary)
                .opacity(0.4)
                .padding(.leading, 8)
        }
        .padding(.vertical, -2)
    }
}


#Preview {
    NotesHomeView()
}
