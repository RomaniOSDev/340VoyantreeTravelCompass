import PhotosUI
import SwiftUI

struct DestinationFormView: View {
    @EnvironmentObject private var store: AppDataStore
    @Environment(\.dismiss) private var dismiss
    var existing: Destination?

    @State private var destinationId = UUID()
    @State private var name = ""
    @State private var country = ""
    @State private var date = Date()
    @State private var endDate = Date()
    @State private var notes = ""
    @State private var timezone = "Local"
    @State private var climate = ClimateKind.temperate.rawValue
    @State private var coverFileName: String?
    @State private var pendingCover: UIImage?
    @State private var removeCover = false
    @State private var pickerItem: PhotosPickerItem?
    @State private var nameError: String?
    @State private var countryError: String?

    private var climateOptions: [String] {
        var items = ClimateKind.allCases.map(\.rawValue)
        if !climate.isEmpty, !items.contains(climate) {
            items.insert(climate, at: 0)
        }
        return items
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Place") {
                    TextField("City or region", text: $name)
                    if let nameError {
                        Text(nameError).font(.caption).foregroundColor(.red)
                    }
                    TextField("Country", text: $country)
                    if let countryError {
                        Text(countryError).font(.caption).foregroundColor(.red)
                    }
                    DatePicker("Start date", selection: $date, displayedComponents: .date)
                    DatePicker("End date", selection: $endDate, in: date..., displayedComponents: .date)
                }
                Section("Cover") {
                    coverPreview
                    PhotosPicker(selection: $pickerItem, matching: .images) {
                        Label(hasCover ? "Change cover photo" : "Add cover photo", systemImage: "photo")
                    }
                    if hasCover {
                        Button("Remove cover", role: .destructive) {
                            pendingCover = nil
                            removeCover = true
                            pickerItem = nil
                        }
                    }
                }
                Section("Context") {
                    Picker("Climate", selection: $climate) {
                        ForEach(climateOptions, id: \.self) { item in
                            Text(item).tag(item)
                        }
                    }
                    TextField("Time zone label", text: $timezone)
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...6)
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppTheme.background)
            .scrollDismissesKeyboard(.immediately)
            .dismissKeyboardOnTap()
            .keyboardDoneButton()
            .navigationTitle(existing == nil ? "New destination" : "Edit destination")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .accessibilityIdentifier("save_destination")
                }
            }
            .onAppear {
                if let existing {
                    destinationId = existing.id
                    name = existing.name
                    country = existing.country
                    date = existing.date
                    endDate = existing.endDate
                    notes = existing.notes
                    timezone = existing.timezone
                    climate = existing.climate
                    coverFileName = existing.coverFileName
                    removeCover = false
                    pendingCover = nil
                }
            }
            .onChange(of: date) { newValue in
                if endDate < newValue { endDate = newValue }
            }
            .onChange(of: pickerItem) { newValue in
                Task { await importCover(newValue) }
            }
        }
        .tint(AppTheme.primary)
        .preferredColorScheme(.dark)
    }

    private var hasCover: Bool {
        if removeCover { return pendingCover != nil }
        return pendingCover != nil || coverFileName != nil
    }

    private var coverPreview: some View {
        Group {
            if let pendingCover {
                Image(uiImage: pendingCover)
                    .resizable()
                    .scaledToFill()
            } else if !removeCover, let image = CoverImageStore.load(coverFileName) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Image("BannerFlight")
                    .resizable()
                    .scaledToFill()
            }
        }
        .ticketClip(height: 120)
        .listRowInsets(EdgeInsets())
    }

    private func importCover(_ item: PhotosPickerItem?) async {
        guard let item else { return }
        guard let data = try? await item.loadTransferable(type: Data.self),
              let image = UIImage(data: data) else { return }
        await MainActor.run {
            pendingCover = image
            removeCover = false
        }
    }

    private func save() {
        nameError = name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Enter a place name." : nil
        countryError = country.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "Enter a country." : nil
        guard nameError == nil, countryError == nil else { return }
        var fileName = coverFileName
        if removeCover, pendingCover == nil {
            CoverImageStore.delete(fileName)
            fileName = nil
        }
        if let pendingCover, let saved = CoverImageStore.save(pendingCover, destinationId: destinationId) {
            fileName = saved
        }
        let item = Destination(
            id: destinationId,
            name: name.trimmingCharacters(in: .whitespacesAndNewlines),
            country: country.trimmingCharacters(in: .whitespacesAndNewlines),
            date: date,
            endDate: max(date, endDate),
            notes: notes,
            visited: existing?.visited ?? false,
            timezone: timezone,
            climate: climate,
            journal: existing?.journal ?? "",
            coverFileName: fileName
        )
        store.upsertDestination(item)
        UIImpactFeedbackGenerator(style: .light).impactOccurred()
        dismiss()
    }
}
