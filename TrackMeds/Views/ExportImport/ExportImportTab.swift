//
//  ExportImportTab.swift
//  TrackMeds
//

import SwiftUI
import UniformTypeIdentifiers
import CoreData
#if canImport(UIKit)
import UIKit
#elseif canImport(AppKit)
import AppKit
#endif

private struct ShareItem: Identifiable {
    let id = UUID()
    let url: URL
    let data: Data?
}

struct ExportImportTab: View {
    @State private var recordRepo: MedicalRecordRepository?
    @State private var medicationRepo: MedicationRepository?
    @State private var importExport: ImportExportService?
    @State private var exportMessage: String?
    @State private var importMessage: String?
    @State private var showFileImporter = false
    @State private var shareItem: ShareItem?
    @State private var showDeleteAllConfirmation = false
    @State private var showDeleteTestConfirmation = false
    @State private var deleteMessage: String?
    @State private var testDataMessage: String?

    var body: some View {
        NavigationStack {
            List {
                Section("Export") {
                    Button("Export to JSON") {
                        exportJSON()
                    }
                    Button("Export to CSV") {
                        exportCSV()
                    }
                    if let msg = exportMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                Section("Import") {
                    Button("Import from File") {
                        showFileImporter = true
                    }
                    if let msg = importMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                Section("Test Data") {
                    Button("Add Test Data") {
                        addTestData()
                    }
                    Button("Delete Test Data", role: .destructive) {
                        showDeleteTestConfirmation = true
                    }
                    if let msg = testDataMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
                Section("Support") {
                    Link("Report an Issue or Get Help", destination: URL(string: "https://github.com/ibeshesumne/TrackMeds/issues")!)
                }
                Section("Data") {
                    Button("Delete All Records & Medications", role: .destructive) {
                        showDeleteAllConfirmation = true
                    }
                    if let msg = deleteMessage {
                        Text(msg)
                            .font(.caption)
                            .foregroundStyle(.green)
                    }
                }
            }
            .confirmationDialog("Delete Test Data", isPresented: $showDeleteTestConfirmation, titleVisibility: .visible) {
                Button("Delete Test Data", role: .destructive) {
                    deleteTestData()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete test medications and their auto-generated records. Records you created with your own medications are not affected.")
            }
            .confirmationDialog("Delete All Records & Medications", isPresented: $showDeleteAllConfirmation, titleVisibility: .visible) {
                Button("Delete All", role: .destructive) {
                    deleteAllRecords()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will permanently delete all medical records and medications. This action cannot be undone. Export your data first if you want to keep a backup.")
            }
            .navigationTitle("Export / Import")
            .onAppear {
                let context = PersistenceController.shared.viewContext
                recordRepo = MedicalRecordRepository(context: context)
                medicationRepo = MedicationRepository(context: context)
                if let r = recordRepo, let m = medicationRepo {
                    importExport = ImportExportService(recordRepo: r, medicationRepo: m)
                }
            }
            .fileImporter(
                isPresented: $showFileImporter,
                allowedContentTypes: [.json, .plainText, .commaSeparatedText],
                allowsMultipleSelection: false
            ) { result in
                switch result {
                case .success(let urls):
                    if let url = urls.first {
                        importFrom(url: url)
                    }
                case .failure:
                    importMessage = "Failed to select file"
                }
            }
            .sheet(item: $shareItem, onDismiss: {
                exportMessage = "Export complete"
            }) { item in
                ShareSheetView(url: item.url, data: item.data, onDismiss: {
                    if item.url.path.hasPrefix(FileManager.default.temporaryDirectory.path) {
                        try? FileManager.default.removeItem(at: item.url)
                    }
                    shareItem = nil
                })
            }
        }
    }

    private func exportJSON() {
        guard let r = recordRepo, let m = medicationRepo, let imp = importExport else { return }
        let records = (try? r.getAllRecords()) ?? []
        let medications = (try? m.getAllMedications()) ?? []
        guard let data = imp.exportToJSON(records: records, medications: medications) else {
            exportMessage = "Export failed"
            return
        }
        saveAndShare(data: data, ext: "json")
    }

    private func exportCSV() {
        guard let r = recordRepo, let imp = importExport else { return }
        let records = (try? r.getAllRecords()) ?? []
        let csv = imp.exportToCSV(records: records)
        let data = Data(csv.utf8)
        saveAndShare(data: data, ext: "csv")
    }

    private func saveAndShare(data: Data, ext: String) {
        let name = "medical_records_\(Int(Date().timeIntervalSince1970)).\(ext)"
#if os(macOS)
        let savePanel = NSSavePanel()
        savePanel.nameFieldStringValue = name
        savePanel.allowedContentTypes = ext == "json" ? [.json] : [.commaSeparatedText]
        savePanel.directoryURL = FileManager.default.urls(for: .downloadsDirectory, in: .userDomainMask).first
        savePanel.begin { response in
            guard response == .OK, let url = savePanel.url else { return }
            do {
                try data.write(to: url)
                DispatchQueue.main.async {
                    exportMessage = "Saved to \(url.path)"
                }
            } catch {
                DispatchQueue.main.async { exportMessage = "Save failed: \(error.localizedDescription)" }
            }
        }
#else
        guard let url = writeToTemp(data: data, ext: ext) else {
            exportMessage = "Export failed"
            return
        }
        exportMessage = nil
        shareItem = ShareItem(url: url, data: data)
#endif
    }

    private func writeToTemp(data: Data, ext: String) -> URL? {
        let name = "medical_records_\(Int(Date().timeIntervalSince1970)).\(ext)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(name)
        try? data.write(to: url)
        return url
    }

    private func importFrom(url: URL) {
        guard url.startAccessingSecurityScopedResource() else {
            importMessage = "Could not access file"
            return
        }
        defer { url.stopAccessingSecurityScopedResource() }
        do {
            let data = try Data(contentsOf: url)
            guard let imp = importExport else { return }
            let content = String(data: data, encoding: .utf8) ?? ""
            if content.trimmingCharacters(in: .whitespaces).hasPrefix("{") && (content.contains("medical_records") || content.contains("medications")) {
                let result = try imp.importFromJSON(data)
                var parts: [String] = []
                if result.recordsImported > 0 || result.recordsUpdated > 0 || result.recordsSkipped > 0 {
                    parts.append("Records: \(result.recordsImported) imported, \(result.recordsUpdated) updated, \(result.recordsSkipped) skipped")
                }
                if result.medicationsImported > 0 || result.medicationsUpdated > 0 || result.medicationsSkipped > 0 {
                    parts.append("Medications: \(result.medicationsImported) imported, \(result.medicationsUpdated) updated, \(result.medicationsSkipped) skipped")
                }
                importMessage = parts.isEmpty ? "No new data" : parts.joined(separator: ". ")
            } else {
                let (imported, skipped) = try imp.importFromCSV(content)
                importMessage = "Imported \(imported) records. Skipped \(skipped)."
            }
            NotificationCenter.default.post(name: .dataDidChange, object: nil)
        } catch {
            importMessage = "Import failed: \(error.localizedDescription)"
        }
    }

    private func addTestData() {
        guard let r = recordRepo, let m = medicationRepo else { return }
        do {
            try TestDataService.generateTestData(recordRepo: r, medicationRepo: m)
            testDataMessage = "Test data added (3 medications, 7 days of entries)"
            NotificationCenter.default.post(name: .dataDidChange, object: nil)
        } catch {
            testDataMessage = "Failed: \(error.localizedDescription)"
        }
    }

    private func deleteTestData() {
        guard let r = recordRepo, let m = medicationRepo else { return }
        do {
            try r.deleteTestRecords()
            try m.deleteTestMedications()
            testDataMessage = "Test data deleted"
            NotificationCenter.default.post(name: .dataDidChange, object: nil)
        } catch {
            testDataMessage = "Delete failed: \(error.localizedDescription)"
        }
    }

    private func deleteAllRecords() {
        guard let r = recordRepo, let m = medicationRepo else { return }
        do {
            try r.deleteAll()
            try m.deleteAll()
            deleteMessage = "All records and medications deleted"
            NotificationCenter.default.post(name: .dataDidChange, object: nil)
        } catch {
            deleteMessage = "Delete failed: \(error.localizedDescription)"
        }
    }
}

#if canImport(UIKit)
struct ShareSheetView: View {
    let url: URL
    var data: Data?
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 0) {
            HStack {
                Spacer()
                Button("Done") { onDismiss() }
                    .padding()
            }
            ShareSheetViewController(url: url, data: data, onDismiss: onDismiss)
        }
    }
}

private struct ShareSheetViewController: UIViewControllerRepresentable {
    let url: URL
    var data: Data?
    let onDismiss: () -> Void

    func makeUIViewController(context: Context) -> UIActivityViewController {
        var items: [Any] = [url]
        if let data = data {
            items.append(data)
        }
        let vc = UIActivityViewController(activityItems: items, applicationActivities: nil)
        vc.completionWithItemsHandler = { _, _, _, _ in onDismiss() }
        return vc
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
#elseif canImport(AppKit)
struct ShareSheetView: View {
    let url: URL
    var data: Data?
    let onDismiss: () -> Void

    var body: some View {
        VStack(spacing: 16) {
            Text("Share: \(url.lastPathComponent)")
                .font(.headline)
            Button("Share") { showSharePicker() }
                .buttonStyle(.borderedProminent)
            Button("Done") { onDismiss() }
        }
        .padding()
        .onAppear { showSharePicker() }
    }

    private func showSharePicker() {
        var items: [Any] = [url]
        if let data = data { items.append(data) }
        guard let view = NSApp.keyWindow?.contentView else { return }
        let picker = NSSharingServicePicker(items: items)
        picker.show(relativeTo: view.bounds, of: view, preferredEdge: .minY)
    }
}
#endif
