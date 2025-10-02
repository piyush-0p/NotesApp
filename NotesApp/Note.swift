//
//  Note.swift
//  NotesApp
//
//  Created by Piyush on 03/10/25.
//

import Foundation

struct Note: Identifiable, Codable {
    var id = UUID()
    var content: String
    var createdAt: Date
    var modifiedAt: Date
    
    // Get preview text (first few lines)
    var previewText: String {
        let lines = content.components(separatedBy: .newlines)
        let preview = lines.prefix(3).joined(separator: " ")
        return preview.isEmpty ? "No content" : preview
    }
    
    // Format date for display
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM yyyy 'at' h:mm a"
        return formatter.string(from: modifiedAt)
    }
}
