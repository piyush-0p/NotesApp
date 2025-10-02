# Semantic Search Implementation

## Overview

This NotesApp implements semantic search using a **CoreML sentence embedding model** to enable intelligent, meaning-based search through notes. Unlike traditional keyword matching, semantic search understands the context and meaning of queries, returning relevant results even when exact words don't match.

## Architecture Components

### 1. **SemanticSearchService** (`SemanticSearchService.swift`)
The core service that handles all semantic search operations.

#### Key Responsibilities:
- **Model Loading**: Loads the CoreML `SentenceEmbedding` model
- **Embedding Generation**: Converts text into 384-dimensional vector embeddings
- **Similarity Calculation**: Computes cosine similarity between embeddings
- **Search Execution**: Ranks notes by relevance to the query

#### How it Works:

```swift
// 1. Initialize and load the CoreML model
private func loadModel() {
    let config = MLModelConfiguration()
    model = try SentenceEmbedding(configuration: config)
}
```

```swift
// 2. Convert text to embeddings (384-dimensional vectors)
func getEmbedding(for text: String) -> [Float]? {
    // Tokenize the text
    let (inputIds, attentionMask) = tokenizer.tokenize(text)
    
    // Create MLMultiArray inputs (128 tokens)
    let inputIdsArray = try MLMultiArray(shape: [1, 128], dataType: .int32)
    let attentionMaskArray = try MLMultiArray(shape: [1, 128], dataType: .int32)
    
    // Feed to model and get 384-dimensional embedding
    let output = try model.prediction(input: input)
    
    // Normalize the embedding vector
    let norm = sqrt(embedding.reduce(0) { $0 + $1 * $1 })
    return embedding.map { $0 / norm }
}
```

```swift
// 3. Calculate similarity using cosine similarity
func cosineSimilarity(_ embedding1: [Float], _ embedding2: [Float]) -> Float {
    let dotProduct = zip(embedding1, embedding2).reduce(0) { $0 + $1.0 * $1.1 }
    return dotProduct // Normalized vectors, so dot product = cosine similarity
}
```

```swift
// 4. Search and rank notes
func searchNotes(_ query: String, in notes: [Note]) -> [Note] {
    // Get query embedding
    guard let queryEmbedding = getEmbedding(for: query) else { return notes }
    
    // Calculate similarity scores for all notes
    var notesWithScores: [(note: Note, score: Float)] = []
    for note in notes {
        let noteEmbedding = getEmbedding(for: note.content)
        let similarity = cosineSimilarity(queryEmbedding, noteEmbedding)
        notesWithScores.append((note, similarity))
    }
    
    // Sort by relevance (highest similarity first)
    notesWithScores.sort { $0.score > $1.score }
    return notesWithScores.map { $0.note }
}
```

---

### 2. **Tokenizer** (`Tokenizer.swift`)
Converts text into token IDs that the CoreML model can process.

#### Key Features:
- **BERT-style WordPiece Tokenization**: Breaks text into subword tokens
- **Vocabulary Management**: Loads and uses `vocab.txt` (BERT vocabulary)
- **Special Tokens**: Adds `[CLS]` at start and `[SEP]` at end
- **Sequence Length**: Fixed at 128 tokens with padding/truncation

#### Tokenization Process:

```swift
func tokenize(_ text: String) -> (inputIds: [Int], attentionMask: [Int]) {
    // 1. Lowercase the text
    let lowercasedText = text.lowercased()
    
    // 2. Split into words
    let words = lowercasedText.components(separatedBy: .whitespacesAndNewlines)
    
    // 3. Add special tokens
    var tokens: [String] = ["[CLS]"]
    for word in words {
        let wordTokens = wordPieceTokenize(word)  // Subword tokenization
        tokens.append(contentsOf: wordTokens)
    }
    tokens.append("[SEP]")
    
    // 4. Convert to IDs using vocabulary
    var inputIds = tokens.compactMap { vocabulary[$0] ?? vocabulary["[UNK]"] }
    
    // 5. Truncate or pad to 128 tokens
    if inputIds.count > maxSequenceLength {
        inputIds = Array(inputIds.prefix(128))
    }
    
    // 6. Create attention mask (1 for real tokens, 0 for padding)
    let attentionMask = Array(repeating: 1, count: inputIds.count)
    
    // 7. Pad both arrays to 128
    while inputIds.count < 128 {
        inputIds.append(0)  // PAD token
        paddedAttentionMask.append(0)
    }
    
    return (inputIds, paddedAttentionMask)
}
```

#### WordPiece Tokenization:
```swift
// Handles unknown words by breaking them into subwords
// Example: "playing" → ["play", "##ing"]
private func wordPieceTokenize(_ word: String) -> [String] {
    // Try full word first
    if vocabulary[word] != nil { return [word] }
    
    // Otherwise, break into subword pieces
    // Uses greedy longest-match-first strategy
}
```

---

### 3. **SearchView** (`SearchView.swift`)
The user interface for semantic search.

#### Features:
- **Real-time Search**: Updates results as user types
- **Asynchronous Processing**: Runs search on background thread
- **Loading States**: Shows progress indicator during search
- **Empty States**: Displays helpful messages when no query or no results

#### Search Flow:

```swift
private func performSearch() {
    guard !searchQuery.isEmpty else {
        searchResults = []
        return
    }
    
    isSearching = true
    
    // Run on background thread to avoid UI blocking
    DispatchQueue.global(qos: .userInitiated).async {
        let results = semanticSearch.searchNotes(searchQuery, in: notesManager.notes)
        
        // Update UI on main thread
        DispatchQueue.main.async {
            searchResults = results
            isSearching = false
        }
    }
}
```

