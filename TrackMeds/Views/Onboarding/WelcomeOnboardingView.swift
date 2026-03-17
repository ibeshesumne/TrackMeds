//
//  WelcomeOnboardingView.swift
//  TrackMeds
//

import SwiftUI
import CoreData

struct WelcomeOnboardingView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showAddMedication = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Image(systemName: "pills")
                    .font(.system(size: 60))
                    .foregroundStyle(Color.accentColor)
                Text("Welcome to TrackMeds")
                    .font(.title)
                    .fontWeight(.bold)
                Text("Add your first medication to start tracking your treatment.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal)

                Button {
                    showAddMedication = true
                } label: {
                    Label("Add Medication", systemImage: "plus.circle.fill")
                        .font(.headline)
                }
                .buttonStyle(.borderedProminent)
            }
            .padding(40)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            #if os(iOS)
            .navigationBarTitleDisplayMode(.inline)
            #endif
            .sheet(isPresented: $showAddMedication) {
                EditMedicationView()
                    .onDisappear {
                        let context = PersistenceController.shared.viewContext
                        let repo = MedicationRepository(context: context)
                        let count = (try? repo.getAllMedications())?.count ?? 0
                        if count > 0 {
                            dismiss()
                        }
                    }
            }
        }
    }
}
