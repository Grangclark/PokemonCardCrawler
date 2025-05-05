//
//  CardDetailView.swift
//  PokemonCardCrawler
//
//  Created by 長橋和敏 on 2025/05/05.
//

import SwiftUI

/*
struct CardDetailView: View {
    var body: some View {
        Text(/*@START_MENU_TOKEN@*/"Hello, World!"/*@END_MENU_TOKEN@*/)
    }
}

struct CardDetailView_Previews: PreviewProvider {
    static var previews: some View {
        CardDetailView()
    }
}
*/

struct CardDetailView: View {
    let card: Card
    @State private var cardImage: NSImage?
    
    var body: some View {
        ScrollView {
            VStack(alignment: .center, spacing: 20) {
                if let cardImage = cardImage {
                    Image(nsImage: cardImage)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(maxHeight: 400)
                        .cornerRadius(10)
                        .shadow(radius: 5)
                } else {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 245, height: 342)
                }
                
                VStack(alignment: .leading, spacing: 15) {
                    Group {
                        Text(card.name ?? "不明なカード")
                            .font(.title)
                            .bold()
                        
                        Divider()
                        
                        if let cardID = card.cardID {
                            detailRow(title: "カードID", value: cardID)
                        }
                        
                        if let expansion = card.expansion {
                            detailRow(title: "拡張セット", value: expansion)
                        }
                        
                        if let rarity = card.rarity {
                            detailRow(title: "レアリティ", value: rarity)
                        }
                        
                        if let cardType = card.cardType {
                            detailRow(title: "タイプ", value: cardType)
                        }
                        
                        if let hp = card.hp, hp > 0 {
                            detailRow(title: "HP", value: "\(hp)")
                        }
                    }
                    
                    Group {
                        if let attack1 = card.attack1, !attack1.isEmpty {
                            detailRow(title: "技1", value: attack1)
                        }
                        
                        if let attack2 = card.attack2, !attack2.isEmpty {
                            detailRow(title: "技2", value: attack2)
                        }
                        
                        if let ability = card.ability, !ability.isEmpty {
                            detailRow(title: "特性", value: ability)
                        }
                        
                        if let weakness = card.weakness, !weakness.isEmpty {
                            detailRow(title: "弱点", value: weakness)
                        }
                        
                        if let resistance = card.resistance, !resistance.isEmpty {
                            detailRow(title: "抵抗力", value: resistance)
                        }
                        
                        if let retreatCost = card.retreatCost, retreatCost > 0 {
                            detailRow(title: "逃げるコスト", value: "\(retreatCost)")
                        }
                    }
                    
                    if let pageURL = card.pageURL {
                        Link("公式サイトで見る", destination: URL(string: pageURL)!)
                            .padding(.top, 10)
                    }
                }
                .padding()
                .frame(maxWidth: 600)
            }
            .padding()
        }
        .navigationTitle(card.name ?? "カード詳細")
        .onAppear(perform: loadCardImage)
    }
    
    private func detailRow(title: String, value: String) -> some View {
        HStack(alignment: .top) {
            Text(title + ":")
                .frame(width: 100, alignment: .leading)
                .font(.headline)
            
            Text(value)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
    
    private func loadCardImage() {
        guard cardImage == nil, let imageURL = card.imageURL, let url = URL(string: imageURL) else {
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
