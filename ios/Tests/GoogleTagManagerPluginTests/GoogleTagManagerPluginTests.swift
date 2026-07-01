import XCTest
@testable import GoogleTagManagerPlugin

class GoogleTagManagerTests: XCTestCase {
    func testGTMManagerInitializes() {
        let manager = GTMManager()
        XCTAssertNotNil(manager)
    }
}
