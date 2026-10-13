//
//  InspectorViewController.swift
//  md-preview
//

import Cocoa
import SwiftUI

final class InspectorViewController: NSViewController {

    private var host: NSHostingView<InspectorView>!
    private var metadata = DocumentMetadata()
    private var selectedTextStatistics: SelectedTextStatistics?

    override func loadView() {
        host = NSHostingView(
            rootView: InspectorView(metadata: metadata, selectedTextStatistics: selectedTextStatistics)
        )
        view = host
    }

    func display(metadata: DocumentMetadata) {
        self.metadata = metadata
        loadViewIfNeeded()
        updateHost()
    }

    func displaySelectedText(_ selectedText: String?) {
        let statistics = selectedText.map { SelectedTextStatistics(text: $0) }
        guard selectedTextStatistics != statistics else { return }
        selectedTextStatistics = statistics
        updateHost()
    }

    private func updateHost() {
        loadViewIfNeeded()
        host.rootView = InspectorView(metadata: metadata, selectedTextStatistics: selectedTextStatistics)
    }
}
