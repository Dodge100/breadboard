import XCTest
@testable import breadboard

final class ManipulatorModelTests: XCTestCase {

    // MARK: - Action COW

    func testActionCopyIsReferenceCopy() {
        let a = Action(toKey: "a")
        var b = a  // Copy — should share storage initially
        b.toKey = "b"  // Mutation triggers deep copy

        XCTAssertEqual(a.toKey, "a", "Original should be unchanged")
        XCTAssertEqual(b.toKey, "b", "Copy should have new value")
    }

    func testActionCopyDoesNotAffectOriginal() {
        let a = Action(kind: .sendText, fireMode: .onKeyDown, text: "hello")
        var b = a
        b.fireMode = .afterKeyUp
        b.text = "world"

        XCTAssertEqual(a.fireMode, .onKeyDown)
        XCTAssertEqual(a.text, "hello")
        XCTAssertEqual(b.fireMode, .afterKeyUp)
        XCTAssertEqual(b.text, "world")
    }

    func testActionDeepCopyHasNewID() {
        let a = Action(toKey: "a")
        let b = a.deepCopy()

        XCTAssertNotEqual(a.id, b.id, "deepCopy should generate a new ID")
        XCTAssertEqual(a.toKey, b.toKey, "Values should be equal")
    }

    func testActionDeepCopyIndependentMutation() {
        let a = Action(toKey: "a")
        var b = a.deepCopy()
        b.toKey = "b"

        XCTAssertEqual(a.toKey, "a")
        XCTAssertEqual(b.toKey, "b")
    }

    func testActionArrayCopyIsCOW() {
        var actions = [Action(toKey: "a"), Action(toKey: "b")]
        let copied = actions  // Array COW — shares element references

        // Mutate original
        actions[0].toKey = "changed"

        XCTAssertEqual(copied[0].toKey, "a", "Copied array should be unaffected")
        XCTAssertEqual(actions[0].toKey, "changed")
    }

    func testActionMultipleMutations() {
        var action = Action(kind: .sendKey, toKey: "a")

        action.toKey = "b"
        action.fireMode = .afterKeyUp
        action.isLazy = true
        action.tapCount = 3

        XCTAssertEqual(action.toKey, "b")
        XCTAssertEqual(action.fireMode, .afterKeyUp)
        XCTAssertTrue(action.isLazy)
        XCTAssertEqual(action.tapCount, 3)
    }

    // MARK: - Action Codable

    func testActionCodableRoundTrip() throws {
        let original = Action(
            kind: .sendKey,
            fireMode: .onKeyDown,
            toKey: "space",
            toModifiers: [.command, .shift],
            delaySeconds: 0.5,
            isLazy: true,
            tapCount: 2
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Action.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.kind, original.kind)
        XCTAssertEqual(decoded.toKey, original.toKey)
        XCTAssertEqual(decoded.toModifiers, original.toModifiers)
        XCTAssertEqual(decoded.isLazy, original.isLazy)
        XCTAssertEqual(decoded.tapCount, original.tapCount)
        XCTAssertEqual(decoded.delaySeconds, original.delaySeconds)
    }

    func testActionCodableAllKinds() throws {
        let kinds: [ActionKind] = [
            .sendKey, .sendText, .consumerKey, .pointingButton, .mouseKey,
            .stickyModifier, .halt, .holdDown, .selectInputSource, .setNotification,
            .fromEvent, .softwareFunction, .setVariable, .unsetVariable,
            .toggleVariable, .runShell, .openApp, .openURL, .runShortcut,
            .runAppleScript, .executeNamedTrigger, .sendUserCommand,
            .setGlobalVariable, .unsetGlobalVariable, .showPalette, .hidePalette,
            .getSelectedText, .setClipboard, .getClipboard, .clearClipboard,
            .activateApp, .hideApp, .unhideApp, .quitApp, .forceQuitApp,
            .activateLastApp, .windowAction, .lockScreen, .showDesktop,
            .missionControl, .toggleDarkMode, .setVolume, .muteSystem,
            .emptyTrash, .getBatteryState, .getIPAddress, .toggleHiddenFiles,
            .logOut, .restartSystem, .shutdownSystem, .speakText, .transformText,
            .calculateExpression, .incrementVariable, .decrementVariable,
            .appendClipboard, .pasteClipboard, .httpRequest, .openFile,
            .openFolder, .playSound, .flashScreen
        ]

        for kind in kinds {
            let action = Action(kind: kind)
            let data = try JSONEncoder().encode(action)
            let decoded = try JSONDecoder().decode(Action.self, from: data)
            XCTAssertEqual(decoded.kind, kind, "Round-trip failed for \(kind)")
            XCTAssertEqual(decoded.id, action.id)
        }
    }

    func testActionCodableWithOptionalFields() throws {
        let original = Action(
            kind: .consumerKey,
            consumerKey: .mute,
            isRepeatEnabled: false,
            windowActionKind: .maximize,
            numberValue: 42
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Action.self, from: data)

        XCTAssertEqual(decoded.consumerKey, .mute)
        XCTAssertEqual(decoded.windowActionKind, .maximize)
        XCTAssertEqual(decoded.numberValue, 42)
        XCTAssertEqual(decoded.isRepeatEnabled, false)
    }

    // MARK: - Manipulator Codable

