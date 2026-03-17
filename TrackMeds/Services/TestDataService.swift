//
//  TestDataService.swift
//  TrackMeds
//

import Foundation
import CoreData

enum TestDataService {
    static let testDataPrefix = "Test:"

    static func generateTestData(
        recordRepo: MedicalRecordRepository,
        medicationRepo: MedicationRepository
    ) throws {
        let calendar = Calendar.current
        let now = Date()
        let sevenDaysAgo = calendar.date(byAdding: .day, value: -7, to: now) ?? now

        let testMedications: [(name: String, dosageMg: Int32, capsuleCount: Int32, frequency: String, daysPerWeek: Set<Int>)] = [
            ("Test: Aspirin", 100, 2, "Daily", [0, 1, 2, 3, 4, 5, 6]),
            ("Test: Bicalutamide", 150, 1, "3 times per week", [1, 3, 5]),
            ("Test: Vitamin D", 1000, 1, "2 times per week", [2, 5])
        ]

        var medications: [Medication] = []

        for (name, dosageMg, capsuleCount, frequency, _) in testMedications {
            let startDate = sevenDaysAgo.milliseconds
            let endDate = now.addingTimeInterval(365 * 24 * 60 * 60).milliseconds
            let med = Medication(
                id: UUID().uuidString,
                name: name,
                dosageMg: dosageMg,
                capsuleCount: capsuleCount,
                startDate: startDate,
                endDate: endDate,
                useIntervalInsteadOfEndDate: false,
                intervalDays: 0,
                frequency: frequency,
                version: 1
            )
            try medicationRepo.insert(med)
            medications.append(med)
        }

        for dayOffset in 0..<7 {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: now) else { continue }
            let weekday = calendar.component(.weekday, from: date) - 1
            let dateMs = date.milliseconds

            for (med, config) in zip(medications, testMedications) {
                guard config.daysPerWeek.contains(weekday) else { continue }
                let record = MedicalRecord(
                    uuid: UUID().uuidString,
                    date: dateMs,
                    medication: med.displayLabel,
                    tabletDosage: med.dosageMg,
                    tabletCount: med.capsuleCount,
                    weight: dayOffset == 0 ? 72.5 : 0,
                    exerciseDuration: dayOffset % 2 == 0 ? 30 : 0,
                    sideEffectExperienced: dayOffset == 3 && med.name.contains("Bicalutamide"),
                    sideEffectDescription: dayOffset == 3 && med.name.contains("Bicalutamide") ? "Mild fatigue" : "",
                    startDate: med.startDate,
                    endDate: med.endDate,
                    createdAt: dateMs,
                    amendedAt: nil,
                    version: 1
                )
                try recordRepo.insert(record)
            }
        }
    }
}
