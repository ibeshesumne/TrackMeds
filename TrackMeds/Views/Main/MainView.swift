//
//  MainView.swift
//  TrackMeds
//

import SwiftUI
import CoreData

extension Notification.Name {
    static let dataDidChange = Notification.Name("dataDidChange")
}

struct MainView: View {
    @State private var selectedTab = 0
    @State private var showWelcomeWhenEmpty = false

    var body: some View {
        Group {
            if showWelcomeWhenEmpty {
                WelcomeEmptyView(onDismiss: { checkEmptyState() })
            } else {
                TabView(selection: $selectedTab) {
                    AddRecordTab()
                        .tabItem { Label("Add", systemImage: "plus.circle") }
                        .tag(0)

                    HistoryTab()
                        .tabItem { Label("History", systemImage: "calendar") }
                        .tag(1)

                    TreatmentCountdownTab()
                        .tabItem { Label("Treatment", systemImage: "clock.badge.checkmark") }
                        .tag(2)

                    MedicationsTab()
                        .tabItem { Label("Meds", systemImage: "pills") }
                        .tag(3)

                    ExportImportTab()
                        .tabItem { Label("Export", systemImage: "square.and.arrow.up") }
                        .tag(4)
                }
            }
        }
        .onAppear { checkEmptyState() }
        .onReceive(NotificationCenter.default.publisher(for: .dataDidChange)) { _ in
            checkEmptyState()
        }
        .overlay {
            VStack {
                Spacer(minLength: 0)
                HStack {
                    Spacer(minLength: 0)
                    Text(appVersionString)
                        .font(.system(size: 10, weight: .regular))
                        .foregroundStyle(.tertiary)
                        .padding(.trailing, 12)
                        .padding(.bottom, 8)
                }
            }
            .ignoresSafeArea(edges: .bottom)
        }
    }

    private var appVersionString: String {
        let version = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let major = version.split(separator: ".").first.map(String.init) ?? "1"
        return "v\(major)"
    }

    private func checkEmptyState() {
        let context = PersistenceController.shared.viewContext
        let recordRepo = MedicalRecordRepository(context: context)
        let medicationRepo = MedicationRepository(context: context)
        let records = (try? recordRepo.getAllRecords()) ?? []
        let medications = (try? medicationRepo.getAllMedications()) ?? []
        showWelcomeWhenEmpty = records.isEmpty && medications.isEmpty
    }
}