    func testManipulatorCodableRoundTrip() throws {
        let original = Manipulator(
            name: "Test Remap",
            folder: "Browser",
            tags: ["test", "safari"],
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            conditions: [
                Condition(kind: .frontmostApp, op: .isEqual, target: "com.apple.Safari")
            ],
            actions: [
                Action(kind: .sendKey, toKey: "e", toModifiers: [.command])
            ]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Manipulator.self, from: data)

        XCTAssertEqual(decoded.id, original.id)
        XCTAssertEqual(decoded.name, original.name)
        XCTAssertEqual(decoded.trigger.steps.first?.key, original.trigger.steps.first?.key)
        XCTAssertEqual(decoded.conditions.count, original.conditions.count)
        XCTAssertEqual(decoded.actions.count, original.actions.count)
        XCTAssertEqual(decoded.actions[0].toKey, original.actions[0].toKey)
        XCTAssertEqual(decoded.tags, original.tags)
        XCTAssertEqual(decoded.folder, original.folder)
    }

    func testManipulatorCodableWithAdditionalTriggers() throws {
        let original = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "j")],
            additionalTriggers: [
                AdditionalTrigger(
                    trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "w")]),
                    conditions: [Condition(kind: .variable, op: .isEqual, target: "mode", value: "vim")]
                )
            ]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Manipulator.self, from: data)

        XCTAssertEqual(decoded.additionalTriggers.count, 1)
        XCTAssertEqual(decoded.additionalTriggers[0].trigger.steps.first?.key, "w")
        XCTAssertEqual(decoded.additionalTriggers[0].conditions[0].target, "mode")
    }

    func testManipulatorIsEnabledPreserved() throws {
        let original = Manipulator(
            isEnabled: false,
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(Manipulator.self, from: data)

        XCTAssertFalse(decoded.isEnabled)
    }

    // MARK: - Condition Codable

    func testConditionCodableRoundTrip() throws {
        let kinds: [ConditionKind] = [
            .frontmostApp, .frontmostAppName, .inputSource, .device,
            .variable, .globalVariable, .keyboardType, .deviceExists,
            .expression, .eventChanged, .window, .runningCondition,
            .token, .namedClipboard, .screen, .pixelCondition
        ]

        for kind in kinds {
            let original = Condition(
                kind: kind,
                op: .isEqual,
                target: "test_target",
                value: "test_value"
            )
            let data = try JSONEncoder().encode(original)
            let decoded = try JSONDecoder().decode(Condition.self, from: data)

            XCTAssertEqual(decoded.kind, kind)
            XCTAssertEqual(decoded.op, .isEqual)
            XCTAssertEqual(decoded.target, "test_target")
            XCTAssertEqual(decoded.value, "test_value")
            XCTAssertEqual(decoded.id, original.id)
        }
    }

    // MARK: - KeyShortcut

    func testKeyShortcutCodable() throws {
        let original = KeyShortcut(
            mandatoryModifiers: [.command, .shift],
            optionalModifiers: [.option],
            key: "a"
        )

        let data = try JSONEncoder().encode(original)
        let decoded = try JSONDecoder().decode(KeyShortcut.self, from: data)

        XCTAssertEqual(decoded.mandatoryModifiers, original.mandatoryModifiers)
        XCTAssertEqual(decoded.optionalModifiers, original.optionalModifiers)
        XCTAssertEqual(decoded.key, original.key)
    }

    // MARK: - HeldModifierMask

    func testHeldModifierMaskBasics() {
        typealias HM = KeyboardRemapEngine.HeldModifierMask
        var mask = HM()
        XCTAssertTrue(mask.isEmpty)

        mask.insert(HM.leftCommand)
        XCTAssertTrue(mask.contains(HM.leftCommand))
        XCTAssertFalse(mask.contains(HM.rightCommand))

        mask.insert(HM.leftShift)
        XCTAssertTrue(mask.contains(HM.leftShift))

        mask.remove(HM.leftCommand)
        XCTAssertFalse(mask.contains(HM.leftCommand))
        XCTAssertTrue(mask.contains(HM.leftShift))
    }

    func testHeldModifierMaskUnion() {
        typealias HM = KeyboardRemapEngine.HeldModifierMask
        let mask1: HM = [HM.leftCommand, HM.leftShift]
        let mask2: HM = [HM.leftCommand, HM.leftOption]

        let union = mask1.union(mask2)
        XCTAssertTrue(union.contains(HM.leftCommand))
        XCTAssertTrue(union.contains(HM.leftShift))
        XCTAssertTrue(union.contains(HM.leftOption))
    }

    func testHeldModifierMaskIntersection() {
        typealias HM = KeyboardRemapEngine.HeldModifierMask
        let mask1: HM = [HM.leftCommand, HM.leftShift]
        let mask2: HM = [HM.leftCommand, HM.leftOption]

        let intersection = mask1.intersection(mask2)
        XCTAssertTrue(intersection.contains(HM.leftCommand))
        XCTAssertFalse(intersection.contains(HM.leftShift))
        XCTAssertFalse(intersection.contains(HM.leftOption))
    }

    func testHeldModifierMaskBitsForModifier() {
        typealias HM = KeyboardRemapEngine.HeldModifierMask
        let cmdBits = HM.bits(for: .command)
        XCTAssertFalse(cmdBits.isEmpty)

        let bits = HM.bits(for: .command).union(
            HM.bits(for: .shift)
        )
        XCTAssertTrue(bits.contains(HM.leftCommand))
        XCTAssertTrue(bits.contains(HM.leftShift))
        XCTAssertFalse(bits.contains(HM.leftOption))
    }
}
