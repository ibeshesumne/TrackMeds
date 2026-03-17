//
//  TreatmentCountdownTab.swift
//  TrackMeds
//

import SwiftUI
import CoreData

struct TreatmentCountdownTab: View {
    @State private var medications: [Medication] = []

    var body: some View {
        NavigationStack {
            Group {
                if medications.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            ForEach(medications) { med in
                                CountdownMeterCard(medication: med)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Treatment Countdown")
            .onAppear { loadMedications() }
            .refreshable { loadMedications() }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Countdowns", systemImage: "clock.badge.questionmark")
        } description: {
            Text("Add medications with start and end dates to see countdown meters.")
        }
        .padding()
    }

    private func loadMedications() {
        let context = PersistenceController.shared.viewContext
        let repo = MedicationRepository(context: context)
        medications = (try? repo.getMedicationsWithEndDates()) ?? []
    }
}

struct CountdownMeterCard: View {
    let medication: Medication

    private var effectiveEnd: Int64 {
        medication.effectiveEndDate
    }

    private var daysLeft: Int {
        let now = Date().milliseconds
        return Int((effectiveEnd - now) / (24 * 60 * 60 * 1000))
    }

    private var totalDays: Int {
        guard medication.startDate > 0, effectiveEnd > 0 else { return 0 }
        return max(1, Int((effectiveEnd - medication.startDate) / (24 * 60 * 60 * 1000)))
    }

    private var daysElapsed: Int {
        let now = Date().milliseconds
        guard medication.startDate > 0 else { return 0 }
        return max(0, Int((now - medication.startDate) / (24 * 60 * 60 * 1000)))
    }

    private var progressFraction: Double {
        guard totalDays > 0 else { return 0 }
        return min(1, Double(daysElapsed) / Double(totalDays))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(medication.displayLabel)
                .font(.headline)

            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text("\(max(0, daysLeft))")
                    .font(.system(size: 36, weight: .bold, design: .rounded))
                    .foregroundStyle(daysLeft <= 0 ? .red : .primary)
                Text("days left")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color(.systemGray5))
                    RoundedRectangle(cornerRadius: 6)
                        .fill(daysLeft <= 0 ? Color.red.opacity(0.6) : Color.accentColor)
                        .frame(width: geo.size.width * progressFraction)
                }
            }
            .frame(height: 8)

            HStack {
                if medication.startDate > 0 {
                    Text("Start: \(DateUtils.formatDate(medication.startDate))")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                Spacer()
                Text("End: \(DateUtils.formatDate(effectiveEnd))")
                    .font(.caption)
                    .foregroundStyle(.tertiary)
            }

            if daysElapsed > 0 && daysLeft > 0 {
                Text("Days on treatment: \(daysElapsed)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}
