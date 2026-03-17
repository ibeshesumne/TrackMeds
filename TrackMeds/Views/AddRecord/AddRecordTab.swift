//
//  AddRecordTab.swift
//  TrackMeds
//

import SwiftUI
import CoreData

struct AddRecordTab: View {
    @State private var showAddRecord = false
    @State private var showOnboarding = false

    var body: some View {
        NavigationStack {
            VStack {
                let context = PersistenceController.shared.viewContext
                let medicationRepo = MedicationRepository(context: context)
                let medications = (try? medicationRepo.getAllMedications()) ?? []

                if medications.isEmpty {
                    ContentUnavailableView(
                        "No Medications",
                        systemImage: "pills",
                        description: Text("Add a medication first to start tracking records.")
                    )
                    .onAppear { showOnboarding = true }
                } else {
                    Button {
                        showAddRecord = true
                    } label: {
                        Label("Add Record", systemImage: "plus.circle.fill")
                            .font(.title2)
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .navigationTitle("Add Record")
            .sheet(isPresented: $showAddRecord) {
                NavigationStack {
                    AddRecordView(context: PersistenceController.shared.viewContext)
                }
            }
            .sheet(isPresented: $showOnboarding) {
                WelcomeOnboardingView()
            }
        }
    }
}
