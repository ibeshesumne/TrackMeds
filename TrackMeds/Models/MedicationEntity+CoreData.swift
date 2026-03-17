//
//  MedicationEntity+CoreData.swift
//  TrackMeds
//

import CoreData

extension MedicationEntity {
    func toModel() -> Medication {
        Medication(
            id: id ?? UUID().uuidString,
            name: name ?? "",
            dosageMg: dosageMg,
            capsuleCount: capsuleCount,
            startDate: startDate,
            endDate: endDate,
            useIntervalInsteadOfEndDate: useIntervalInsteadOfEndDate,
            intervalDays: intervalDays,
            frequency: frequency ?? "",
            version: version
        )
    }

    func update(from model: Medication) {
        id = model.id
        name = model.name
        dosageMg = model.dosageMg
        capsuleCount = model.capsuleCount
        startDate = model.startDate
        endDate = model.endDate
        useIntervalInsteadOfEndDate = model.useIntervalInsteadOfEndDate
        intervalDays = model.intervalDays
        frequency = model.frequency
        version = model.version
    }
}
