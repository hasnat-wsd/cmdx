import CmdXCore
import Foundation
import Testing

struct CutItemMatcherTests {
    private let documents = URL(fileURLWithPath: "/Users/test/Documents", isDirectory: true)

    @Test func matchesByExactURL() {
        let matcher = CutItemMatcher(items: [Fixtures.file], folder: nil)

        #expect(matcher.matches(url: Fixtures.file, labels: []))
        #expect(!matcher.matches(url: Fixtures.other, labels: []))
    }

    @Test func ignoresTrailingSlashOnFolders() {
        let matcher = CutItemMatcher(items: [Fixtures.folder], folder: nil)

        #expect(matcher.matches(url: URL(fileURLWithPath: "/Users/test/Documents/Photos"), labels: []))
    }

    @Test func matchesByNameInTheShownFolder() {
        let matcher = CutItemMatcher(items: [Fixtures.file], folder: documents)

        #expect(matcher.matches(url: nil, labels: ["report.pdf"]))
    }

    @Test func neverMatchesSameNameInAnotherFolder() {
        let matcher = CutItemMatcher(items: [Fixtures.file], folder: URL(fileURLWithPath: "/Users/test/Desktop"))

        #expect(!matcher.matches(url: nil, labels: ["report.pdf"]))
    }

    @Test func matchesNameShownWithExtensionHidden() {
        let matcher = CutItemMatcher(items: [Fixtures.file], folder: documents, displayNames: [Fixtures.file: "report"])

        #expect(matcher.matches(url: nil, labels: ["report"]))
    }

    @Test func doesNotMatchUnrelatedLabels() {
        let folderNamedFolder = URL(fileURLWithPath: "/Users/test/Documents/Folder")
        let matcher = CutItemMatcher(items: [folderNamedFolder], folder: documents)

        #expect(!matcher.matches(url: nil, labels: ["Photos", "Today"]))
        #expect(!matcher.matches(url: nil, labels: []))
    }
}
