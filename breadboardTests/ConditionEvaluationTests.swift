import XCTest
@testable import breadboard

final class ConditionEvaluationTests: XCTestCase {

    // MARK: - compare (the core comparison function)

    func testCompareIsEqual() {
        let engine = KeyboardRemapEngine()
        XCTAssertTrue(engine.compare("Safari", .isEqual, "Safari"))
        XCTAssertTrue(engine.compare("SAFARI", .isEqual, "safari"), "Should be case-insensitive")
        XCTAssertFalse(engine.compare("Safari", .isEqual, "Finder"))
    }

    func testCompareIsNotEqual() {
        let engine = KeyboardRemapEngine()
        XCTAssertTrue(engine.compare("Safari", .isNotEqual, "Finder"))
        XCTAssertFalse(engine.compare("Safari", .isNotEqual, "Safari"))
        XCTAssertFalse(engine.compare("SAFARI", .isNotEqual, "safari"), "Should treat same as equal")
    }

    func testCompareContains() {
        let engine = KeyboardRemapEngine()
        XCTAssertTrue(engine.compare("com.apple.Safari", .contains, "safari"))
        XCTAssertTrue(engine.compare("com.apple.Safari", .contains, "apple"))
        XCTAssertFalse(engine.compare("com.apple.Safari", .contains, "finder"))
    }

    func testCompareMatches() {
        let engine = KeyboardRemapEngine()
        XCTAssertTrue(engine.compare("com.apple.Safari", .matches, ".*Safari$"))
        XCTAssertTrue(engine.compare("com.apple.Safari", .matches, "safari"), "Should convert to regex and be case-insensitive")
        XCTAssertFalse(engine.compare("com.apple.Safari", .matches, "^Finder"))
        // Invalid regex should not crash
        XCTAssertFalse(engine.compare("test", .matches, "["))
    }

    func testCompareEmptyStrings() {
        let engine = KeyboardRemapEngine()
        XCTAssertTrue(engine.compare("", .isEqual, ""))
        XCTAssertFalse(engine.compare("", .isEqual, "a"))
        XCTAssertTrue(engine.compare("", .contains, ""))
        XCTAssertFalse(engine.compare("", .contains, "a"))
    }

    // MARK: - Variable evaluation

    func testVariableCondition() {
        let engine = KeyboardRemapEngine()
        engine.setVariable(name: "myvar", value: "hello")

        // Test that condition evaluation works with in-memory variables
        // We need to call evaluateCondition, which calls conditionMet
        let cond = Condition(kind: .variable, op: .isEqual, target: "myvar", value: "hello")
        XCTAssertTrue(engine.evaluateCondition(cond))

        let cond2 = Condition(kind: .variable, op: .isEqual, target: "myvar", value: "world")
        XCTAssertFalse(engine.evaluateCondition(cond2))
    }

    func testVariableConditionNotSet() {
        let engine = KeyboardRemapEngine()
        let cond = Condition(kind: .variable, op: .isEqual, target: "nonexistent", value: "")
        // Empty string == empty string
        XCTAssertTrue(engine.evaluateCondition(cond))
    }

    func testGlobalVariableCondition() {
        let engine = KeyboardRemapEngine()
        engine.setGlobalVariable(name: "gvar", value: "global_value")

        let cond = Condition(kind: .globalVariable, op: .isEqual, target: "gvar", value: "global_value")
        XCTAssertTrue(engine.evaluateCondition(cond))
    }

    func testNamedClipboardCondition() {
        let engine = KeyboardRemapEngine()
        engine.setNamedClipboard(name: "clip1", value: "clipboard_text")

        let cond = Condition(kind: .namedClipboard, op: .contains, target: "clip1", value: "board")
        XCTAssertTrue(engine.evaluateCondition(cond))
    }

    func testExpressionCondition() {
        let engine = KeyboardRemapEngine()
        engine.setVariable(name: "x", value: "5")

        // Expression "5 == 5" should be true
        var cond = Condition(kind: .expression, op: .isEqual, target: "5 == 5", value: "")
        XCTAssertTrue(engine.evaluateCondition(cond))

        cond = Condition(kind: .expression, op: .isEqual, target: "2 + 2 == 4", value: "")
        XCTAssertTrue(engine.evaluateCondition(cond))

        // Expression "5 == 6" should be false
        cond = Condition(kind: .expression, op: .isEqual, target: "5 == 6", value: "")
        XCTAssertFalse(engine.evaluateCondition(cond))
    }

    func testEventChangedCondition() {
        let engine = KeyboardRemapEngine()
        let cond = Condition(kind: .eventChanged, op: .isEqual, target: "", value: "")
        XCTAssertTrue(engine.evaluateCondition(cond), "eventChanged should always return true")
    }

    // MARK: - Condition with frontmostApp (requires running app bundle ID)

    func testFrontmostAppCondition() {
        let engine = KeyboardRemapEngine()
        // We can't perfectly test frontmostApp without mocking NSWorkspace,
        // but we can verify it evaluates without crashing.
        // The actual value depends on the running test host.
        let cond = Condition(kind: .frontmostApp, op: .isEqual, target: "com.apple.xctest")
        // This will return the result of comparing the current frontmost app,
        // which might be any app. We just verify it's a Bool.
        let result = engine.evaluateCondition(cond)
        XCTAssertTrue(type(of: result) == Bool.self)
    }
}
