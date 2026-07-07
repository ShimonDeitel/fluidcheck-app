import SwiftUI

struct ContentView: View {
    @EnvironmentObject var store: FluidCheckStore
    @EnvironmentObject var purchases: PurchaseManager
    @State private var showingAdd = false
    @State private var showingPaywall = false
    @State private var editingItem: FluidCheck? = nil
    @State private var showingSettings = false

    var body: some View {
        NavigationStack {
            ZStack {
                FluidCheckTheme.background.ignoresSafeArea()
                List {
                    ForEach(store.items) { item in
                        Button {
                            editingItem = item
                        } label: {
                            row(for: item)
                        }
                        .listRowBackground(FluidCheckTheme.card)
                        .accessibilityIdentifier("row_\(item.name)")
                    }
                    .onDelete { offsets in
                        store.delete(at: offsets)
                    }
                }
                .scrollContentBackground(.hidden)
                .listStyle(.plain)
            }
            .navigationTitle("Fluid Levels Checklist")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        showingSettings = true
                    } label: {
                        Image(systemName: "gearshape.fill")
                    }
                    .accessibilityIdentifier("settingsButton")
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        if store.canAddMore {
                            showingAdd = true
                        } else {
                            showingPaywall = true
                        }
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    .accessibilityIdentifier("addButton")
                }
            }
            .sheet(isPresented: $showingAdd) {
                FluidCheckFormView(mode: .add) { new in
                    if !store.add(new) {
                        showingPaywall = true
                    }
                }
            }
            .sheet(item: $editingItem) { item in
                FluidCheckFormView(mode: .edit(item)) { updated in
                    store.update(updated)
                } onDelete: {
                    store.delete(id: item.id)
                }
            }
            .sheet(isPresented: $showingPaywall) {
                PaywallView()
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView()
            }
        }
        .tint(FluidCheckTheme.accent)
    }

    @ViewBuilder
    private func row(for item: FluidCheck) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(item.name)
                .font(FluidCheckTheme.bodyFont)
                .foregroundColor(FluidCheckTheme.textPrimary)
            Text(item.detail)
                .font(FluidCheckTheme.captionFont)
                .foregroundColor(FluidCheckTheme.textSecondary)
            Text(item.date, style: .date)
                .font(FluidCheckTheme.captionFont)
                .foregroundColor(FluidCheckTheme.accent)
        }
        .padding(.vertical, 4)
    }
}

enum FluidCheckFormMode {
    case add
    case edit(FluidCheck)
}

struct FluidCheckFormView: View {
    let mode: FluidCheckFormMode
    var onSave: (FluidCheck) -> Void
    var onDelete: (() -> Void)? = nil

    @Environment(\.dismiss) private var dismiss
    @State private var name: String = ""
    @State private var detail: String = ""
    @State private var date: Date = Date()
    @State private var note: String = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Fluid name") {
                    TextField("Fluid name", text: $name)
                        .accessibilityIdentifier("nameField")
                }
                Section("Level status") {
                    TextField("Level status", text: $detail)
                        .accessibilityIdentifier("detailField")
                }
                Section("Checked date") {
                    DatePicker("Checked date", selection: $date, displayedComponents: .date)
                        .accessibilityIdentifier("dateField")
                }
                Section("Note") {
                    TextField("Optional note", text: $note, axis: .vertical)
                        .accessibilityIdentifier("noteField")
                }
                if case .edit = mode, let onDelete {
                    Section {
                        Button("Delete", role: .destructive) {
                            onDelete()
                            dismiss()
                        }
                        .accessibilityIdentifier("deleteButton")
                    }
                }
            }
            .onTapGesture {
                hideKeyboard()
            }
            .navigationTitle(isEditing ? "Edit Fluid Check" : "New Fluid Check")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .accessibilityIdentifier("cancelButton")
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        save()
                    }
                    .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                    .accessibilityIdentifier("saveButton")
                }
            }
            .onAppear(perform: populate)
        }
    }

    private var isEditing: Bool {
        if case .edit = mode { return true }
        return false
    }

    private func populate() {
        if case .edit(let item) = mode {
            name = item.name
            detail = item.detail
            date = item.date
            note = item.note
        }
    }

    private func save() {
        var item: FluidCheck
        if case .edit(let existing) = mode {
            item = existing
        } else {
            item = FluidCheck(name: name, detail: detail, date: date)
        }
        item.name = name
        item.detail = detail
        item.date = date
        item.note = note
        onSave(item)
        dismiss()
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    ContentView()
        .environmentObject(FluidCheckStore())
        .environmentObject(PurchaseManager())
}
