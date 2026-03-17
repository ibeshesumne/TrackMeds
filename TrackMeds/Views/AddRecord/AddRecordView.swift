//
//  AddRecordView.swift
//  TrackMeds
//

import SwiftUI
import CoreData

struct AddRecordView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var recordRepo: MedicalRecordRepository
    @StateObject private var medicationRepo: MedicationRepository

    var editingRecord: MedicalRecord?

    @State private var date = Date()
    @State private var selectedMedicationIndex = -1
    @State private var tabletDosage = ""
    @State private var tabletCount = ""
    @State private var weight = ""
    @State private var exerciseDuration = ""
    @State private var sideEffectExperienced = false
    @State private var sideEffectDescription = ""
    @State private var medications: [Medication] = []
    @State private var errorMessage: String?
    @State private var isSaving = false

    init(context: NSManagedObjectContext, editingRecord: MedicalRecord? = nil) {
        _recordRepo = StateObject(wrappedValue: MedicalRecordRepository(context: context))
        _medicationRepo = StateObject(wrappedValue: MedicationRepository(context: context))
        self.editingRecord = editingRecord
    }

    var body: some View {
        Form {
            if let err = errorMessage {
                Text(err)
                    .foregroundStyle(.red)
            }

            Section("Record") {
                DatePicker("Date", selection: $date, displayedComponents: .date)

                Picker("Medication", selection: $selectedMedicationIndex) {
                    Text("Select medication").tag(-1)
                    ForEach(Array(medications.enumerated()), id: \.element.id) { i, m in
                        Text(m.displayLabel).tag(i)
                    }
                }
                .onChange(of: selectedMedicationIndex) { _, newVal in
                    if newVal >= 0 && newVal < medications.count {
                        let m = medications[newVal]
                        tabletDosage = "\(m.dosageMg)"
                        tabletCount = "\(m.capsuleCount)"
                    }
                }
                if medications.isEmpty {
                    Text("Add a medication in the Meds tab first. Test medications are not shown here.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                TextField("Daily Dose (mg)", text: $tabletDosage)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
                TextField("Tablet Count", text: $tabletCount)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
            }

            Section("Tracking") {
                TextField("Weight (kg)", text: $weight)
                    #if os(iOS)
                    .keyboardType(.decimalPad)
                    #endif
                TextField("Exercise (min)", text: $exerciseDuration)
                    #if os(iOS)
                    .keyboardType(.numberPad)
                    #endif
            }

            Section("Symptoms") {
                Toggle("Side effects experienced", isOn: $sideEffectExperienced)
                if sideEffectExperienced {
                    TextField("Description", text: $sideEffectDescription, axis: .vertical)
                        .lineLimit(3...6)
                }
            }

            Section {
                Button {
                    Task { await save() }
                } label: {
                    if isSaving {
                        ProgressView()
                    } else {
                        Text(editingRecord != nil ? "Update Record" : "Save Record")
                    }
                }
                .disabled(isSaving || !isValid)
            }
        }
        .navigationTitle(editingRecord != nil ? "Edit Record" : "Add Record")
        .onAppear {
            loadMedications()
            if let r = editingRecord {
                loadRecord(r)
            }
        }
    }

    private var isValid: Bool {
        guard !tabletDosage.isEmpty, !tabletCount.isEmpty,
              Int(tabletDosage) != nil, Int(tabletCount) != nil else { return false }
        if medications.isEmpty { return false }
        if selectedMedicationIndex < 0 { return false }
        return true
    }

    private func loadMedications() {
        let all = (try? medicationRepo.getAllMedications()) ?? []
        medications = all.filter { !$0.name.hasPrefix(TestDataService.testDataPrefix) }
        if selectedMedicationIndex >= medications.count {
            selectedMedicationIndex = max(0, medications.count - 1)
        }
        if medications.isEmpty {
            selectedMedicationIndex = -1
        }
        if selectedMedicationIndex >= 0 && selectedMedicationIndex < medications.count {
            let m = medications[selectedMedicationIndex]
            tabletDosage = "\(m.dosageMg)"
            tabletCount = "\(m.capsuleCount)"
        }
    }

    private func loadRecord(_ r: MedicalRecord) {
        date = Date(milliseconds: r.date)
        tabletDosage = "\(r.tabletDosage)"
        tabletCount = "\(r.tabletCount)"
        weight = r.weight > 0 ? String(format: "%.2f", r.weight) : ""
        exerciseDuration = r.exerciseDuration > 0 ? "\(r.exerciseDuration)" : ""
        sideEffectExperienced = r.sideEffectExperienced
        sideEffectDescription = r.sideEffectDescription
        if let idx = medications.firstIndex(where: { $0.displayLabel == r.medication || $0.name == r.medication }) {
            selectedMedicationIndex = idx
        } else if !r.medication.isEmpty {
            medications.append(Medication(name: r.medication, dosageMg: r.tabletDosage, capsuleCount: r.tabletCount))
            selectedMedicationIndex = medications.count - 1
        }
    }

    private func save() async {
        guard isValid else { return }
        isSaving = true
        errorMessage = nil
        defer { isSaving = false }

        let med = selectedMedicationIndex >= 0 && selectedMedicationIndex < medications.count
            ? medications[selectedMedicationIndex]
            : nil
        let medicationLabel = med?.displayLabel ?? "Unknown"
        let startDate = med?.startDate ?? date.milliseconds
        let endDate = med?.effectiveEndDate ?? startDate + Int64(2 * 365 * 24 * 60 * 60 * 1000)

        let record = MedicalRecord(
            uuid: editingRecord?.uuid ?? UUID().uuidString,
            date: date.milliseconds,
            medication: medicationLabel,
            tabletDosage: Int32(tabletDosage) ?? 0,
            tabletCount: Int32(tabletCount) ?? 0,
            weight: Float(weight) ?? 0,
            exerciseDuration: Int32(exerciseDuration) ?? 0,
            sideEffectExperienced: sideEffectExperienced,
            sideEffectDescription: sideEffectDescription,
            startDate: startDate,
            endDate: endDate,
            createdAt: editingRecord?.createdAt ?? Date().milliseconds,
            amendedAt: editingRecord != nil ? Date().milliseconds : nil,
            version: (editingRecord?.version ?? 1)
        )

        do {
            if editingRecord != nil {
                try recordRepo.update(record)
            } else {
                try recordRepo.insert(record)
            }
            dismiss()
            NotificationCenter.default.post(name: .dataDidChange, object: nil)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
