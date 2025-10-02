//
//  NotesManager.swift
//  NotesApp
//
//  Created by Piyush on 03/10/25.
//

import Foundation

class NotesManager: ObservableObject {
    @Published var notes: [Note] = []
    
    private let savePath = FileManager.documentsDirectory.appendingPathComponent("notes.json")
    
    init() {
        loadNotes()
    }
    
    func addNote(_ note: Note) {
        notes.insert(note, at: 0)
        saveNotes()
    }
    
    func updateNote(_ note: Note) {
        if let index = notes.firstIndex(where: { $0.id == note.id }) {
            notes[index] = note
            saveNotes()
        }
    }
    
    func deleteNote(_ note: Note) {
        notes.removeAll { $0.id == note.id }
        saveNotes()
    }
    
    private func saveNotes() {
        do {
            let data = try JSONEncoder().encode(notes)
            try data.write(to: savePath, options: [.atomic, .completeFileProtection])
        } catch {
            print("Unable to save notes: \(error.localizedDescription)")
        }
    }
    
    private func loadNotes() {
        do {
            let data = try Data(contentsOf: savePath)
            notes = try JSONDecoder().decode([Note].self, from: data)
        } catch {
            // No saved notes yet, start with empty array
            notes = []
        }
    }
}

extension FileManager {
    static var documentsDirectory: URL {
        FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    }
}