---

### 4. **SentenceEmbedding Model** (`SentenceEmbedding.mlpackage`)
CoreML model that converts sentences to embeddings.

#### Model Specifications:
- **Input**: 
  - `input_ids`: MLMultiArray of shape [1, 128] (token IDs)
  - `attention_mask`: MLMultiArray of shape [1, 128] (attention mask)
- **Output**: 
  - `embeddings`: MLMultiArray of shape [1, 384] (sentence embedding vector)
- **Type**: BERT-based sentence transformer (likely MiniLM or similar)

---

### 5. **Vocabulary File** (`vocab.txt`)
Contains the BERT WordPiece vocabulary.

#### Structure:
- ~30,000 tokens
- Includes special tokens: `[PAD]`, `[UNK]`, `[CLS]`, `[SEP]`, `[MASK]`
- Contains word pieces (e.g., "play", "##ing", "##ed")
- Each line number corresponds to token ID

---

## How Semantic Search Works

### Step-by-Step Process:

1. **User enters a search query** (e.g., "machine learning concepts")

2. **Tokenization**:
   ```
   "machine learning concepts"
   → ["[CLS]", "machine", "learning", "concepts", "[SEP]"]
   → [101, 3698, 2861, 10838, 102, 0, 0, ...] (padded to 128)
   ```

3. **Generate Query Embedding**:
   ```
   Token IDs → CoreML Model → 384-dimensional vector
   Example: [0.42, -0.18, 0.91, ..., 0.15]
   ```

4. **Generate Note Embeddings**:
   - For each note, convert content to embedding
   - Cache could be implemented for efficiency (currently computed on-the-fly)

5. **Calculate Similarity**:
   ```
   Cosine Similarity = dot product of normalized vectors
   
   Query:  [0.42, -0.18, 0.91, ...]
   Note 1: [0.38, -0.22, 0.87, ...] → Similarity: 0.94
   Note 2: [0.15, 0.72, -0.33, ...] → Similarity: 0.31
   Note 3: [0.41, -0.19, 0.89, ...] → Similarity: 0.98
   ```

6. **Rank and Return**:
   ```
   Results sorted by similarity:
   1. Note 3 (0.98) - Most relevant
   2. Note 1 (0.94) - Very relevant
   3. Note 2 (0.31) - Less relevant
   ```

---

## Key Concepts

### Embeddings
- **Definition**: Dense vector representations of text that capture semantic meaning
- **Dimension**: 384 floating-point numbers per text
- **Property**: Similar meanings → Similar vectors (close in vector space)

### Cosine Similarity
- **Range**: -1 to 1 (with normalized vectors: 0 to 1)
- **Formula**: `cos(θ) = A·B / (||A|| × ||B||)`
- **Normalized**: Since vectors are normalized, `cos(θ) = A·B` (dot product)
- **Interpretation**: 
  - 1.0 = Identical meaning
  - 0.9+ = Very similar
  - 0.7-0.9 = Somewhat similar
  - <0.5 = Not very similar

### BERT Tokenization
- **WordPiece**: Subword tokenization to handle rare/unknown words
- **Special Tokens**:
  - `[CLS]`: Classification token (start of sequence)
  - `[SEP]`: Separator token (end of sequence)
  - `[PAD]`: Padding token
  - `[UNK]`: Unknown token
- **Max Length**: 128 tokens (trade-off between context and speed)

---

## Advantages of This Approach

1. **Semantic Understanding**:
   - Query "ML algorithms" matches notes about "machine learning techniques"
   - Understands synonyms and related concepts

2. **No Keyword Dependence**:
   - Finds relevant results even without exact word matches
   - Better than traditional full-text search

3. **On-Device Processing**:
   - Uses CoreML for fast, private inference
   - No network requests required
   - Works offline

4. **Ranking by Relevance**:
   - Results ordered by semantic similarity
   - Most relevant notes appear first

---

## Potential Improvements

1. **Embedding Cache**:
   ```swift
   // Store note embeddings to avoid recomputation
   private var embeddingCache: [UUID: [Float]] = [:]
   ```

2. **Batch Processing**:
   - Process multiple notes simultaneously
   - Improve performance for large note collections

3. **Incremental Updates**:
   - Only recompute embeddings for modified notes
   - Update cache instead of full recomputation

4. **Similarity Threshold**:
   ```swift
   // Filter out results below certain similarity
   let threshold: Float = 0.5
   return notesWithScores.filter { $0.score >= threshold }
   ```

5. **Hybrid Search**:
   - Combine semantic search with keyword matching
   - Best of both approaches

6. **Result Snippets**:
   - Highlight relevant sections in search results
   - Show why a note matched the query

---

## Performance Considerations

- **Model Size**: ~14 MB (lightweight BERT variant)
- **Inference Time**: ~50-100ms per text on modern devices
- **Memory**: Minimal (model loaded once, embeddings computed on-demand)
- **Scalability**: Linear with number of notes (O(n) for n notes)
- **Background Processing**: Prevents UI blocking during search

---

## Technical Stack

- **Language**: Swift
- **ML Framework**: CoreML
- **Model Type**: BERT-based sentence transformer
- **UI Framework**: SwiftUI
- **Architecture**: MVVM pattern with service layer

---

## Conclusion

This semantic search implementation provides intelligent, context-aware search functionality for the NotesApp. By leveraging BERT embeddings and cosine similarity, it delivers superior search results compared to traditional keyword matching, all while maintaining privacy through on-device processing.
