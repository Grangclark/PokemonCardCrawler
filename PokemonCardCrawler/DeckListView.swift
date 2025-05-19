//
//  DeckListView.swift
//  PokemonCardCrawler
//
//  Created by 長橋和敏 on 2025/05/19.
//

import Foundation
// DeckListView.swift
import SwiftUI

struct DeckListView: View {
    @Environment(\.managedObjectContext) private var viewContext
    
    var body: some View {
        NavigationView {
            List {
                Text("デッキ機能は準備中です")
            }
            .navigationTitle("デッキ")
        }
    }
}

struct DeckListView_Previews: PreviewProvider {
    static var previews: some View {
        DeckListView()
            .environment(\.managedObjectContext, PersistenceController.shared.container.viewContext)
    }
}
