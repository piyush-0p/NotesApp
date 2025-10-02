//
//  Tokenizer.swift
//  NotesApp
//
//  Created by Piyush on 03/10/25.
//

import Foundation

class Tokenizer {
    private var vocabulary: [String: Int] = [:]
    private let maxSequenceLength = 128
    
    init() {
        loadVocabulary()
    }
    
    private func loadVocabulary() {
        guard let path = Bundle.main.path(forResource: "vocab", ofType: "txt"),
              let content = try? String(contentsOfFile: path, encoding: .utf8) else {
            print("Failed to load vocabulary file")
            return
        }
        
        let tokens = content.components(separatedBy: .newlines)
        for (index, token) in tokens.enumerated() {
            vocabulary[token] = index
        }
    }
    
    func tokenize(_ text: String) -> (inputIds: [Int], attentionMask: [Int]) {
        let lowercasedText = text.lowercased()
        let words = lowercasedText.components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
        
        var tokens: [String] = ["[CLS]"]
        
        for word in words {
            let wordTokens = wordPieceTokenize(word)
            tokens.append(contentsOf: wordTokens)
        }
        
        tokens.append("[SEP]")
        
        // Convert tokens to IDs
        var inputIds = tokens.compactMap { vocabulary[$0] ?? vocabulary["[UNK]"] }
        
        // Truncate or pad to maxSequenceLength
        if inputIds.count > maxSequenceLength {
            inputIds = Array(inputIds.prefix(maxSequenceLength))
        }
        
        let attentionMask = Array(repeating: 1, count: inputIds.count)
        
        // Pad to maxSequenceLength
        while inputIds.count < maxSequenceLength {
            inputIds.append(0) // PAD token
        }
        
        var paddedAttentionMask = attentionMask
        while paddedAttentionMask.count < maxSequenceLength {
            paddedAttentionMask.append(0)
        }
        
        return (inputIds, paddedAttentionMask)
    }
    
    private func wordPieceTokenize(_ word: String) -> [String] {
        if vocabulary[word] != nil {
            return [word]
        }
        
        var tokens: [String] = []
        var start = word.startIndex
        
        while start < word.endIndex {
            var end = word.endIndex
            var foundToken: String? = nil
            
            while start < end {
                let substring = String(word[start..<end])
                let token = start == word.startIndex ? substring : "##\(substring)"
                
                if vocabulary[token] != nil {
                    foundToken = token
                    break
                }
                
                end = word.index(before: end)
            }
            
            if let token = foundToken {
                tokens.append(token)
                start = end
            } else {
                tokens.append("[UNK]")
                start = word.index(after: start)
            }
        }
        
        return tokens
    }
}
