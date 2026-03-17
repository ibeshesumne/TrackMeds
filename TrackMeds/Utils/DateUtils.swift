//
//  DateUtils.swift
//  TrackMeds
//

import Foundation

enum DateUtils {
    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        f.locale = Locale.current
        return f
    }()

    private static let dateTimeFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd HH:mm:ss"
        f.locale = Locale.current
        return f
    }()

    static func formatDate(_ timestamp: Int64) -> String {
        dateFormatter.string(from: Date(milliseconds: timestamp))
    }

    static func formatDateTime(_ timestamp: Int64) -> String {
        dateTimeFormatter.string(from: Date(milliseconds: timestamp))
    }

    static func parseDate(_ dateString: String) -> Int64 {
        if let date = dateTimeFormatter.date(from: dateString) ?? dateTimeFormatter.date(from: dateString + " 00:00:00") {
            return date.milliseconds
        }
        if let date = dateFormatter.date(from: dateString) {
            return date.milliseconds
        }
        return 0
    }

    static func getDateOnly(_ timestamp: Int64) -> Int64 {
        let calendar = Calendar.current
        var components = calendar.dateComponents([.year, .month, .day], from: Date(milliseconds: timestamp))
        components.hour = 0
        components.minute = 0
        components.second = 0
        return (calendar.date(from: components) ?? Date()).milliseconds
    }
}

extension Date {
    var milliseconds: Int64 {
        Int64(timeIntervalSince1970 * 1000)
    }

    init(milliseconds: Int64) {
        self.init(timeIntervalSince1970: Double(milliseconds) / 1000)
    }
}
