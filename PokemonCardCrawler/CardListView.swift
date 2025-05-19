//
//  CardListView.swift
//  PokemonCardCrawler
//
//  Created by 長橋和敏 on 2025/05/19.
//


import SwiftUI
import CoreData

struct CardListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        sortDescriptors: [NSSortDescriptor(keyPath: \CDPokemonCard.name, ascending: true)],
        animation: .default)
    private var cards: FetchedResults<CDPokemonCard>
    
    var body: some View {
        // NavigationStackをNavigationViewに変更
        NavigationView {
            List {
                Text("カード数: \(cards.count)").foregroundColor(.gray)
                
                ForEach(cards, id: \.self) { card in
                    CardRowView(card: card)
                }
            }
            .navigationTitle("ポケモンカード")
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        // クローラーの実行アクション
                    }) {
                        Label("クロール", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
        }
    }
}

struct CardListView_Previews: PreviewProvider {
    static var previews: some View {
        CardListView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}

/*
import Foundation

struct CardListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    @FetchRequest(
        entity: CDPokemonCard.entity(),
        sortDescriptors: [NSSortDescriptor(keyPath: \CDPokemonCard.name, ascending: true)],
        animation: .default)
    private var cards: FetchedResults<CDPokemonCard>
    
    var body: some View {
        NavigationStack {
            List {
                Text("カード数: \(cards.count)").foregroundColor(.gray)
                
                ForEach(cards, id: \.self) { card in
                    CardRowView(card: card)
                }
            }
            .navigationTitle("ポケモンカード")
            .toolbar {
                ToolbarItem {
                    Button(action: {
                        // クローラーの実行アクション
                    }) {
                        Label("クロール", systemImage: "arrow.triangle.2.circlepath")
                    }
                }
            }
        }
    }
}
*/
