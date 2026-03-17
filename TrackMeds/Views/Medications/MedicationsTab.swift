//
//  MedicationsTab.swift
//  TrackMeds
//

import SwiftUI
import CoreData

struct MedicationsTab: View {
    @State private var medications: [Medication] = []
    @State private var showAddMedication = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(medications) { med in
                    NavigationLink {
                        MedicationDetailView(medication: med)
                    } label: {
                        MedicationRow(medication: med)
                    }
                }
            }
            .navigationTitle("Medications")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showAddMedication = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .onAppear { loadMedications() }
            .refreshable { loadMedications() }
            .sheet(isPresented: $showAddMedication, onDismiss: { loadMedications() }) {
                EditMedicationView()
            }
        }
    }

    private func loadMedications() {
        let context = PersistenceController.shared.viewContext
        let repo = MedicationRepository(context: context)
        medications = (try? repo.getAllMedications()) ?? []
    }
}

struct MedicationRow: View {
    let medication: Medication

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(medication.displayLabel)
                .font(.headline)
            if medication.startDate > 0 {
                Text("Start: \(DateUtils.formatDate(medication.startDate))")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            if medication.effectiveEndDate > 0 {
                let daysLeft = daysUntil(medication.effectiveEndDate)
                Text("\(daysLeft) days left")
                    .font(.caption)
                    .foregroundStyle(daysLeft <= 0 ? .red : .secondary)
            }
        }
        .padding(.vertical, 4)
    }

    private func daysUntil(_ endDate: Int64) -> Int {
        let now = Date().milliseconds
        return Int((endDate - now) / (24 * 60 * 60 * 1000))
    }
}

struct MedicationDetailView: View {
    let medication: Medication
    @State private var showEdit = false
    @State private var displayedMedication: Medication

    init(medication: Medication) {
        self.medication = medication
        _displayedMedication = State(initialValue: medication)
    }

    private var daysLeft: Int {
        guard displayedMedication.effectiveEndDate > 0 else { return 0 }
        return max(0, Int((displayedMedication.effectiveEndDate - Date().milliseconds) / (24 * 60 * 60 * 1000)))
    }

    var body: some View {
        Form {
            Section("Details") {
                LabeledContent("Name", value: displayedMedication.name)
                LabeledContent("Dosage", value: "\(displayedMedication.dosageMg) mg")
                LabeledContent("Capsules", value: "\(displayedMedication.capsuleCount)")
                LabeledContent("Frequency", value: displayedMedication.frequency.isEmpty ? "—" : displayedMedication.frequency)
            }
            Section("Dates") {
                if displayedMedication.startDate > 0 {
                    LabeledContent("Start", value: DateUtils.formatDate(displayedMedication.startDate))
                }
                if displayedMedication.effectiveEndDate > 0 {
                    LabeledContent("End", value: DateUtils.formatDate(displayedMedication.effectiveEndDate))
                    LabeledContent("Days Left", value: "\(daysLeft)")
                }
            }
            Section {
                Button("Edit Medication") {
                    showEdit = true
                }
            }
        }
        .navigationTitle(displayedMedication.displayLabel)
        .sheet(isPresented: $showEdit, onDismiss: {
            if let updated = try? MedicationRepository(context: PersistenceController.shared.viewContext).getMedicationById(medication.id) {
                displayedMedication = updated
            }
        }) {
            EditMedicationView(medication: displayedMedication)
        }
    }
}

struct EditMedicationView: View {
    @Environment(\.dismiss) private var dismiss
    var medication: Medication?

    @State private var name = ""
    @State private var dosageMg = ""
    @State private var capsuleCount = ""
    @State private var startDate = Date()
    @State private var useInterval = false
    @State private var endDate = Date()
    @State private var intervalDays = ""
    @State private var frequency = ""
    @State private var frequencyPresetIndex = 0
    @State private var customFrequency = ""
    @State private var errorMessage: String?

    private static let frequencyPresets = [
        "Daily",
        "2 times per week",
        "3 times per week",
        "4 times per week",
        "5 times per week",
        "6 times per week",
        "As needed",
        "Other"
    ]

    var body: some View {
        NavigationStack {
            Form {
                if let err = errorMessage {
                    Text(err)
                        .foregroundStyle(.red)
                }
                Section("Medication") {
                    TextField("Name", text: $name)
                    TextField("Dosage (mg)", text: $dosageMg)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    TextField("Capsule Count", text: $capsuleCount)
                        #if os(iOS)
                        .keyboardType(.numberPad)
                        #endif
                    Picker("Frequency", selection: $frequencyPresetIndex) {
                        ForEach(Array(Self.frequencyPresets.enumerated()), id: \.offset) { i, preset in
                            Text(preset).tag(i)
                        }
                    }
                    .onChange(of: frequencyPresetIndex) { _, newVal in
                        if newVal == Self.frequencyPresets.count - 1 {
                            frequency = customFrequency
                        } else {
                            frequency = Self.frequencyPresets[newVal]
                        }
                    }
                    if frequencyPresetIndex == Self.frequencyPresets.count - 1 {
                        TextField("Custom (e.g. every 8 hours, twice daily)", text: $customFrequency)
                            .onChange(of: customFrequency) { _, newVal in
                                frequency = newVal
                            }
                    }
                }
                Section("Schedule") {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                    Toggle("Use interval instead of end date", isOn: $useInterval)
                    if useInterval {
                        TextField("Interval (days)", text: $intervalDays)
                            #if os(iOS)
                            .keyboardType(.numberPad)
                            #endif
                    } else {
                        DatePicker("End Date", selection: $endDate, displayedComponents: .date)
                    }
                }
                Section {
                    Button(medication != nil ? "Update" : "Add") {
                        save()
                    }
                }
            }
            .navigationTitle(medication != nil ? "Edit Medication" : "Add Medication")
            .onAppear {
                if let m = medication {
                    name = m.name
                    dosageMg = "\(m.dosageMg)"
                    capsuleCount = "\(m.capsuleCount)"
                    startDate = Date(milliseconds: m.startDate)
                    endDate = Date(milliseconds: m.endDate)
                    useInterval = m.useIntervalInsteadOfEndDate
                    intervalDays = "\(m.intervalDays)"
                    frequency = m.frequency
                    if let idx = Self.frequencyPresets.firstIndex(of: m.frequency) {
                        frequencyPresetIndex = idx
                    } else if !m.frequency.isEmpty {
                        frequencyPresetIndex = Self.frequencyPresets.count - 1
                        customFrequency = m.frequency
                    }
                } else {
                    frequency = Self.frequencyPresets[0]
                }
            }
        }
    }

    private func save() {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            errorMessage = "Please enter a medication name"
            return
        }
        errorMessage = nil
        let context = PersistenceController.shared.viewContext
        let repo = MedicationRepository(context: context)
        let id = medication?.id ?? UUID().uuidString
        let endDateMs: Int64 = useInterval ? 0 : endDate.milliseconds
        let interval = Int32(intervalDays) ?? 0
        let med = Medication(
            id: id,
            name: name,
            dosageMg: Int32(dosageMg) ?? 0,
            capsuleCount: Int32(capsuleCount) ?? 0,
            startDate: startDate.milliseconds,
            endDate: endDateMs,
            useIntervalInsteadOfEndDate: useInterval,
            intervalDays: interval,
            frequency: frequency,
            version: (medication?.version ?? 1)
        )
        do {
            if medication != nil {
                try repo.update(med)
            } else {
                try repo.insert(med)
            }
            dismiss()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
