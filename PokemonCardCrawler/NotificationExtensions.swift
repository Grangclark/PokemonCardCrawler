//
//  NotificationExtensions.swift
//  PokemonCardCrawler
//
//  Created by 長橋和敏 on 2025/05/05.
//

import Foundation
import CoreData

extension Notification.Name {
    static let startCrawling = Notification.Name("startCrawling")
    static let clearDatabase = Notification.Name("clearDatabase")
}
