//
//  PersistenceController.swift
//  TrackMeds
//

import CoreData

struct PersistenceController {
    static let shared = PersistenceController()

    let container: NSPersistentContainer

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "MedTrackModel")
        if inMemory {
            container.persistentStoreDescriptions.first?.url = URL(fileURLWithPath: "/dev/null")
        }
        container.loadPersistentStores { _, error in
            if let error = error as NSError? {
                fatalError("Core Data load error: \(error), \(error.userInfo)")
            }
        }
        container.viewContext.automaticallyMergesChangesFromParent = true
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    var viewContext: NSManagedObjectContext {
        container.viewContext
    }

    func save() {
        let context = viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                let nsError = error as NSError
                print("Core Data save error: \(nsError), \(nsError.userInfo)")
            }
        }
    }

    static var preview: PersistenceController = {
        let controller = PersistenceController(inMemory: true)
        let context = controller.viewContext
        for i in 0..<5 {
            let record = MedicalRecordEntity(context: context)
            record.uuid = UUID().uuidString
            record.date = Date().milliseconds
            record.medication = "Medication \(i)"
            record.tabletDosage = 50
            record.tabletCount = 1
            record.weight = 75.0
            record.exerciseDuration = 30
            record.sideEffectExperienced = false
            record.sideEffectDescription = ""
            record.startDate = Date().milliseconds
            record.endDate = Date().addingTimeInterval(365 * 24 * 3600).milliseconds
            record.createdAt = Date().milliseconds
            record.version = 1
        }
        try? context.save()
        return controller
    }()
}
