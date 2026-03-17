//
//  MedicalRecordRepository.swift
//  TrackMeds
//

import Combine
import CoreData

@MainActor
final class MedicalRecordRepository: ObservableObject {
    @Published private(set) var refreshId = UUID()
    private let context: NSManagedObjectContext

    init(context: NSManagedObjectContext) {
        self.context = context
    }

    func getAllRecords() throws -> [MedicalRecord] {
        let request = MedicalRecordEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MedicalRecordEntity.date, ascending: false)]
        let entities = try context.fetch(request)
        return entities.map { $0.toModel() }
    }

    func getRecordById(_ uuid: String) throws -> MedicalRecord? {
        let request = MedicalRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "uuid == %@", uuid)
        request.fetchLimit = 1
        return try context.fetch(request).first?.toModel()
    }

    func getFirstRecord() throws -> MedicalRecord? {
        let request = MedicalRecordEntity.fetchRequest()
        request.sortDescriptors = [NSSortDescriptor(keyPath: \MedicalRecordEntity.date, ascending: true)]
        request.fetchLimit = 1
        return try context.fetch(request).first?.toModel()
    }

    func insert(_ record: MedicalRecord) throws {
        let entity = MedicalRecordEntity(context: context)
        entity.update(from: record)
        try context.save()
    }

    func update(_ record: MedicalRecord) throws {
        let request = MedicalRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "uuid == %@", record.uuid)
        request.fetchLimit = 1
        guard let entity = try context.fetch(request).first else { return }
        entity.update(from: record)
        try context.save()
    }

    func deleteById(_ uuid: String) throws {
        let request = MedicalRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "uuid == %@", uuid)
        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
        try context.save()
    }

    func deleteAll() throws {
        let request = MedicalRecordEntity.fetchRequest()
        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
        try context.save()
    }

    func deleteTestRecords() throws {
        let request = MedicalRecordEntity.fetchRequest()
        request.predicate = NSPredicate(format: "medication BEGINSWITH %@", TestDataService.testDataPrefix)
        let entities = try context.fetch(request)
        for entity in entities {
            context.delete(entity)
        }
        try context.save()
    }

    func insertOrUpdate(_ record: MedicalRecord) throws {
        if let existing = try getRecordById(record.uuid) {
            if existing.version < record.version {
                try update(record)
            }
        } else {
            try insert(record)
        }
    }
}
