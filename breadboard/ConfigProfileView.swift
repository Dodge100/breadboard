import SwiftUI

// MARK: - Profile Manager Sheet

/// Full profile management view presented as a sheet.
/// Allows creating, renaming, duplicating, deleting, and switching profiles.
struct ConfigProfileManagerView: View {
    @ObservedObject var store: RemapStore
    @Environment(\.dismiss) private var dismiss

    @State private var showRenameAlert = false
    @State private var renameTarget: ConfigProfile?
    @State private var renameText = ""
    @State private var showDeleteAlert = false
    @State private var deleteTarget: ConfigProfile?
    @State private var deleteError: String?

    var body: some View {
        VStack(spacing: 0) {
            // ── Header ────────────────────────────────────────────
            HStack {
                Label("Config Profiles", systemImage: "square.on.square")
                    .font(.headline)
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.escape)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(.ultraThinMaterial)

            if store.profiles.isEmpty {
                Spacer()
                ContentUnavailableView {
                    Label("No Profiles", systemImage: "square.on.square")
                } description: {
                    Text("Create a profile to get started.")
                } actions: {
                    Button("Create Default Profile") {
                        let profile = ConfigProfile.default()
                        store.profiles.append(profile)
                        store.activeProfileID = profile.id
                        store.manipulators = Manipulator.defaults()
                        store.saveProfilesManifest()
                        store.saveConfig()
                        store.applyRemaps()
                    }
                    .buttonStyle(.borderedProminent)
                }
                Spacer()
            } else {
                profileList
            }

            // ── Footer ────────────────────────────────────────────
            HStack(spacing: 8) {
                Button {
                    createProfile()
                } label: {
                    Label("New Profile", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)

                Button {
                    guard let active = store.activeProfile else { return }
                    store.duplicateProfile(active.id)
                } label: {
                    Label("Duplicate Active", systemImage: "doc.on.doc")
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                .disabled(store.activeProfile == nil)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.quaternary.opacity(0.3))
        }
        .frame(minWidth: 420, minHeight: 360)
        .alert("Rename Profile", isPresented: $showRenameAlert) {
            TextField("Name", text: $renameText)
            Button("Rename") {
                if let target = renameTarget, !renameText.trimmingCharacters(in: .whitespaces).isEmpty {
                    store.renameProfile(target.id, name: renameText.trimmingCharacters(in: .whitespaces))
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter a new name for this profile.")
        }
        .alert("Delete Profile?", isPresented: $showDeleteAlert) {
            Button("Delete", role: .destructive) {
                if let target = deleteTarget {
                    do {
                        try store.deleteProfile(target.id)
                    } catch let error as ProfileError {
                        deleteError = error.localizedDescription
                    } catch {}
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let target = deleteTarget {
                Text("Delete \"\(target.name)\"? This cannot be undone.")
            }
        }
        .alert("Cannot Delete", isPresented: Binding(
            get: { deleteError != nil },
            set: { if !$0 { deleteError = nil } }
        )) {
            Button("OK") { deleteError = nil }
        } message: {
            Text(deleteError ?? "")
        }
    }

    // MARK: - Profile List

    private var profileList: some View {
        List {
            ForEach(store.profiles) { profile in
                ProfileRow(
                    profile: profile,
                    isActive: profile.id == store.activeProfileID,
                    onSwitch: { store.switchProfile(to: profile.id) },
                    onRename: {
                        renameTarget = profile
                        renameText = profile.name
                        showRenameAlert = true
                    },
                    onDuplicate: { store.duplicateProfile(profile.id) },
                    onDelete: {
                        deleteTarget = profile
                        showDeleteAlert = true
                    },
                    onChangeIcon: { icon in
                        store.updateProfileIcon(profile.id, icon: icon)
                    }
                )
            }
        }
        .listStyle(.inset(alternatesRowBackgrounds: true))
    }

    // MARK: - Create Profile

    private func createProfile() {
        let baseName = "Profile \(store.profiles.count + 1)"
        store.createProfile(name: baseName, icon: "person")
    }
}

// MARK: - Profile Row

private struct ProfileRow: View {
    let profile: ConfigProfile
    let isActive: Bool
    let onSwitch: () -> Void
    let onRename: () -> Void
    let onDuplicate: () -> Void
    let onDelete: () -> Void
    let onChangeIcon: (String) -> Void

    @State private var showIconPicker = false

    var body: some View {
        HStack(spacing: 12) {
            // Icon with popover picker
            Button {
                showIconPicker.toggle()
            } label: {
                Image(systemName: profile.icon)
                    .font(.title3)
                    .foregroundColor(isActive ? .accentColor : .secondary)
                    .frame(width: 28, height: 28)
            }
            .buttonStyle(.plain)
            .help("Change icon")
            .popover(isPresented: $showIconPicker, arrowEdge: .trailing) {
                iconPickerPopover
            }

            // Name and metadata
            VStack(alignment: .leading, spacing: 2) {
                Text(profile.name)
                    .font(.body.weight(.medium))
                    .lineLimit(1)
                if isActive {
                    Text("Active")
                        .font(.caption2)
                        .foregroundColor(.accentColor)
                }
            }

            Spacer()

            // Action buttons
            if !isActive {
                Button("Switch") {
                    onSwitch()
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            } else {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(.accentColor)
                    .font(.title3)
            }

            Menu {
                Button { onRename() } label: {
                    Label("Rename", systemImage: "pencil")
                }
                Button { onDuplicate() } label: {
                    Label("Duplicate", systemImage: "doc.on.doc")
                }
                Divider()
                Button(role: .destructive) { onDelete() } label: {
                    Label("Delete", systemImage: "trash")
                }
                .disabled(profile.name == "Default")
            } label: {
                Image(systemName: "ellipsis.circle")
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isActive ? Color.accentColor.opacity(0.06) : Color.clear)
        .cornerRadius(8)
    }

    // MARK: - Icon Picker Popover

    private var iconPickerPopover: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Choose an icon")
                .font(.caption.weight(.medium))
                .foregroundStyle(.secondary)
                .padding(.horizontal, 4)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 6), count: 6), spacing: 6) {
                ForEach(ConfigProfile.availableIcons, id: \.self) { icon in
                    Button {
                        onChangeIcon(icon)
                        showIconPicker = false
                    } label: {
                        Image(systemName: icon)
                            .font(.title3)
                            .frame(width: 32, height: 32)
                            .background(profile.icon == icon ? Color.accentColor.opacity(0.15) : Color.clear)
                            .cornerRadius(6)
                    }
                    .buttonStyle(.plain)
                    .help(icon)
                }
            }
            .padding(8)
        }
        .padding(8)
        .frame(width: 260)
    }
}

// MARK: - Toolbar Profile Switcher

/// Compact profile switcher for the toolbar. Shows the active profile's icon and name,
/// with a dropdown menu to switch or manage profiles.
struct ProfileSwitcherButton: View {
    @ObservedObject var store: RemapStore
    @State private var showManager = false

    var body: some View {
        if let active = store.activeProfile {
            Menu {
                Section("Profiles") {
                    ForEach(store.profiles) { profile in
                        Button {
                            store.switchProfile(to: profile.id)
                        } label: {
                            Label {
                                Text(profile.name)
                            } icon: {
                                Image(systemName: profile.icon)
                            }
                            if profile.id == active.id {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
                Divider()
                Button {
                    showManager = true
                } label: {
                    Label("Manage Profiles\u{2026}", systemImage: "square.on.square")
                }
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: active.icon)
                        .font(.body)
                    Text(active.name)
                        .font(.body)
                }
            }
            .menuStyle(.button)
            .buttonStyle(.plain)
            .help("Switch or manage config profiles")
            .sheet(isPresented: $showManager) {
                ConfigProfileManagerView(store: store)
            }
        }
    }
}
