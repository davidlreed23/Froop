//
//  PayWallModel.swift
//  FroopProof
//
//  Created by David Reed on 1/25/24.
//

import Foundation
import SwiftUI

struct PaywallModel: Codable {
    var title: String
    var subTitle: String
    var headerImage: String
    var stretchyHeader: Bool
    var stickyHeader: Bool
    var stickyHeaderTitle: String
    var points: [Point]
    var reviews: [Review]
    var showReviews: Bool
    var showDefaultView: Bool
    
    enum CodingKeys: CodingKey {
        case title
        case subTitle
        case headerImage
        case stretchyHeader
        case stickyHeader
        case stickyHeaderTitle
        case points
        case reviews
        case showReviews
        case showDefaultView
    }
    
    struct Point: Identifiable, Codable {
        let id: UUID = .init()
        var symbol: String
        var content: String
        var color: String
        
        enum CodingKeys: CodingKey {
            case symbol
            case content
            case color
        }
        
        var colorValue: Color {
            switch color {
            case "Green":
                return .green
            case "Red":
                return .red
            case "Yellow":
                return .yellow
            case "Blue":
                return Color(red: 255/255, green: 49/255, blue: 97/255)
            case "Orange":
                return .orange
            case "Purple":
                return .purple
            case "Cyan" :
                return .cyan
            default:
                return .primary
            }
        }
    }
    
    struct Review: Identifiable, Codable {
        let id: UUID = .init()
        var name: String
        var rating: Int
        var content: String
        
        enum CodingKeys: CodingKey {
            case name
            case rating
            case content
        }
    }
}
