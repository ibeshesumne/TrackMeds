//
//  ImportExportService.swift
//  TrackMeds
//

import Foundation
import UniformTypeIdentifiers
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

struct ImportExportResult {
    var recordsImported: Int = 0
    var recordsUpdated: Int = 0
    var recordsSkipped: Int = 0
    var medicationsImported: Int = 0
    var medicationsUpdated: Int = 0
    var medicationsSkipped: Int = 0
}

@MainActor
final class ImportExportService {
    private let recordRepo: MedicalRecordRepository
    private let medicationRepo: MedicationRepository

    init(recordRepo: MedicalRecordRepository, medicationRepo: MedicationRepository) {
        self.recordRepo = recordRepo
        self.medicationRepo = medicationRepo
    }

    func exportToJSON(records: [MedicalRecord], medications: [Medication]) -> Data? {
        var root: [String: Any] = [:]
        var recordsObj: [String: Any] = [:]
        for r in records {
            var rec: [String: Any] = [
                "date": r.date,
                "medication": r.medication,
                "tabletDosage": r.tabletDosage,
                "tabletCount": r.tabletCount,
                "weight": Double(r.weight),
                "exerciseDuration": r.exerciseDuration,
                "sideEffectExperienced": r.sideEffectExperienced,
                "sideEffectDescription": r.sideEffectDescription,
                "startDate": r.startDate,
                "endDate": r.endDate,
                "createdAt": r.createdAt,
                "version": r.version,
            ]
            if let a = r.amendedAt { rec["amendedAt"] = a }
            recordsObj[r.uuid] = rec
        }
        root["medical_records"] = recordsObj

        var medsObj: [String: Any] = [:]
        for m in medications {
            medsObj[m.id] = [
                "name": m.name,
                "dosageMg": m.dosageMg,
                "capsuleCount": m.capsuleCount,
                "startDate": m.startDate,
                "endDate": m.endDate,
                "useIntervalInsteadOfEndDate": m.useIntervalInsteadOfEndDate ? 1 : 0,
                "intervalDays": m.intervalDays,
                "frequency": m.frequency,
                "version": m.version,
            ]
        }
        root["medications"] = medsObj

        return try? JSONSerialization.data(withJSONObject: root, options: .prettyPrinted)
    }

    func exportToCSV(records: [MedicalRecord]) -> String {
        var lines: [String] = ["UUID,Date,Medication,Daily Dose (mg),Tablet Count,Weight (kg),Exercise Duration (min),Symptoms,Symptoms Description,Start Date,End Date"]
        for r in records {
            let dateStr = DateUtils.formatDate(r.date)
            let startStr = r.startDate > 0 ? DateUtils.formatDate(r.startDate) : ""
            let endStr = r.endDate > 0 ? DateUtils.formatDate(r.endDate) : ""
            let weightStr = r.weight > 0 ? String(format: "%.2f", r.weight) : ""
            let exerciseStr = r.exerciseDuration > 0 ? "\(r.exerciseDuration)" : ""
            let med = escapeCsv(r.medication)
            let desc = escapeCsv(r.sideEffectDescription)
            lines.append("\(r.uuid),\(dateStr),\(med),\(r.tabletDosage),\(r.tabletCount),\(weightStr),\(exerciseStr),\(r.sideEffectExperienced),\(desc),\(startStr),\(endStr)")
        }
        return lines.joined(separator: "\n")
    }

    func importFromJSON(_ data: Data) throws -> ImportExportResult {
        var result = ImportExportResult()
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return result
        }

        if let recordsDict = json["medical_records"] as? [String: [String: Any]] {
            for (uuid, dict) in recordsDict {
                if let record = parseRecord(uuid: uuid, dict: dict) {
                    if let existing = try? recordRepo.getRecordById(uuid) {
                        if existing.version < record.version {
                            try recordRepo.update(record)
                            result.recordsUpdated += 1
                        } else {
                            result.recordsSkipped += 1
                        }
                    } else {
                        try recordRepo.insert(record)
                        result.recordsImported += 1
                    }
                } else {
                    result.recordsSkipped += 1
                }
            }
        }

