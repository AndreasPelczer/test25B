//
//  JSONProduct.swift
//  test25B
//
//  Created by Andreas Pelczer on 12.01.26.
//


import Foundation

// MARK: - Root Product DTO
struct JSONProduct: Decodable {
    let id: String
    let name: String
    let kategorie: String
    let typ: String
    let beschreibung: String?
    let metadata: JSONProductMetadata?
    let rezept: JSONRecipe?
}

// MARK: - Metadata
struct JSONProductMetadata: Decodable {
    let allergene: String?
    let zusatzstoffe: String?
    let kcal_100g: String?
    let fett: String?
    let zucker: String?
}

// MARK: - Recipe
struct JSONRecipe: Decodable {
    let portionen: String
    let algorithmus: [String]
    let komponenten: [JSONIngredient]
}

// MARK: - Ingredient
struct JSONIngredient: Decodable {
    let name: String
    let menge: String
    let einheit: String
}
