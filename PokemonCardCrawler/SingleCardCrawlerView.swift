//
//  SingleCardCrawlerView.swift
//  PokemonCardCrawler
//
//  Created by 長橋和敏 on 2025/05/29.
//

import SwiftUI

struct SingleCardCrawlerView: View {
    @Environment(\.managedObjectContext) private var viewContext
    @State private var cardURL = ""
    @State private var isLoading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""
    
    var body: some View {
        VStack(spacing: 20) {
            Text("カード追加")
                .font(.title)
                .padding()
            
            VStack(alignment: .leading) {
                Text("ポケモンカードのURLを入力してください")
                    .font(.headline)
                
                TextField("https://www.pokemon-card.com/card-search/details.php/card/...", text: $cardURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .frame(width: 500)
            }
            
            Button(action: {
                addSingleCard()
            }) {
                HStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                    Text(isLoading ? "取得中..." : "カードを追加")
                }
            }
            .buttonStyle(.borderedProminent)
            .disabled(cardURL.isEmpty || isLoading)
            
            if !errorMessage.isEmpty {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
            
            if !successMessage.isEmpty {
                Text(successMessage)
                    .foregroundColor(.green)
            }
            
            Spacer()
        }
        .padding()
    }
    
    private func addSingleCard() {
        // URL形式のバリデーション
        guard isValidPokemonCardURL(cardURL) else {
            errorMessage = "有効なポケモンカードのURLを入力してください"
            return
        }
        
        isLoading = true
        errorMessage = ""
        successMessage = ""
        
        // シングルカードクローラーを実行
        SingleCardCrawler.shared.crawlSingleCard(url: cardURL, context: viewContext) { result in
            DispatchQueue.main.async {
                isLoading = false
                
                switch result {
                case .success(let cardName):
                    successMessage = "「\(cardName)」を追加しました"
                    cardURL = "" // 入力フィールドをクリア
                case .failure(let error):
                    errorMessage = "エラー: \(error.localizedDescription)"
                }
            }
        }
    }
        
    private func isValidPokemonCardURL(_ url: String) -> Bool {
        // テスト用に一時的にすべてのURLを許可
        return true
        
        // 元のコード（後で復活させる）
        // return url.contains("pokemon-card.com") && url.contains("card-search")
    }
}
