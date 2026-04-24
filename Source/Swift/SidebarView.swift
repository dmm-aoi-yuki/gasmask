import SwiftUI
import UniformTypeIdentifiers

struct SidebarView: View {
    @ObservedObject var store: HostsDataStore

    @State private var renameError: String?
    @State private var hostsToRemove: Hosts?
    @State private var iconPickerHosts: Hosts?

    var body: some View {
        List(selection: $store.selectedHosts) {
            ForEach(store.hostsGroups, id: \.self) { group in
                let children = (group.children as? [Hosts]) ?? []
                Section(header: HostsRowView(hosts: group, isGroup: true, refreshToken: store.rowRefreshToken)) {
                    ForEach(children, id: \.self) { hosts in
                        HostsRowView(hosts: hosts, isGroup: false, refreshToken: store.rowRefreshToken)
                            .contextMenu { contextMenuItems(for: hosts) }
                            .tag(hosts)
                    }
                    .onMove { source, destination in
                        moveHosts(in: group, from: source, to: destination)
                    }
                }
                .onDrop(of: [.fileURL, .url], delegate: SidebarDropDelegate(group: group))
            }
        }
        .listStyle(.sidebar)
        .onReceive(store.$renamingHosts) { newValue in
            if let hosts = newValue {
                showRenamePanel(for: hosts)
            }
        }
        .alert(Text("Rename Error"), isPresented: Binding(
            get: { renameError != nil },
            set: { if !$0 { renameError = nil } }
        )) {
            Button("OK") { renameError = nil }
        } message: {
            Text(renameError ?? "")
        }
        .alert(Text("Remove Hosts File"), isPresented: Binding(
            get: { hostsToRemove != nil },
            set: { if !$0 { hostsToRemove = nil } }
        )) {
            Button("Cancel", role: .cancel) { hostsToRemove = nil }
            Button("Remove", role: .destructive) {
                if let hosts = hostsToRemove {
                    HostsMainController.defaultInstance()?.removeHostsFile(hosts, moveToTrash: true)
                }
                hostsToRemove = nil
            }
        } message: {
            Text(String(format: NSLocalizedString("Are you sure you want to remove \"%@\"? The file will be moved to Trash.", comment: ""), hostsToRemove?.name() ?? ""))
        }
        .sheet(isPresented: Binding(
            get: { iconPickerHosts != nil },
            set: { if !$0 { iconPickerHosts = nil } }
        )) {
            if let hosts = iconPickerHosts {
                IconPickerView(hosts: hosts)
            }
        }
    }

    // MARK: - Helpers

    private func moveHosts(in group: HostsGroup, from source: IndexSet, to destination: Int) {
        guard let controller = HostsMainController.defaultInstance() else { return }
        let children = (group.children as? [Hosts]) ?? []
        guard let sourceIndex = source.first, sourceIndex < children.count else { return }
        let hosts = children[sourceIndex]
        let adjustedDestination = destination > sourceIndex ? destination - 1 : destination
        controller.moveHostsFile(hosts, to: adjustedDestination)
    }

    // MARK: - Rename

    private func showRenamePanel(for hosts: Hosts) {
        defer { store.renamingHosts = nil }

        let alert = NSAlert()
        alert.messageText = NSLocalizedString("Rename", comment: "Rename dialog title")
        alert.addButton(withTitle: NSLocalizedString("OK", comment: ""))
        alert.addButton(withTitle: NSLocalizedString("Cancel", comment: ""))

        let textField = NSTextField(frame: NSRect(x: 0, y: 0, width: 200, height: 24))
        textField.stringValue = hosts.name() ?? ""
        textField.isEditable = true
        textField.isSelectable = true
        alert.accessoryView = textField
        alert.window.initialFirstResponder = textField

        guard alert.runModal() == .alertFirstButtonReturn else { return }

        let trimmed = textField.stringValue.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }

        if trimmed.contains("/") {
            renameError = NSLocalizedString("File name cannot contain forward slash.", comment: "")
            return
        }

        guard let controller = HostsMainController.defaultInstance() else { return }
        let renamed = controller.rename(hosts, to: trimmed)
        if renamed {
            NotificationCenter.default.post(name: .hostsFileRenamed, object: hosts)
        } else {
            renameError = NSLocalizedString("A file with that name already exists.", comment: "")
        }
    }

    // MARK: - Context Menu

    @ViewBuilder
    private func contextMenuItems(for hosts: Hosts) -> some View {
        if !hosts.saved() {
            Button("Save") {
                HostsMainController.defaultInstance()?.save(hosts)
            }
        }

        if !hosts.active() {
            Button("Activate") {
                HostsMainController.defaultInstance()?.activateHostsFile(hosts)
            }
            .disabled(!hosts.exists)
        }

        Button("Show In Finder") {
            if let path = hosts.path {
                NSWorkspace.shared.selectFile(path, inFileViewerRootedAtPath: "")
            }
        }
        .disabled(!hosts.exists)

        if let remote = hosts as? RemoteHosts {
            Button("Open in Browser") {
                if let url = remote.url {
                    NSWorkspace.shared.open(url)
                }
            }
        }

        Divider()

        if hosts is RemoteHosts {
            Button("Move to Local") {
                HostsMainController.defaultInstance()?.move(hosts, toControllerClass: LocalHostsController.self)
            }
            .disabled(!hosts.exists)
        }

        Button("Rename") {
            store.renamingHosts = hosts
        }

        Button(NSLocalizedString("Set Status Bar Icon…", comment: "Context menu")) {
            iconPickerHosts = hosts
        }

        Divider()

        if store.canRemoveFiles {
            Button("Remove") {
                hostsToRemove = hosts
            }
        }
    }
}

// MARK: - Drop Support

extension SidebarView {

    struct SidebarDropDelegate: DropDelegate {
        let group: HostsGroup

        func validateDrop(info: DropInfo) -> Bool {
            info.hasItemsConforming(to: [.fileURL, .url])
        }

        func performDrop(info: DropInfo) -> Bool {
            guard let controller = HostsMainController.defaultInstance() else { return false }

            let providers = info.itemProviders(for: [.fileURL, .url])
            var handled = false
            for provider in providers {
                if provider.canLoadObject(ofClass: URL.self) {
                    handled = true
                    _ = provider.loadObject(ofClass: URL.self) { url, error in
                        if let error {
                            NSLog("Drop URL load failed: %@", error.localizedDescription)
                            return
                        }
                        guard let url else { return }
                        DispatchQueue.main.async {
                            if url.isFileURL {
                                _ = controller.createHosts(fromLocalURL: url, to: group)
                            } else {
                                _ = controller.createHosts(from: url, to: group)
                            }
                        }
                    }
                }
            }
            return handled
        }
    }
}
