//
//  MedicalRecordEntity+CoreData.swift
//  TrackMeds
//

import CoreData

extension MedicalRecordEntity {
    func toModel() -> MedicalRecord {
        MedicalRecord(
            uuid: uuid ?? UUID().uuidString,
            date: date,
            medication: medication ?? "",
            tabletDosage: tabletDosage,
            tabletCount: tabletCount,
            weight: weight,
            exerciseDuration: exerciseDuration,
            sideEffectExperienced: sideEffectExperienced,
            sideEffectDescription: sideEffectDescription ?? "",
            startDate: startDate,
            endDate: endDate,
            createdAt: createdAt,
            amendedAt: amendedAt != 0 ? amendedAt : nil,
            version: version
        )
    }

    func update(from model: MedicalRecord) {
        uuid = model.uuid
        date = model.date
        medication = model.medication
        tabletDosage = model.tabletDosage
        tabletCount = model.tabletCount
        weight = model.weight
        exerciseDuration = model.exerciseDuration
        sideEffectExperienced = model.sideEffectExperienced
        sideEffectDescription = model.sideEffectDescription
        startDate = model.startDate
        endDate = model.endDate
        createdAt = model.createdAt
        amendedAt = model.amendedAt ?? 0
        version = model.version
    }
}
