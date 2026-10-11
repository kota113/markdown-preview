//
//  DocumentWindowController+Autosave.swift
//  md-preview
//
//  Automatic saving of edited documents.
//

import Cocoa

extension DocumentWindowController {
    // MARK: - Autosave

    func applyAutoSaveIntervalSetting() {
        guard hasUnsavedEditorChanges else { return }
        stopAutoSaveTimer()
        startAutoSaveTimerIfNeeded()
    }

    func startAutoSaveTimerIfNeeded() {
        guard autoSaveTimer == nil,
              currentFileURL != nil,
              hasUnsavedEditorChanges,
              let interval = AutoSaveSetting.interval else { return }
        let timerID = UUID()
        autoSaveTimerID = timerID
        autoSaveTimer = Timer.scheduledTimer(
            withTimeInterval: interval,
            repeats: false
        ) { [weak self, timerID] _ in
            Task { @MainActor [weak self] in
                guard let self, self.autoSaveTimerID == timerID else { return }
                self.autoSaveTimer = nil
                self.autoSaveTimerID = nil
                self.performAutomaticSave()
            }
        }
    }

    func stopAutoSaveTimer() {
        autoSaveTimer?.invalidate()
        autoSaveTimer = nil
        autoSaveTimerID = nil
    }

    private func performAutomaticSave() {
        guard hasUnsavedEditorChanges,
              !isEditorCommitInFlight,
              currentFileURL != nil else { return }

        isPerformingAutomaticSave = true
        editorSaveStatus = .saving
        commitEdits(exitAfter: false) { [weak self] success in
            guard let self else { return }
            self.isPerformingAutomaticSave = false
            guard !success else { return }
            self.showAutoSaveFailure()
        }
    }

    private func showAutoSaveFailure() {
        guard hasUnsavedEditorChanges else { return }
        autoSaveFeedbackResetWork?.cancel()
        autoSaveFeedbackResetWork = nil
        editorSaveStatus = .failed

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.autoSaveFeedbackResetWork = nil
            if self.editorSaveStatus == .failed {
                self.editorSaveStatus = .edited
            }
        }
        autoSaveFeedbackResetWork = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5, execute: work)
    }

    func resetAutoSaveFeedback() {
        autoSaveFeedbackResetWork?.cancel()
        autoSaveFeedbackResetWork = nil
        if editorSaveStatus == .failed {
            editorSaveStatus = .edited
        }
    }

    func updateWindowSubtitle() {
        switch editorSaveStatus {
        case .unchanged:
            documentWindow.subtitle = ""
        case .edited:
            documentWindow.subtitle = NSLocalizedString(
                "Edited", comment: "Window subtitle for unsaved changes")
        case .saving:
            documentWindow.subtitle = NSLocalizedString(
                "Saving", comment: "Window subtitle while automatically saving edits")
        case .saved:
            documentWindow.subtitle = NSLocalizedString(
                "Saved", comment: "Window subtitle after edits were saved successfully")
        case .failed:
            documentWindow.subtitle = NSLocalizedString(
                "Auto-save failed", comment: "Window subtitle after an automatic save failure")
        }
    }
}
