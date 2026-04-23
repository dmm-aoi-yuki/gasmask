import AppKit
import SwiftUI

@objc final class PreferencesPresenter: NSObject {
    private static var window: NSWindow?

    @objc static func showPreferences() {
        if let existing = window {
            existing.makeKeyAndOrderFront(nil)
            return
        }

        let tabVC = PreferencesTabViewController()
        tabVC.tabStyle = .toolbar

        let contentSize = NSSize(width: 550, height: 150)

        func makeTab<V: View>(label: String, symbolName: String, rootView: V) -> NSTabViewItem {
            let hc = NSHostingController(rootView: rootView)
            hc.preferredContentSize = contentSize
            let item = NSTabViewItem(viewController: hc)
            item.label = label
            item.image = NSImage(systemSymbolName: symbolName, accessibilityDescription: label)
            return item
        }

        tabVC.addTabViewItem(makeTab(label: NSLocalizedString("General", comment: ""), symbolName: "gearshape", rootView: GeneralTab()))
        tabVC.addTabViewItem(makeTab(label: NSLocalizedString("Editor", comment: ""), symbolName: "square.and.pencil", rootView: EditorTab()))
        tabVC.addTabViewItem(makeTab(label: NSLocalizedString("Remote", comment: ""), symbolName: "globe", rootView: RemoteTab()))
        tabVC.addTabViewItem(makeTab(label: NSLocalizedString("Hotkeys", comment: ""), symbolName: "command.square.fill", rootView: HotkeysTab()))
        tabVC.addTabViewItem(makeTab(label: NSLocalizedString("Update", comment: ""), symbolName: "arrow.triangle.2.circlepath", rootView: UpdateTab()))

        let w = NSWindow(contentViewController: tabVC)
        w.styleMask = [.titled, .closable]
        w.toolbarStyle = .preference
        w.title = NSLocalizedString("General", comment: "")
        w.setFrameAutosaveName("PreferencesWindow")

        // Keep the window alive after close so it can be reopened
        w.isReleasedWhenClosed = false

        tabVC.preferencesWindow = w

        window = w
        w.center()
        w.makeKeyAndOrderFront(nil)
    }
}

// MARK: - Tab View Controller

private class PreferencesTabViewController: NSTabViewController {
    weak var preferencesWindow: NSWindow?

    override func tabView(_ tabView: NSTabView, didSelect tabViewItem: NSTabViewItem?) {
        super.tabView(tabView, didSelect: tabViewItem)
        let title = tabViewItem?.label ?? ""
        preferencesWindow?.title = title
        // super may reset title asynchronously; re-apply on next run loop
        DispatchQueue.main.async { [weak self] in
            self?.preferencesWindow?.title = title
        }
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        let title = tabViewItems[selectedTabViewItemIndex].label
        preferencesWindow?.title = title
    }
}
