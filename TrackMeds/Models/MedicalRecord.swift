//
//  MedicalRecord.swift
//  TrackMeds
//

import Foundation

struct MedicalRecord: Identifiable, Equatable {
    let uuid: String
    var date: Int64
    var medication: String
    var tabletDosage: Int32
    var tabletCount: Int32
    var weight: Float
    var exerciseDuration: Int32
    var sideEffectExperienced: Bool
    var sideEffectDescription: String
    var startDate: Int64
    var endDate: Int64
    var createdAt: Int64
    var amendedAt: Int64?
    var version: Int32

    var id: String { uuid }

    init(
        uuid: String = UUID().uuidString,
        date: Int64 = 0,
        medication: String = "",
        tabletDosage: Int32 = 0,
        tabletCount: Int32 = 0,
        weight: Float = 0,
        exerciseDuration: Int32 = 0,
        sideEffectExperienced: Bool = false,
        sideEffectDescription: String = "",
        startDate: Int64 = 0,
        endDate: Int64 = 0,
        createdAt: Int64 = 0,
        amendedAt: Int64? = nil,
        version: Int32 = 1
    ) {
        self.uuid = uuid
        self.date = date
        self.medication = medication
        self.tabletDosage = tabletDosage
        self.tabletCount = tabletCount
        self.weight = weight
        self.exerciseDuration = exerciseDuration
        self.sideEffectExperienced = sideEffectExperienced
        self.sideEffectDescription = sideEffectDescription
        self.startDate = startDate
        self.endDate = endDate
        self.createdAt = createdAt
        self.amendedAt = amendedAt
        self.version = version
    }
}
