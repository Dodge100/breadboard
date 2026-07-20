import SwiftUI

// MARK: - Profile Manager View

/// Profile management view usable in Settings or as a sheet.
struct ConfigProfileManagerView: View {
    @ObservedObject var store: RemapStore
    @Environment(\.dismiss) private var dismiss
    @State private var isSheet: Bool = false

    @State private var showRenameAlert = false
    @State private var renameTarget: ConfigProfile?
    @State private var renameText = ""
    @State private var showDeleteAlert = false
    @State private var deleteTarget: ConfigProfile?
    @State private var deleteError: String?

    var body: some View {
        VStack(spacing: 0) {
            // Header with close button
            HStack {
                Text("Profiles")
                    .font(.headline)
                Spacer()
                Button("Done") {
                    dismiss()
                }
                .keyboardShortcut(.defaultAction)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            Divider()

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
                    Text("New Profile")
                }
                .controlSize(.small)

                Button {
                    guard let active = store.activeProfile else { return }
                    store.duplicateProfile(active.id)
                } label: {
                    Text("Duplicate Active")
                }
                .controlSize(.small)
                .disabled(store.activeProfile == nil)

                Spacer()
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(.quaternary.opacity(0.3))
        }
        .frame(minWidth: 380, minHeight: 300)
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
        HStack(spacing: 10) {
            // Icon with popover picker
            Button {
                showIconPicker.toggle()
            } label: {
                Image(systemName: profile.icon)
                    .font(.body)
                    .foregroundStyle(isActive ? Color.accentColor : .secondary)
                    .frame(width: 20, height: 20)
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showIconPicker, arrowEdge: .trailing) {
                iconPickerPopover
            }

            // Name
            Text(profile.name)
                .lineLimit(1)

            Spacer()

            // Active indicator or switch button
            if isActive {
                Text("Active")
                    .font(.caption)
                    .foregroundStyle(Color.accentColor)
            } else {
                Button("Switch") {
                    onSwitch()
                }
                .controlSize(.small)
            }

            // Context menu
            Menu {
                Button("Rename") { onRename() }
                Button("Duplicate") { onDuplicate() }
                Divider()
                Button("Delete", role: .destructive) { onDelete() }
                    .disabled(profile.name == "Default")
            } label: {
                Image(systemName: "ellipsis")
                    .foregroundStyle(.tertiary)
            }
            .menuStyle(.borderlessButton)
            .fixedSize()
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 8)
        .background(isActive ? Color.accentColor.opacity(0.06) : Color.clear)
        .cornerRadius(6)
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
                Section {
                    ForEach(store.profiles) { profile in
                        Button {
                            store.switchProfile(to: profile.id)
                        } label: {
                            Text(profile.name)
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
                    Text("Manage Profiles\u{2026}")
                }
            } label: {
                Text(active.name)
                    .font(.callout)
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
