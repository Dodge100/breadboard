import XCTest
@testable import breadboard

final class RoutingCacheTests: XCTestCase {

    // MARK: - triggerGroups

    func testTriggerGroupsFromSingleTrigger() {
        let manip = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            conditions: [Condition(kind: .frontmostApp, op: .isEqual, target: "com.apple.Safari")],
            actions: [Action(toKey: "e")]
        )
        let groups = KeyboardRemapEngine.RoutingCache.triggerGroups(for: manip)
        XCTAssertEqual(groups.count, 1)
        XCTAssertEqual(groups[0].groupIndex, 0)
        XCTAssertEqual(groups[0].trigger.keyType, .keyboard)
        XCTAssertEqual(groups[0].conditions.count, 1)
    }

    func testTriggerGroupsWithAdditionalTriggers() {
        let manip = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")],
            additionalTriggers: [
                AdditionalTrigger(trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "w")]))
            ]
        )
        let groups = KeyboardRemapEngine.RoutingCache.triggerGroups(for: manip)
        XCTAssertEqual(groups.count, 2) // main + 1 additional
        XCTAssertEqual(groups[0].groupIndex, 0)
        XCTAssertEqual(groups[1].groupIndex, 1)
        XCTAssertEqual(groups[1].trigger.steps.first?.key, "w")
    }

    // MARK: - insert / remove

    func testInsertBasicManipulator() {
        let manip = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )
        var cache = KeyboardRemapEngine.RoutingCache()
        cache.manipulatorCache[manip.id] = manip
        cache.insert(manipulator: manip)

        XCTAssertEqual(cache.all.count, 1)
        XCTAssertEqual(cache.keyboard.count, 1)
        XCTAssertEqual(cache.pointing.count, 0)
        XCTAssertEqual(cache.hotKeys.count, 0)
        XCTAssertEqual(cache.simultaneous.count, 0)
        XCTAssertEqual(cache.stringTriggers.count, 0)
        XCTAssertEqual(cache.consumer.count, 0)
        XCTAssertEqual(cache.mouseMotionToScroll.count, 0)

        XCTAssertEqual(cache.all[0].manipulatorID, manip.id)
    }

    func testInsertDisabledManipulator() {
        let manip = Manipulator(
            isEnabled: false,
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )
        var cache = KeyboardRemapEngine.RoutingCache()
        cache.manipulatorCache[manip.id] = manip
        cache.insert(manipulator: manip)

        XCTAssertEqual(cache.all.count, 0, "Disabled manipulator should not be inserted")
    }

    func testInsertPointingManipulator() {
        let manip = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "left")], keyType: .pointing),
            actions: [Action(kind: .pointingButton, pointingButton: .left)]
        )
        var cache = KeyboardRemapEngine.RoutingCache()
        cache.manipulatorCache[manip.id] = manip
        cache.insert(manipulator: manip)

        XCTAssertEqual(cache.keyboard.count, 0)
        XCTAssertEqual(cache.pointing.count, 1)
    }

    func testInsertMouseBasicManipulator() {
        let manip = Manipulator(
            manipulatorType: .mouseBasic,
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )
        var cache = KeyboardRemapEngine.RoutingCache()
        cache.manipulatorCache[manip.id] = manip
        cache.insert(manipulator: manip)

        XCTAssertEqual(cache.all.count, 1)
        XCTAssertEqual(cache.keyboard.count, 0)
        XCTAssertEqual(cache.pointing.count, 1)
    }

    func testInsertMouseMotionToScroll() {
        let manip = Manipulator(
            manipulatorType: .mouseMotionToScroll,
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(kind: .mouseKey)]
        )
        var cache = KeyboardRemapEngine.RoutingCache()
        cache.manipulatorCache[manip.id] = manip
        cache.insert(manipulator: manip)

        XCTAssertEqual(cache.mouseMotionToScroll.count, 1)
    }

    func testInsertHotKey() {
        let trigger = ManipulatorTrigger(
            steps: [KeyShortcut(key: "q")],
            hotKey: HotKeyTriggerConfig(tapCount: 2, holdRequired: false)
        )
        let manip = Manipulator(
            trigger: trigger,
            actions: [Action(toKey: "e")]
        )
        var cache = KeyboardRemapEngine.RoutingCache()
        cache.manipulatorCache[manip.id] = manip
        cache.insert(manipulator: manip)

        XCTAssertEqual(cache.hotKeys.count, 1)
        XCTAssertEqual(cache.keyboard.count, 1) // Also in keyboard
    }

    func testInsertSimultaneous() {
        let trigger = ManipulatorTrigger(
            simultaneous: SimultaneousTrigger(keys: [KeyShortcut(key: "a"), KeyShortcut(key: "b")])
        )
        let manip = Manipulator(
            trigger: trigger,
            actions: [Action(toKey: "c")]
        )
        var cache = KeyboardRemapEngine.RoutingCache()
        cache.manipulatorCache[manip.id] = manip
        cache.insert(manipulator: manip)

        XCTAssertEqual(cache.simultaneous.count, 1)
        XCTAssertEqual(cache.keyboard.count, 0)
    }

    func testInsertStringTrigger() {
        let trigger = ManipulatorTrigger(
            stringTrigger: StringTriggerOptions(string: "omw")
        )
        let manip = Manipulator(
            trigger: trigger,
            actions: [Action(kind: .sendText, text: "on my way!")]
        )
        var cache = KeyboardRemapEngine.RoutingCache()
        cache.manipulatorCache[manip.id] = manip
        cache.insert(manipulator: manip)

        XCTAssertEqual(cache.stringTriggers.count, 1)
        XCTAssertEqual(cache.keyboard.count, 0)
        XCTAssertEqual(cache.all.count, 0) // eventGroups only, not string
    }

    func testInsertConsumerKey() {
        let manip = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "mute")], keyType: .consumer),
            actions: [Action(kind: .consumerKey, consumerKey: .mute)]
        )
        var cache = KeyboardRemapEngine.RoutingCache()
        cache.manipulatorCache[manip.id] = manip
        cache.insert(manipulator: manip)

        XCTAssertEqual(cache.consumer.count, 1)
        XCTAssertEqual(cache.keyboard.count, 0)
    }

    func testRemoveAllRoutes() {
        let manip = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )
        var cache = KeyboardRemapEngine.RoutingCache()
        cache.manipulatorCache[manip.id] = manip
        cache.insert(manipulator: manip)

        XCTAssertEqual(cache.all.count, 1)

        cache.remove(manipulatorID: manip.id)
        XCTAssertEqual(cache.all.count, 0)
        XCTAssertEqual(cache.keyboard.count, 0)
    }

    // MARK: - build

    func testBuildFromEmpty() {
        let cache = KeyboardRemapEngine.RoutingCache.build(from: [])
        XCTAssertEqual(cache.all.count, 0)
        XCTAssertEqual(cache.manipulatorCache.count, 0)
    }

    func testBuildFromMultipleManipulators() {
        let m1 = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )
        let m2 = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "left")], keyType: .pointing),
            actions: [Action(kind: .pointingButton, pointingButton: .left)]
        )
        let m3 = Manipulator(
            manipulatorType: .mouseMotionToScroll,
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(kind: .mouseKey)]
        )

        let cache = KeyboardRemapEngine.RoutingCache.build(from: [m1, m2, m3])

        XCTAssertEqual(cache.all.count, 2) // m1 and m2 (eventGroups), m3 is .mouseMotionToScroll only
        XCTAssertEqual(cache.keyboard.count, 1)
        XCTAssertEqual(cache.pointing.count, 1)
        XCTAssertEqual(cache.mouseMotionToScroll.count, 1)
        XCTAssertEqual(cache.manipulatorCache.count, 3)
    }

    // MARK: - hasRoutingRelevantChange

    func testHasRoutingRelevantChangeEnabled() {
        let old = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )
        var changed = old
        changed.isEnabled = false

        XCTAssertTrue(KeyboardRemapEngine.RoutingCache.hasRoutingRelevantChange(old, changed))
    }

    func testHasRoutingRelevantChangeTrigger() {
        let old = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )
        var changed = old
        changed.trigger = ManipulatorTrigger(steps: [KeyShortcut(key: "w")])

        XCTAssertTrue(KeyboardRemapEngine.RoutingCache.hasRoutingRelevantChange(old, changed))
    }

    func testHasRoutingRelevantChangeActions() {
        let old = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )
        var changed = old
        changed.actions[0].toKey = "f"

        XCTAssertTrue(KeyboardRemapEngine.RoutingCache.hasRoutingRelevantChange(old, changed))
    }

    func testHasRoutingRelevantChangeConditions() {
        let old = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            conditions: [Condition(kind: .frontmostApp, op: .isEqual, target: "com.apple.Safari")],
            actions: [Action(toKey: "e")]
        )
        var changed = old
        changed.conditions[0].target = "com.apple.Finder"

        XCTAssertTrue(KeyboardRemapEngine.RoutingCache.hasRoutingRelevantChange(old, changed))
    }

    func testHasRoutingRelevantChangeType() {
        let old = Manipulator(
            manipulatorType: .basic,
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )
        var changed = old
        changed.manipulatorType = .mouseBasic

        XCTAssertTrue(KeyboardRemapEngine.RoutingCache.hasRoutingRelevantChange(old, changed))
    }

    func testHasRoutingRelevantChangeNameOnly() {
        let old = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )
        var changed = old
        changed.name = "New Name"
        changed.notes = "some notes"
        changed.folder = "folder"
        changed.tags = ["tag1"]

        XCTAssertFalse(KeyboardRemapEngine.RoutingCache.hasRoutingRelevantChange(old, changed),
                       "Name, notes, folder, tags should NOT trigger a rebuild")
    }

    func testHasRoutingRelevantChangeAdditionalTriggers() {
        let old = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )
        var changed = old
        changed.additionalTriggers = [
            AdditionalTrigger(trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "w")]))
        ]

        XCTAssertTrue(KeyboardRemapEngine.RoutingCache.hasRoutingRelevantChange(old, changed))
    }

    func testHasRoutingRelevantChangeParameters() {
        let old = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )
        var changed = old
        changed.parameters.toIfAloneTimeoutMilliseconds = 500

        XCTAssertTrue(KeyboardRemapEngine.RoutingCache.hasRoutingRelevantChange(old, changed))
    }

    // MARK: - diffUpdate

    func testDiffUpdateAdd() {
        let m1 = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )
        let oldCache = KeyboardRemapEngine.RoutingCache.build(from: [m1])

        let m2 = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "w")]),
            actions: [Action(toKey: "r")]
        )

        let newCache = KeyboardRemapEngine.RoutingCache.diffUpdate(
            from: [m1, m2],
            oldCache: oldCache,
            oldManipulators: [m1]
        )

        XCTAssertEqual(newCache.all.count, 2)
        XCTAssertEqual(newCache.manipulatorCache.count, 2)
        XCTAssertNotNil(newCache.manipulator(for: m2.id))
    }

    func testDiffUpdateRemove() {
        let m1 = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )
        let m2 = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "w")]),
            actions: [Action(toKey: "r")]
        )
        let oldCache = KeyboardRemapEngine.RoutingCache.build(from: [m1, m2])

        let newCache = KeyboardRemapEngine.RoutingCache.diffUpdate(
            from: [m1],
            oldCache: oldCache,
            oldManipulators: [m1, m2]
        )

        XCTAssertEqual(newCache.all.count, 1)
        XCTAssertEqual(newCache.manipulatorCache.count, 1)
        XCTAssertNil(newCache.manipulator(for: m2.id))
    }

    func testDiffUpdateNameChangeIsNoOp() {
        let m1 = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )
        let oldCache = KeyboardRemapEngine.RoutingCache.build(from: [m1])

        var renamed = m1
        renamed.name = "Renamed"

        let newCache = KeyboardRemapEngine.RoutingCache.diffUpdate(
            from: [renamed],
            oldCache: oldCache,
            oldManipulators: [m1]
        )

        // The cache should have the UPDATED manipulator (with new name)
        // but the ROUTE should remain the same
        XCTAssertEqual(newCache.all.count, 1, "Route count should stay the same")
        XCTAssertEqual(newCache.manipulatorCache[m1.id]?.name, "Renamed",
                       "Name should be updated in cache")
    }

    func testDiffUpdateTriggerChangeRebuilds() {
        let m1 = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )
        let oldCache = KeyboardRemapEngine.RoutingCache.build(from: [m1])

        var changed = m1
        changed.trigger = ManipulatorTrigger(steps: [KeyShortcut(key: "z")])

        let newCache = KeyboardRemapEngine.RoutingCache.diffUpdate(
            from: [changed],
            oldCache: oldCache,
            oldManipulators: [m1]
        )

        XCTAssertEqual(newCache.all.count, 1, "Route should exist")
        XCTAssertNotNil(newCache.manipulator(for: m1.id))
    }

    func testDiffUpdateDisableRemovesRoute() {
        let m1 = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )
        let oldCache = KeyboardRemapEngine.RoutingCache.build(from: [m1])

        var disabled = m1
        disabled.isEnabled = false

        let newCache = KeyboardRemapEngine.RoutingCache.diffUpdate(
            from: [disabled],
            oldCache: oldCache,
            oldManipulators: [m1]
        )

        XCTAssertEqual(newCache.all.count, 0, "Disabled manipulator should have no route")
        XCTAssertEqual(newCache.manipulatorCache.count, 1, "Cache should still have the manipulator data")
    }

    // MARK: - subscript access

    func testSubscriptAccess() {
        let manip = Manipulator(
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(toKey: "e")]
        )
        var cache = KeyboardRemapEngine.RoutingCache()
        cache.manipulatorCache[manip.id] = manip
        cache.insert(manipulator: manip)

        let route = cache.all[0]
        let retrieved = cache[route]
        XCTAssertEqual(retrieved.id, manip.id)
        XCTAssertEqual(retrieved.trigger.steps.first?.key, "q")
    }

    // MARK: - needsMouseMoved

    func testNeedsMouseMoved() {
        let empty = KeyboardRemapEngine.RoutingCache()
        XCTAssertFalse(empty.needsMouseMoved)

        let manip = Manipulator(
            manipulatorType: .mouseMotionToScroll,
            trigger: ManipulatorTrigger(steps: [KeyShortcut(key: "q")]),
            actions: [Action(kind: .mouseKey)]
        )
        let cache = KeyboardRemapEngine.RoutingCache.build(from: [manip])
        XCTAssertTrue(cache.needsMouseMoved)
    }
}
