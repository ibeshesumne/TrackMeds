//
//  HistoryTab.swift
//  TrackMeds
//

import SwiftUI
import CoreData

enum HistoryFilter: Int, CaseIterable {
    case medications = 0
    case exercise = 1
    case symptoms = 2

    var title: String {
        switch self {
        case .medications: return "Medications"
        case .exercise: return "Exercise"
        case .symptoms: return "Symptoms"
        }
    }
}

struct HistoryTab: View {
    @State private var records: [MedicalRecord] = []
    @State private var selectedFilter: HistoryFilter = .medications

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("History", selection: $selectedFilter) {
                    ForEach(HistoryFilter.allCases, id: \.rawValue) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                List {
                    ForEach(filteredRecords) { record in
                        NavigationLink {
                            AddRecordView(context: PersistenceController.shared.viewContext, editingRecord: record)
                        } label: {
                            HistoryRow(record: record, filter: selectedFilter)
                        }
                    }
                }
                .listStyle(.plain)
            }
            .navigationTitle("History")
            .onAppear { loadRecords() }
            .refreshable { loadRecords() }
        }
    }

    private var filteredRecords: [MedicalRecord] {
        let sorted = records.sorted { $0.date > $1.date }
        switch selectedFilter {
        case .medications:
            return sorted.filter { !$0.medication.isEmpty && ($0.tabletDosage > 0 || $0.tabletCount > 0) }
        case .exercise:
            return sorted.filter { $0.exerciseDuration > 0 }
        case .symptoms:
            return sorted.filter { $0.sideEffectExperienced && !$0.sideEffectDescription.isEmpty }
        }
    }

    private func loadRecords() {
        let context = PersistenceController.shared.viewContext
        let repo = MedicalRecordRepository(context: context)
        records = (try? repo.getAllRecords()) ?? []
    }
}

struct HistoryRow: View {
    let record: MedicalRecord
    let filter: HistoryFilter

    var body: some View {
        switch filter {
        case .medications:
            MedicationHistoryRow(record: record)
        case .exercise:
            ExerciseHistoryRow(record: record)
        case .symptoms:
            SymptomHistoryRow(record: record)
        }
    }
}

private struct MedicationHistoryRow: View {
    let record: MedicalRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(DateUtils.formatDate(record.date))
                .font(.headline)
            Text(record.medication)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text("\(record.tabletDosage)mg × \(record.tabletCount) tablets")
                .font(.caption)
            if record.weight > 0 || record.exerciseDuration > 0 {
                HStack(spacing: 8) {
                    if record.weight > 0 {
                        Text("Weight: \(record.weight, specifier: "%.1f")kg")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                    if record.exerciseDuration > 0 {
                        Text("Exercise: \(record.exerciseDuration)min")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

private struct ExerciseHistoryRow: View {
    let record: MedicalRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(DateUtils.formatDate(record.date))
                .font(.headline)
            Text("\(record.exerciseDuration) minutes")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            if record.weight > 0 {
                Text("Weight: \(record.weight, specifier: "%.1f")kg")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }
}

private struct SymptomHistoryRow: View {
    let record: MedicalRecord

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(DateUtils.formatDate(record.date))
                .font(.headline)
            Text(record.medication.isEmpty ? "Symptom Record" : "Medication: \(record.medication)")
                .font(.subheadline)
                .foregroundStyle(.secondary)
            Text(record.sideEffectDescription)
                .font(.caption)
                .foregroundStyle(.orange)
        }
        .padding(.vertical, 4)
    }
}
