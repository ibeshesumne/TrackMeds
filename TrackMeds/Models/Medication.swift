//
//  Medication.swift
//  TrackMeds
//

import Foundation

struct Medication: Identifiable, Equatable {
    let id: String
    var name: String
    var dosageMg: Int32
    var capsuleCount: Int32
    var startDate: Int64
    var endDate: Int64
    var useIntervalInsteadOfEndDate: Bool
    var intervalDays: Int32
    var frequency: String
    var version: Int32

    init(
        id: String = UUID().uuidString,
        name: String = "",
        dosageMg: Int32 = 0,
        capsuleCount: Int32 = 0,
        startDate: Int64 = 0,
        endDate: Int64 = 0,
        useIntervalInsteadOfEndDate: Bool = false,
        intervalDays: Int32 = 0,
        frequency: String = "",
        version: Int32 = 1
    ) {
        self.id = id
        self.name = name
        self.dosageMg = dosageMg
        self.capsuleCount = capsuleCount
        self.startDate = startDate
        self.endDate = endDate
        self.useIntervalInsteadOfEndDate = useIntervalInsteadOfEndDate
        self.intervalDays = intervalDays
        self.frequency = frequency
        self.version = version
    }

    var effectiveEndDate: Int64 {
        if useIntervalInsteadOfEndDate && intervalDays > 0 && startDate > 0 {
            return startDate + Int64(intervalDays) * 24 * 60 * 60 * 1000
        }
        return endDate
    }

    var displayLabel: String {
        dosageMg > 0 ? "\(name) (\(dosageMg) mg)" : name
    }
}
