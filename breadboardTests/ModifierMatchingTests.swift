import XCTest
@testable import breadboard
import Carbon.HIToolbox

final class ModifierMatchingTests: XCTestCase {

    /// Helper to create CGEventFlags from an array of ModifierKey.
    private func flags(_ mods: Set<ModifierKey>) -> CGEventFlags {
        var result = CGEventFlags()
        for mod in mods {
            if let cgFlag = mod.cgFlag {
                result.insert(cgFlag)
            }
        }
        return result
    }

    func testEmptyModifiersMatch() {
        let engine = KeyboardRemapEngine()
        let shortcut = KeyShortcut(mandatoryModifiers: [], key: "a")
        XCTAssertTrue(engine.modifiersMatch(shortcut, flags: []))
        XCTAssertTrue(engine.modifiersMatch(shortcut, flags: flags([.command])),
                      "Optional modifiers without mandatory should match")
    }

    func testMandatoryModifierMustBePresent() {
        let engine = KeyboardRemapEngine()
        let shortcut = KeyShortcut(mandatoryModifiers: [.command], key: "a")

        XCTAssertTrue(engine.modifiersMatch(shortcut, flags: flags([.command])))
        XCTAssertFalse(engine.modifiersMatch(shortcut, flags: []))
    }

    func testExtraModifiersBlockMatch() {
        let engine = KeyboardRemapEngine()
        let shortcut = KeyShortcut(mandatoryModifiers: [.command], key: "a")

        // Extra shift should block
        XCTAssertFalse(engine.modifiersMatch(shortcut, flags: flags([.command, .shift])))
    }

    func testOptionalModifierDoesNotBlock() {
        let engine = KeyboardRemapEngine()
        let shortcut = KeyShortcut(
            mandatoryModifiers: [.command],
            optionalModifiers: [.shift],
            key: "a"
        )

        // Both mandatory + optional present = match
        XCTAssertTrue(engine.modifiersMatch(shortcut, flags: flags([.command, .shift])))
        // Only mandatory = match (optional is optional)
        XCTAssertTrue(engine.modifiersMatch(shortcut, flags: flags([.command])))
    }

    func testFnAndAlphaShiftIgnored() {
        let engine = KeyboardRemapEngine()
        let shortcut = KeyShortcut(mandatoryModifiers: [.command], key: "a")

        // CGEventFlags with .maskNonCoalesced (bit 12) should be ignored
        var flagsWithExtras: CGEventFlags = [.maskCommand]
        flagsWithExtras.insert(CGEventFlags(rawValue: 1 << 12)) // maskNonCoalesced

        XCTAssertTrue(engine.modifiersMatch(shortcut, flags: flagsWithExtras),
                      "Non-coalesced bit should be ignored")
    }

    func testMultipleMandatoryModifiers() {
        let engine = KeyboardRemapEngine()
        let shortcut = KeyShortcut(
            mandatoryModifiers: [.command, .shift],
            key: "a"
        )

        XCTAssertTrue(engine.modifiersMatch(shortcut, flags: flags([.command, .shift])))
        XCTAssertFalse(engine.modifiersMatch(shortcut, flags: flags([.command])))
        XCTAssertFalse(engine.modifiersMatch(shortcut, flags: flags([.shift])))
    }

    func testModifierKeyTriggerExemptsSelf() {
        let engine = KeyboardRemapEngine()
        // When remapping a modifier key itself (e.g. command → something),
        // pressing command sets maskCommand — that should be allowed.
        let shortcut = KeyShortcut(mandatoryModifiers: [], key: "left_command")

        // Even though no mandatory modifiers, pressing only command should match
        // because the trigger IS a modifier key
        let matchResult = engine.modifiersMatch(shortcut, flags: flags([.command]))
        // With mandatory=[], it's an "optional modifier" check — maskCommand is allowed
        // because the trigger key is a modifier key (exempt from extra-flags check)
        XCTAssertTrue(matchResult)
    }
}
