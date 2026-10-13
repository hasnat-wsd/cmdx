import CmdXCore
import Testing

@MainActor
struct ClipboardChangeAwaiterTests {
    @Test func reportsChangeOnceClipboardIsUpdated() {
        let pasteboard = FakePasteboard()
        let scheduler = ManualScheduler()
        let awaiter = ClipboardChangeAwaiter(pasteboard: pasteboard, scheduler: scheduler)
        var result: Bool?

        awaiter.awaitChange(from: 0) { result = $0 }
        pasteboard.replaceContents(with: [Fixtures.file])
        scheduler.runUntilIdle()

        #expect(result == true)
    }

    @Test func givesUpAfterMaxAttempts() {
        let scheduler = ManualScheduler()
        let awaiter = ClipboardChangeAwaiter(pasteboard: FakePasteboard(), scheduler: scheduler, maxAttempts: 4)
        var results: [Bool] = []

        awaiter.awaitChange(from: 0) { results.append($0) }
        scheduler.runUntilIdle()

        #expect(results == [false])
    }
}
