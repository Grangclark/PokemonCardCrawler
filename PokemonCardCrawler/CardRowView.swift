//
//  CardRowView.swift
//  PokemonCardCrawler
//
//  Created by 長橋和敏 on 2025/05/05.
//

import SwiftUI
import CoreData

struct CardRowView: View {
    let card: CDPokemonCard
    @State private var cardImage: NSImage?
    
    var body: some View {
        HStack {
            if let cardImage = cardImage {
                Image(nsImage: cardImage)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 80)
                    .cornerRadius(4)
            } else {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.gray.opacity(0.3))
                    .frame(width: 60, height: 80)
            }
            
            VStack(alignment: .leading) {
                Text(card.name)
                    .font(.headline)
                
                HStack {
                    Text(card.cardID)
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    if let expansion = card.expansion {
                        Text("・ \(expansion)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    if let rarity = card.rarity {
                        Text("・ \(rarity)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
        .onAppear(perform: loadCardImage)
    }
    
    private func loadCardImage() {
        // guard cardImage == nil, let imageURL = card.imageURL, let url = URL(string: imageURL) else {
        guard cardImage == nil, !card.imageURL.isEmpty, let url = URL(string: card.imageURL) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { data, _, error in
            if let data = data, let image = NSImage(data: data) {
                DispatchQueue.main.async {
                    self.cardImage = image
                }
            }
        }.resume()
    }
}
