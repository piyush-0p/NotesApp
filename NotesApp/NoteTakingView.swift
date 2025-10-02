//
//  NoteTakingView.swift
//  NotesApp
//
//  Created by Piyush on 03/10/25.
//

import SwiftUI

struct NoteTakingView: View {
    @Environment(\.dismiss) var dismiss
    @ObservedObject var notesManager: NotesManager
    
    @State private var noteContent: String
    var existingNote: Note?
    
    init(notesManager: NotesManager, note: Note? = nil) {
        self.notesManager = notesManager
        self.existingNote = note
        _noteContent = State(initialValue: note?.content ?? "")
    }
    
    var body: some View {
        TextEditor(text: $noteContent)
            .scrollContentBackground(.hidden)
            .padding()
            .background(Color("background"))
            .navigationTitle(existingNote == nil ? "New Note" : "Edit Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveNote()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(noteContent.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
    }
    
    private func saveNote() {
        let trimmedContent = noteContent.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard !trimmedContent.isEmpty else { return }
        
        if let existingNote = existingNote {
            // Update existing note
            var updatedNote = existingNote
            updatedNote.content = trimmedContent
            updatedNote.modifiedAt = Date()
            notesManager.updateNote(updatedNote)
        } else {
            // Create new note
            let newNote = Note(
                content: trimmedContent,
                createdAt: Date(),
                modifiedAt: Date()
            )
            notesManager.addNote(newNote)
        }
        
        dismiss()
    }
}

#Preview {
    NoteTakingView(notesManager: NotesManager())
}
