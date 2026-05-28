import XCTest
@testable import SlipApp

final class DateFormattingTests: XCTestCase {
    func testFormatsTodayAsTime() {
        let calendar = Calendar(identifier: .gregorian)
        let formatter = NoteDateFormatter(calendar: calendar)
        let now = Date(timeIntervalSince1970: 1_700_000_000)

        let label = formatter.label(for: now, relativeTo: now)

        XCTAssertFalse(label.isEmpty)
        XCTAssertTrue(label.contains(":"))
    }

    func testFormatsYesterdayAsYesterday() {
        let calendar = Calendar(identifier: .gregorian)
        let formatter = NoteDateFormatter(calendar: calendar)
        let now = Date(timeIntervalSince1970: 1_700_000_000)
        let yesterday = calendar.date(byAdding: .day, value: -1, to: now)!

        XCTAssertEqual(formatter.label(for: yesterday, relativeTo: now), "Yesterday")
    }
}
