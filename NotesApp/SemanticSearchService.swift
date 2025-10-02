//
//  SemanticSearchService.swift
//  NotesApp
//
//  Created by Piyush on 03/10/25.
//

import Foundation
import CoreML

class SemanticSearchService {
    private let tokenizer = Tokenizer()
    private var model: SentenceEmbedding?
    
    init() {
        loadModel()
    }
    
    private func loadModel() {
        do {
            let config = MLModelConfiguration()
            model = try SentenceEmbedding(configuration: config)
        } catch {
            print("Failed to load model: \(error)")
        }
    }
    
    func getEmbedding(for text: String) -> [Float]? {
        guard let model = model else { return nil }
        
        let (inputIds, attentionMask) = tokenizer.tokenize(text)
        
        do {
            // Create MLMultiArray for input_ids
            let inputIdsArray = try MLMultiArray(shape: [1, 128] as [NSNumber], dataType: .int32)
            for (index, id) in inputIds.enumerated() {
                inputIdsArray[index] = NSNumber(value: id)
            }
            
            // Create MLMultiArray for attention_mask
            let attentionMaskArray = try MLMultiArray(shape: [1, 128] as [NSNumber], dataType: .int32)
            for (index, mask) in attentionMask.enumerated() {
                attentionMaskArray[index] = NSNumber(value: mask)
            }
            
            // Create input
            let input = SentenceEmbeddingInput(
                input_ids: inputIdsArray,
                attention_mask: attentionMaskArray
            )
            
            // Get prediction
            let output = try model.prediction(input: input)
            
            // Extract embedding - the model outputs embeddings directly (shape: [1, 384])
            let embeddingArray = output.embeddings
            let hiddenSize = 384
            
            var embedding = [Float](repeating: 0, count: hiddenSize)
            for i in 0..<hiddenSize {
                embedding[i] = embeddingArray[i].floatValue
            }
            
            // The model already outputs normalized embeddings, but normalize again to be sure
            let norm = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
            if norm > 0 {
                embedding = embedding.map { $0 / norm }
            }
            
            return embedding
            
        } catch {
            print("Error getting embedding: \(error)")
            return nil
        }
    }
    
    func cosineSimilarity(_ embedding1: [Float], _ embedding2: [Float]) -> Float {
        guard embedding1.count == embedding2.count else { return 0 }
        
        let dotProduct = zip(embedding1, embedding2).reduce(0) { $0 + $1.0 * $1.1 }
        return dotProduct // Already normalized, so no need to divide by norms
    }
    
    func searchNotes(_ query: String, in notes: [Note]) -> [Note] {
        guard let queryEmbedding = getEmbedding(for: query) else {
            return notes
        }
        
        var notesWithScores: [(note: Note, score: Float)] = []
        
        for note in notes {
            if let noteEmbedding = getEmbedding(for: note.content) {
                let similarity = cosineSimilarity(queryEmbedding, noteEmbedding)
                notesWithScores.append((note, similarity))
            }
        }
        
        // Sort by similarity (highest first)
        notesWithScores.sort { $0.score > $1.score }
        
        // Return notes sorted by relevance
        return notesWithScores.map { $0.note }
    }
}
