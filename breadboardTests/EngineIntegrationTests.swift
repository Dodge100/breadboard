import XCTest
@testable import breadboard

final class EngineIntegrationTests: XCTestCase {

    // MARK: - apply() Routing

    func testApplyBuildsRoutingCache() {
        let engine = KeyboardRemapEngine()
        let manip = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )

        engine.apply([manip])

        // Apply is async (schedules on main thread), so we wait briefly
        let expectation = XCTestExpectation(description: "apply")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // Check that the engine is active (it starts when manipulators > 0)
        if case .active = engine.state {
            XCTAssertTrue(true)
        } else {
            XCTFail("Engine should be active after apply with manipulators, got \(engine.state)")
        }
    }

    func testApplyWithEmptyArray() {
        let engine = KeyboardRemapEngine()
        engine.apply([])

        let expectation = XCTestExpectation(description: "apply empty")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(engine.state, .inactive, "Engine should be inactive with no manipulators")
    }

    func testOnExecuteActionCallback() {
        let engine = KeyboardRemapEngine()
        let manip = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )

        var executedManipulator: Manipulator?
        var executedAction: Action?
        engine.onExecuteAction = { manip, action, _ in
            executedManipulator = manip
            executedAction = action
        }

        engine.apply([manip])

        let expectation = XCTestExpectation(description: "apply")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        // The callback should be set, but we can't test actual key events
        // without posting real CGEvents (requires Accessibility permissions).
        XCTAssertNotNil(engine.onExecuteAction)
    }

    // MARK: - State Transitions

    func testEngineStartsInactive() {
        let engine = KeyboardRemapEngine()
        XCTAssertEqual(engine.state, .inactive)
    }

    func testStateChangeCallback() {
        let engine = KeyboardRemapEngine()
        var states: [KeyboardRemapEngineState] = []
        engine.onStateChange = { states.append($0) }

        engine.apply([
            Manipulator(
                trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
                actions: [Action(toKey: "e")]
            )
        ])

        let expectation = XCTestExpectation(description: "state change")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        let hasActiveState = states.contains { if case .active = $0 { return true }; return false }
        XCTAssertTrue(hasActiveState, "Engine should transition to active")
    }

    // MARK: - Variables

    func testSetAndGetVariable() {
        let engine = KeyboardRemapEngine()
        engine.setVariable(name: "testVar", value: "testValue")
        XCTAssertEqual(engine.variables["testVar"], "testValue")
    }

    func testUnsetVariable() {
        let engine = KeyboardRemapEngine()
        engine.setVariable(name: "testVar", value: "testValue")
        engine.unsetVariable(name: "testVar")
        XCTAssertNil(engine.variables["testVar"])
    }

    func testResetVariables() {
        let engine = KeyboardRemapEngine()
        engine.setVariable(name: "a", value: "1")
        engine.setVariable(name: "b", value: "2")
        engine.resetVariables()
        XCTAssertTrue(engine.variables.isEmpty)
    }

    func testGlobalVariables() {
        let engine = KeyboardRemapEngine()
        engine.setGlobalVariable(name: "global", value: "value")
        XCTAssertEqual(engine.globalVariables["global"], "value")

        engine.unsetGlobalVariable(name: "global")
        XCTAssertNil(engine.globalVariables["global"])
    }

    func testLoadGlobalVariables() {
        let engine = KeyboardRemapEngine()
        engine.loadGlobalVariables(["k1": "v1", "k2": "v2"])
        XCTAssertEqual(engine.globalVariables["k1"], "v1")
        XCTAssertEqual(engine.globalVariables["k2"], "v2")
    }

    func testResetGlobalVariables() {
        let engine = KeyboardRemapEngine()
        engine.setGlobalVariable(name: "g", value: "v")
        engine.resetGlobalVariables()
        XCTAssertTrue(engine.globalVariables.isEmpty)
    }

    func testOnGlobalVariablesChange() {
        let engine = KeyboardRemapEngine()
        var changedVars: [String: String]?
        engine.onGlobalVariablesChange = { changedVars = $0 }

        engine.setGlobalVariable(name: "test", value: "value")

        // The callback fires asynchronously
        let expectation = XCTestExpectation(description: "variable change")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(changedVars?["test"], "value")
    }

    // MARK: - Named Clipboard

    func testNamedClipboard() {
        let engine = KeyboardRemapEngine()
        engine.setNamedClipboard(name: "clip", value: "content")
        XCTAssertEqual(engine.namedClipboards["clip"], "content")

        engine.unsetNamedClipboard(name: "clip")
        XCTAssertNil(engine.namedClipboards["clip"])
    }

    // MARK: - Sticky & Lazy Modifiers

    func testStickyModifier() {
        let engine = KeyboardRemapEngine()
        engine.setStickyModifier(.command, active: true)
        // Sticky modifier state is internal — we test set/get doesn't crash
    }

    func testToggleStickyModifier() {
        let engine = KeyboardRemapEngine()
        engine.toggleStickyModifier(.command)
        // No crash
    }

    func testSetLazyModifiers() {
        let engine = KeyboardRemapEngine()
        engine.setLazyModifiers([.command, .shift])
        // No crash
    }

    // MARK: - Stop

    func testStopEngine() {
        let engine = KeyboardRemapEngine()
        engine.apply([
            Manipulator(
                trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
                actions: [Action(toKey: "e")]
            )
        ])

        let expectation = XCTestExpectation(description: "apply and stop")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            engine.stop()
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        XCTAssertEqual(engine.state, .inactive, "Engine should be inactive after stop")
    }

    // MARK: - Multiple Apply Calls

    func testMultipleApplies() {
        let engine = KeyboardRemapEngine()

        let m1 = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )
        engine.apply([m1])

        let m2 = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "w")]),
            actions: [Action(toKey: "r")]
        )
        engine.apply([m1, m2])

        // Should not crash
        let expectation = XCTestExpectation(description: "multiple applies")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)

        if case .active = engine.state {
            XCTAssertTrue(true)
        } else {
            XCTFail("Engine should be active after apply")
        }
    }
}
