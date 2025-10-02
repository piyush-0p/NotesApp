//
//  NotesHomeView.swift
//  NotesApp
//
//  Created by Piyush on 02/10/25.
//

import SwiftUI

struct NotesHomeView: View {
    @StateObject private var notesManager = NotesManager()
    
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
                } else {
                    List {
                        ForEach(notesManager.notes) { note in
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
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing){
                    Button(action: {
                        
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
                .font(.system(size: 13))
                .foregroundColor(.primary)
                .opacity(0.5)
                .padding(.leading, 4)
        }
        .padding(.vertical, 4)
    }
}


#Preview {
    NotesHomeView()
}
