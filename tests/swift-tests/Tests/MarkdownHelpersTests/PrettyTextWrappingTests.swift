import XCTest
import WebKit
@testable import MarkdownHelpers

final class PrettyTextWrappingTests: XCTestCase {
    func testPreferenceDefaultsOnAndPersistsDisabledState() throws {
        let suite = "PrettyTextWrappingTests." + UUID().uuidString
        let defaults = try XCTUnwrap(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }

        XCTAssertTrue(PrettyTextWrappingSetting.read(from: nil))
        XCTAssertTrue(PrettyTextWrappingSetting.read(from: defaults))
        PrettyTextWrappingSetting.write(false, to: defaults)
        XCTAssertFalse(PrettyTextWrappingSetting.read(from: UserDefaults(suiteName: suite)))
        PrettyTextWrappingSetting.write(true, to: defaults)
        XCTAssertTrue(PrettyTextWrappingSetting.read(from: defaults))
        XCTAssertNil(defaults.object(forKey: PrettyTextWrappingSetting.defaultsKey))
    }

    func testPreviewAndEditorSelectTheSameWrapStyleWithoutChangingMarkdown() {
        let markdown = "A paragraph with several lines of text that can wrap according to the window width."
        let pretty = MarkdownHTML.render(markdown: markdown, prettyTextWrapping: true)
        let normal = MarkdownHTML.render(markdown: markdown, prettyTextWrapping: false)
        XCTAssertEqual(pretty.articleHTML, normal.articleHTML)
        XCTAssertTrue(pretty.html.contains("--mdp-text-wrap-style: pretty;"))
        XCTAssertTrue(normal.html.contains("--mdp-text-wrap-style: wrap;"))

        for enabled in [true, false] {
            let editor = EditorHTML.render(
                markdown: markdown,
                editorJavaScript: "",
                configuration: .init(prettyTextWrapping: enabled)
            )
            let expected = enabled ? "pretty" : "wrap"
            XCTAssertTrue(editor.contains("--mdp-text-wrap-style: " + expected + ";"))
        }
    }

    @MainActor
    func testQuickLookStyleReachesWebKit() async throws {
        for enabled in [true, false] {
            let html = MarkdownHTML.makeHTML(
                from: "A sentence with enough words to wrap across several lines.",
                allowsScroll: true,
                prettyTextWrapping: enabled
            )
            let web = WKWebView(frame: CGRect(x: 0, y: 0, width: 420, height: 400))
            web.loadHTMLString(html, baseURL: nil)
            let deadline = Date().addingTimeInterval(10)
            while web.isLoading && Date() < deadline {
                try await Task.sleep(for: .milliseconds(10))
            }
            XCTAssertFalse(web.isLoading)
            let actual = try await web.evaluateJavaScript(
                "getComputedStyle(document.documentElement).getPropertyValue('--mdp-text-wrap-style').trim()"
            ) as? String
            XCTAssertEqual(actual, enabled ? "pretty" : "wrap")
            web.stopLoading()
        }
    }
}
