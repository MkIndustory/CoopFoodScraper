//
//  Menu.swift
//  CoopFoodScraper
//
//  Created by ぴっきー！ on 2024/03/30.
//

import Foundation

struct Menu: Codable {
    var name: String //食堂の名前
    var foods: [Food] //Foodの配列
}
