//
//  NotesHomeView.swift
//  NotesApp
//
//  Created by Piyush on 02/10/25.
//

import SwiftUI

struct NotesHomeView: View {
    var body: some View {
        NavigationStack{
            ScrollView{
                VStack(spacing: 20){
                    NotesCardView()
                    NotesCardView()
                    NotesCardView()
                    NotesCardView()
                }
                .padding()
            }
            .background(Color("background"))
            .navigationTitle("Notes")
            .toolbar{
                ToolbarItem(placement: .navigationBarTrailing){
                    Button(action: {
                        
                    }){
                        Image(systemName: "magnifyingglass")
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing){
                    Button(action: {
                        
                    }){
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

struct NotesCardView: View {

    @Environment(\.colorScheme) var colorScheme
    
    var body: some View {
        
            VStack (alignment:.leading){
                // Card background
                RoundedRectangle(cornerRadius: 20)
                    .foregroundColor(.clear)
                    .frame(height: 100)
                    .background(colorScheme == .dark ? .white.opacity(0.2) : .white)
                    .overlay(
                        VStack{
                            Text("this is the test text for the notes application that i have to build a semantic search upon i hope this will work for me this time. i repate this is testing text")
                                .opacity(0.7)
                                .lineLimit(3)
                            Spacer()
                        }
                            .padding([.top, .leading, .trailing])
                    )
                    .cornerRadius(20)
                
                //Date
                Text("22 sep 2025 at 11:30 pm")
                    .font(.system(size: 13))
                    .opacity(0.5)
                    .padding(.leading)
            }
            
            
        
    }
}


#Preview {
    NotesHomeView()
   // NotesCardView()
}