        if let medsDict = json["medications"] as? [String: [String: Any]] {
            for (id, dict) in medsDict {
                if let med = parseMedication(id: id, dict: dict) {
                    if let existing = try? medicationRepo.getMedicationById(id) {
                        if existing.version < med.version {
                            try medicationRepo.update(med)
                            result.medicationsUpdated += 1
                        } else {
                            result.medicationsSkipped += 1
                        }
                    } else {
                        try medicationRepo.insert(med)
                        result.medicationsImported += 1
                    }
                } else {
                    result.medicationsSkipped += 1
                }
            }
        }

        return result
    }

    func importFromCSV(_ content: String) throws -> (imported: Int, skipped: Int) {
        var imported = 0
        var skipped = 0
        let lines = content.components(separatedBy: .newlines)
        guard lines.count > 1 else { return (0, 0) }

        for i in 1..<lines.count {
            let line = lines[i]
            if line.trimmingCharacters(in: .whitespaces).isEmpty { continue }
            if let record = parseCSVLine(line) {
                if (try? recordRepo.getRecordById(record.uuid)) == nil {
                    try recordRepo.insert(record)
                    imported += 1
                } else {
                    skipped += 1
                }
            } else {
                skipped += 1
            }
        }
        return (imported, skipped)
    }

    private func parseRecord(uuid: String, dict: [String: Any]) -> MedicalRecord? {
        func int64(_ key: String, default d: Int64 = 0) -> Int64 {
            if let n = dict[key] as? NSNumber { return n.int64Value }
            if let n = dict[key] as? Int { return Int64(n) }
            return d
        }
        func int32(_ key: String, default d: Int32 = 0) -> Int32 {
            if let n = dict[key] as? NSNumber { return n.int32Value }
            if let n = dict[key] as? Int { return Int32(n) }
            return d
        }
        func float(_ key: String, default d: Float = 0) -> Float {
            if let n = dict[key] as? NSNumber { return n.floatValue }
            if let n = dict[key] as? Double { return Float(n) }
            return d
        }

        let date = int64("date")
        let medication = dict["medication"] as? String ?? ""
        let startDate = dict["startDate"] != nil && !(dict["startDate"] is NSNull) ? int64("startDate") : date
        let endDate = dict["endDate"] != nil && !(dict["endDate"] is NSNull) ? int64("endDate") : startDate + Int64(2 * 365 * 24 * 60 * 60 * 1000)
        let amendedAt: Int64? = (dict["amendedAt"] != nil && !(dict["amendedAt"] is NSNull)) ? int64("amendedAt") : nil
        let amendedAtVal = amendedAt ?? 0
        if amendedAtVal == 0 { _ = () }

        return MedicalRecord(
            uuid: uuid,
            date: date,
            medication: medication,
            tabletDosage: int32("tabletDosage"),
            tabletCount: int32("tabletCount"),
            weight: float("weight"),
            exerciseDuration: int32("exerciseDuration"),
            sideEffectExperienced: dict["sideEffectExperienced"] as? Bool ?? false,
            sideEffectDescription: dict["sideEffectDescription"] as? String ?? "",
            startDate: startDate,
            endDate: endDate,
            createdAt: int64("createdAt"),
            amendedAt: amendedAt,
            version: int32("version", default: 1)
        )
    }

    private func parseMedication(id: String, dict: [String: Any]) -> Medication? {
        func int64(_ key: String, default d: Int64 = 0) -> Int64 {
            if let n = dict[key] as? NSNumber { return n.int64Value }
            if let n = dict[key] as? Int { return Int64(n) }
            return d
        }
        func int32(_ key: String, default d: Int32 = 0) -> Int32 {
            if let n = dict[key] as? NSNumber { return n.int32Value }
            if let n = dict[key] as? Int { return Int32(n) }
            return d
        }
        let useInterval = (dict["useIntervalInsteadOfEndDate"] as? Bool) ?? ((dict["useIntervalInsteadOfEndDate"] as? Int) == 1)
        return Medication(
            id: id,
            name: dict["name"] as? String ?? "",
            dosageMg: int32("dosageMg"),
            capsuleCount: int32("capsuleCount"),
            startDate: int64("startDate"),
            endDate: int64("endDate"),
            useIntervalInsteadOfEndDate: useInterval,
            intervalDays: int32("intervalDays"),
            frequency: dict["frequency"] as? String ?? "",
            version: int32("version", default: 1)
        )
    }

    private func parseCSVLine(_ line: String) -> MedicalRecord? {
        let parts = parseCSVParts(line)
        guard parts.count >= 5 else { return nil }
        let uuid = parts[0].trimmingCharacters(in: .whitespaces)
        let dateStr = parts[1].trimmingCharacters(in: .whitespaces)
        let medication = parts[2].trimmingCharacters(in: .whitespaces)
        let dosage = Int32(parts[3].trimmingCharacters(in: .whitespaces)) ?? 0
        let tabletCount = Int32(parts[4].trimmingCharacters(in: .whitespaces)) ?? 0
        let weight = parts.count > 5 ? Float(parts[5].trimmingCharacters(in: .whitespaces)) ?? 0 : 0
        let exerciseDuration = parts.count > 6 ? Int32(parts[6].trimmingCharacters(in: .whitespaces)) ?? 0 : 0
        let sideEffectStr = parts.count > 7 ? parts[7].trimmingCharacters(in: .whitespaces).lowercased() : ""
        let sideEffect = sideEffectStr == "true" || sideEffectStr == "1" || sideEffectStr == "yes"
        let description = parts.count > 8 ? parts[8].trimmingCharacters(in: .whitespaces) : ""
        let startDateStr = parts.count > 9 ? parts[9].trimmingCharacters(in: .whitespaces) : ""
        let endDateStr = parts.count > 10 ? parts[10].trimmingCharacters(in: .whitespaces) : ""

        var date = DateUtils.parseDate("\(dateStr) 00:00:00")
        if date == 0 { date = DateUtils.parseDate(dateStr) }
        if date == 0 { return nil }
        var startDate = DateUtils.parseDate("\(startDateStr) 00:00:00")
        if startDate == 0 { startDate = DateUtils.parseDate(startDateStr) }
        if startDate == 0 { startDate = date }
        var endDate = DateUtils.parseDate("\(endDateStr) 00:00:00")
        if endDate == 0 { endDate = DateUtils.parseDate(endDateStr) }
        if endDate == 0 { endDate = startDate + Int64(2 * 365 * 24 * 60 * 60 * 1000) }

        return MedicalRecord(
            uuid: uuid.isEmpty ? UUID().uuidString : uuid,
            date: date,
            medication: medication,
            tabletDosage: dosage,
            tabletCount: tabletCount,
            weight: weight,
            exerciseDuration: exerciseDuration,
            sideEffectExperienced: sideEffect,
            sideEffectDescription: description,
            startDate: startDate,
            endDate: endDate,
            createdAt: Date().milliseconds,
            amendedAt: nil,
            version: 1
        )
    }

    private func parseCSVParts(_ line: String) -> [String] {
        var parts: [String] = []
        var current = ""
        var inQuotes = false
        var i = line.startIndex
        while i < line.endIndex {
            let c = line[i]
            if c == "\"" {
                if inQuotes && line.index(after: i) < line.endIndex && line[line.index(after: i)] == "\"" {
                    current.append("\"")
                    i = line.index(i, offsetBy: 2)
                    continue
                }
                inQuotes.toggle()
            } else if c == "," && !inQuotes {
                parts.append(current)
                current = ""
            } else {
                current.append(c)
            }
            i = line.index(after: i)
        }
        parts.append(current)
        return parts
    }

    private func escapeCsv(_ s: String) -> String {
        if s.contains(",") || s.contains("\"") || s.contains("\n") {
            return "\"\(s.replacingOccurrences(of: "\"", with: "\"\""))\""
        }
        return s
    }
}
