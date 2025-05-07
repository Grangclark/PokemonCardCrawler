//
//  CDPokemonCard+CoreDataProperties.swift
//  PokemonCardCrawler
//
//  Created by 長橋和敏 on 2025/05/06.
//

import Foundation

import CoreData

extension CDPokemonCard {
    @nonobjc public class func fetchRequest() -> NSFetchRequest<CDPokemonCard> {
        return NSFetchRequest<CDPokemonCard>(entityName: "CDPokemonCard")
    }

    // 他のプロパティも同様に定義
    @NSManaged public var cardID: String
    @NSManaged public var name: String
    @NSManaged public var imageURL: String
    @NSManaged public var pageURL: String
    @NSManaged public var expansion: String?
    @NSManaged public var rarity: String?
    @NSManaged public var cardType: String?
    @NSManaged public var hp: NSNumber?
    @NSManaged public var attack1: String?
    @NSManaged public var attack2: String?
    @NSManaged public var ability: String?
    @NSManaged public var weakness: String?
    @NSManaged public var resistance: String?
    @NSManaged public var retreatCost: NSNumber?
    @NSManaged public var timestamp: Date?
}
