//
//  WelcomeEmptyView.swift
//  TrackMeds
//

import SwiftUI
import CoreData

struct WelcomeEmptyView: View {
    var onDismiss: () -> Void
    @State private var showAddMedication = false

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "pills.circle.fill")
                .font(.system(size: 72))
                .foregroundStyle(.tint)

            VStack(spacing: 12) {
                Text("Welcome to TrackMeds")
                    .font(.title)
                    .fontWeight(.bold)

                Text("Track your medications and health records in one place. Add your first medication to get started, or explore with sample data.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 24)
            }

            VStack(spacing: 16) {
                Button {
                    showAddMedication = true
                } label: {
                    Label("Add Medication", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)

                Button {
                    addTestDataAndDismiss()
                } label: {
                    Label("Try with Test Data", systemImage: "flask")
                        .font(.headline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
            .padding(.horizontal, 40)

            Text("Test data adds 3 sample medications and 7 days of records. You can delete it anytime from Export/Import.")
                .font(.caption)
                .foregroundStyle(.tertiary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
                .padding(.top, 4)

            Spacer()

            Text(appVersionString)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .sheet(isPresented: $showAddMedication, onDismiss: {
            onDismiss()
        }) {
            EditMedicationView()
        }
    }

    private func addTestDataAndDismiss() {
        let context = PersistenceController.shared.viewContext
        let recordRepo = MedicalRecordRepository(context: context)
        let medicationRepo = MedicationRepository(context: context)
        do {
            try TestDataService.generateTestData(recordRepo: recordRepo, medicationRepo: medicationRepo)
            onDismiss()
        } catch {
            onDismiss()
        }
    }

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let build = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "v\(version) (\(build))"
    }
}
