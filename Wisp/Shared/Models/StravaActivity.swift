//
//  StravaActivity.swift
//  Wisp
//
//  Created by Ege Hurturk on 24.07.2025.
//

import Foundation

struct StravaActivity: Codable, Identifiable {
    let id: Int
    let name: String
    let distance: Double
    let movingTime: Int
    let elapsedTime: Int
    let type: String
    let startDate: String
    let map: ActivityMap

    struct ActivityMap: Codable {
        let id: String
        let summaryPolyline: String?

        enum CodingKeys: String, CodingKey {
            case id
            case summaryPolyline = "summary_polyline"
        }
    }

    enum CodingKeys: String, CodingKey {
        case id, name, distance
        case movingTime = "moving_time"
        case elapsedTime = "elapsed_time"
        case type
        case startDate = "start_date"
        case map
    }
}
