//
//  MedicationRepository.swift
//  TrackMeds
//

import Combine
import CoreData

@MainActor
final class MedicationRepository: ObservableObject {
    @Published private(set) var refreshId = UUID()
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func getAllMedications() throws -> [Medication] {
        let request = MedicationEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MedicationEntity.startDate, ascending: false)]
        let entities = try context.fetch(request)
        return entities.map { $0.toModel() }
    }

    func getMedicationById(_ id: String) throws -> Medication? {
        let request = MedicationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        request.fetchLimit = 1
        return try context.fetch(request).first?.toModel()
    }

    func getMedicationByName(_ name: String) throws -> Medication? {
        let request = MedicationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "name == %@", name)
        request.fetchLimit = 1
        return try context.fetch(request).first?.toModel()
    }

    func getMedicationsWithEndDates() throws -> [Medication] {
        let request = MedicationEntity.fetchRequest()
        request.predicate = NSPredicate(
            format: "(startDate > 0 AND endDate > 0) OR (startDate > 0 AND useIntervalInsteadOfEndDate == YES AND intervalDays > 0)"
        )
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MedicationEntity.startDate, ascending: true)]
        let entities = try context.fetch(request)
        return entities.map { $0.toModel() }
    }

    func insert(_ medication: Medication) throws {
        let entity = MedicationEntity(context: context)
        entity.update(from: medication)
        try context.save()
    }

    func update(_ medication: Medication) throws {
        let request = MedicationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", medication.id)
        request.fetchLimit = 1
        guard let entity = try context.fetch(request).first else { return }
        entity.update(from: medication)
        try context.save()
    }

    func deleteById(_ id: String) throws {
        let request = MedicationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "id == %@", id)
        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
        try context.save()
    }

    func deleteAll() throws {
        let request = MedicationEntity.fetchRequest()
        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
        try context.save()
    }

    func deleteTestMedications() throws {
        let request = MedicationEntity.fetchRequest()
        request.predicate = NSPredicate(format: "name BEGINSWITH %@", TestDataService.testDataPrefix)
        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
        try context.save()
    }

    func insertOrUpdate(_ medication: Medication) throws {
        if let existing = try getMedicationById(medication.id) {
            if existing.version < medication.version {
                try update(medication)
            }
        } else {
            try insert(medication)
        }
    }
}
