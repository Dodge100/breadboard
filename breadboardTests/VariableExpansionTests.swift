import XCTest
@testable import breadboard

final class VariableExpansionTests: XCTestCase {

    var store: RemapStore!

    override func setUp() {
        super.setUp()
        store = RemapStore()
    }

    override func tearDown() {
        store = nil
        super.tearDown()
    }

    // MARK: - expandVariableTokens

    func testNoVariables() {
        let result = store.expandVariableTokens(in: "hello world")
        XCTAssertEqual(result, "hello world")
    }

    func testSimpleVariable() {
        store.engine.setVariable(name: "name", value: "Breadboard")
        let result = store.expandVariableTokens(in: "Hello {{name}}")
        XCTAssertEqual(result, "Hello Breadboard")
    }

    func testMultipleVariables() {
        store.engine.setVariable(name: "first", value: "John")
        store.engine.setVariable(name: "last", value: "Doe")
        let result = store.expandVariableTokens(in: "{{first}} {{last}}")
        XCTAssertEqual(result, "John Doe")
    }

    func testVariableAtStart() {
        store.engine.setVariable(name: "prefix", value: "Mr.")
        let result = store.expandVariableTokens(in: "{{prefix}} Smith")
        XCTAssertEqual(result, "Mr. Smith")
    }

    func testVariableAtEnd() {
        store.engine.setVariable(name: "suffix", value: "Jr.")
        let result = store.expandVariableTokens(in: "John {{suffix}}")
        XCTAssertEqual(result, "John Jr.")
    }

    func testGlobalVariable() {
        store.engine.setGlobalVariable(name: "gvar", value: "GLOBAL")
        let result = store.expandVariableTokens(in: "Value: {{gvar}}")
        XCTAssertEqual(result, "Value: GLOBAL")
    }

    func testMultipleSameVariable() {
        store.engine.setVariable(name: "x", value: "42")
        let result = store.expandVariableTokens(in: "{{x}} + {{x}} = 84")
        XCTAssertEqual(result, "42 + 42 = 84")
    }

    func testRecursiveVariableNotExpanded() {
        store.engine.setVariable(name: "inner", value: "inner_value")
        store.engine.setVariable(name: "outer", value: "before {{inner}} after")
        let result = store.expandVariableTokens(in: "{{outer}}")
        // Variables are not recursively expanded
        XCTAssertEqual(result, "before {{inner}} after")
    }

    func testNonexistentVariable() {
        let result = store.expandVariableTokens(in: "Hello {{nonexistent}}")
        XCTAssertEqual(result, "Hello ")
    }

    func testVariableInMiddleOfText() {
        store.engine.setVariable(name: "mid", value: "MIDDLE")
        let result = store.expandVariableTokens(in: "before {{mid}} after")
        XCTAssertEqual(result, "before MIDDLE after")
    }

    func testBracesNotVariables() {
        let result = store.expandVariableTokens(in: "Just {text} here")
        XCTAssertEqual(result, "Just {text} here")
    }

    func testSingleBrace() {
        let result = store.expandVariableTokens(in: "Just {text here")
        XCTAssertEqual(result, "Just {text here")
    }

    func testMixedVariablesAndBraces() {
        store.engine.setVariable(name: "var", value: "value")
        let result = store.expandVariableTokens(in: "{{var}} and {not_a_var}")
        XCTAssertEqual(result, "value and {not_a_var}")
    }

    func testEmptyText() {
        let result = store.expandVariableTokens(in: "")
        XCTAssertEqual(result, "")
    }

    func testEmptyVariableName() {
        let result = store.expandVariableTokens(in: "{{}}")
        XCTAssertEqual(result, "")
    }

    func testVariableWithSpecialCharacters() {
        store.engine.setVariable(name: "user_name", value: "john_doe-123")
        let result = store.expandVariableTokens(in: "User: {{user_name}}")
        XCTAssertEqual(result, "User: john_doe-123")
    }
}
