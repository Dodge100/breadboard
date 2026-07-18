import SwiftUI

struct ManipulatorEditorView: View {
    @ObservedObject var store: RemapStore
    let manipulator: Manipulator

    var body: some View {
        listContent
    }

    // MARK: - List Layout (existing)

    private var listContent: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                headerSection
                triggerSection
                conditionsSection
                actionsSection
                additionalTriggersSection
                parametersSection
                notesSection
                deleteButton
            }
            .padding(20)
            .frame(maxWidth: 720, alignment: .leading)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }



    // MARK: - Sections

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                TextField("Manipulator name", text: nameBinding)
                    .font(.title2.weight(.semibold))
                    .textFieldStyle(.plain)
                Spacer()
                Toggle("Enabled", isOn: enabledBinding)
                    .toggleStyle(.switch)
                    .labelsHidden()
            }
            HStack {
                TextField("Folder", text: folderBinding)
                    .font(.body)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: 200)
                Text("(optional grouping)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }
            TagEditorField(store: store, manipulator: manipulator)
        }
    }

    private var triggerSection: some View {
        StepCard(title: "Trigger") {
            VStack(alignment: .leading, spacing: 10) {
                Picker("Type", selection: manipulatorTypeBinding) {
                    ForEach(ManipulatorType.allCases) { type in
                        Text(type.rawValue).tag(type)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)

                if manipulator.manipulatorType == .mouseMotionToScroll {
                    Text("Converts mouse movement into scroll events. Configure speed in Parameters.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if manipulator.manipulatorType == .mouseBasic {
                    Text("Remaps mouse buttons. Set the trigger to a pointing button.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if manipulator.manipulatorType == .basic || manipulator.manipulatorType == .mouseBasic {
                    Divider()

                    Picker("Trigger type", selection: triggerTypeBinding) {
                        ForEach(TriggerKeyType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .labelsHidden()
                    .pickerStyle(.segmented)

                    TextField("Named trigger (optional)", text: triggerNameBinding)
                        .textFieldStyle(.roundedBorder)
                        .font(.system(.body, design: .monospaced))
                        .help("If set, this manipulator can be triggered by name from another manipulator's 'Execute Named Trigger' action.")

                    switch manipulator.trigger.keyType {
                    case .keyboard:
                        keyboardTriggerEditor
                    case .consumer:
                        consumerTriggerEditor
                    case .pointing:
                        pointingTriggerEditor
                    case .typedString:
                        typedStringTriggerEditor
                    case .any:
                        Text("Matches any key press. Use conditions to narrow the context.")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var keyboardTriggerEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(store.isRecordingTrigger
                 ? "Press the keys in order, then click Done."
                 : "Record any key combination or sequence you want to trigger this manipulator.")
                .font(.caption)
                .foregroundStyle(.secondary)

            if let simultaneous = manipulator.trigger.simultaneous, simultaneous.isValid {
                Text("Chord: \(simultaneous.keys.map(\.displayLabel).joined(separator: " + "))")
                    .font(.system(.body, design: .monospaced))
                Button("Clear chord") {
                    store.updateManipulator(manipulator.id) { $0.trigger.simultaneous = nil }
                }
                .buttonStyle(.borderless)
            }

            HStack(spacing: 8) {
                if store.isRecordingTrigger {
                    ForEach(Array(store.recordedTriggerSteps.enumerated()), id: \.offset) { index, step in
                        TriggerStepBadge(step: step) {
                            store.removeRecordedTriggerStep(at: index)
                        }
                    }
                } else {
                    if manipulator.trigger.steps.isEmpty {
                        Text("Not recorded")
                            .foregroundStyle(.secondary)
                            .font(.system(.body, design: .monospaced))
                    } else {
                        ForEach(Array(manipulator.trigger.steps.enumerated()), id: \.offset) { index, step in
                            TriggerStepBadge(step: step) {
                                store.removeTriggerStep(at: index, from: manipulator.id)
                            }
                        }
                    }
                }
                Spacer()
            }

            HStack(spacing: 12) {
                if store.isRecordingTrigger {
                    Button(role: .destructive) {
                        store.stopTriggerRecording(save: false)
                    } label: {
                        Text("Cancel")
                    }
                    Spacer()
                    Button {
                        store.stopTriggerRecording(save: true)
                    } label: {
                        Text("Done")
                    }
                    .buttonStyle(.borderedProminent)
                } else {
                    Button {
                        store.startTriggerRecording(for: manipulator.id)
                    } label: {
                        Text(manipulator.trigger.steps.isEmpty ? "Record Trigger" : "Re-record")
                    }
                    if !manipulator.trigger.steps.isEmpty {
                        Button(role: .destructive) {
                            store.updateManipulator(manipulator.id) { $0.trigger.steps.removeAll() }
                        } label: {
                            Text("Clear")
                        }
                    }
                }
            }

            // Modifier info for selected step
            if let firstStep = manipulator.trigger.steps.first, !firstStep.key.isEmpty {
                Divider()
                VStack(alignment: .leading, spacing: 6) {
                    Text("Modifier matching")
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                    HStack(spacing: 8) {
                        Text("Mandatory:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        modifierChips(for: firstStep.mandatoryModifiers) { mods in
                            store.updateManipulator(manipulator.id) {
                                guard $0.trigger.steps.indices.contains(0) else { return }
                                $0.trigger.steps[0].mandatoryModifiers = mods
                            }
                        }
                    }
                    HStack(spacing: 8) {
                        Text("Optional:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        modifierChips(for: firstStep.optionalModifiers) { mods in
                            store.updateManipulator(manipulator.id) {
                                guard $0.trigger.steps.indices.contains(0) else { return }
                                $0.trigger.steps[0].optionalModifiers = mods
                            }
                        }
                    }
                }
            }

            // Simultaneous chord trigger
            if manipulator.trigger.steps.isEmpty {
                Divider()
                Button("Add simultaneous (chord) trigger") {
                    store.updateManipulator(manipulator.id) {
                        $0.trigger.simultaneous = SimultaneousTrigger(keys: [])
                    }
                }
                .buttonStyle(.borderless)
                .font(.caption)
            }

            // Hot Key multi-tap / hold configuration
            if !manipulator.trigger.steps.isEmpty || manipulator.trigger.anyKey {
                hotKeyTriggerEditor
            }

        }
    }

    private func modifierChips(for selected: Set<ModifierKey>, onChange: @escaping (Set<ModifierKey>) -> Void) -> some View {
        HStack(spacing: 4) {
            ForEach(ModifierKey.flagBased, id: \.self) { mod in
                Button {
                    var newSet = selected
                    if newSet.contains(mod) {
                        newSet.remove(mod)
                    } else {
                        newSet.insert(mod)
                    }
                    onChange(newSet)
                } label: {
                    Text(mod.symbol)
                        .font(.caption)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(selected.contains(mod) ? Color.accentColor.opacity(0.2) : Color.gray.opacity(0.1))
                        .cornerRadius(4)
                }
                .buttonStyle(.plain)
            }
        }
    }

    // MARK: - Hot Key trigger configuration

    @ViewBuilder
    private var hotKeyTriggerEditor: some View {
        Divider()
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 6) {
                Text("Hot Key Behavior")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Toggle("Enabled", isOn: hotKeyEnabledBinding)
                    .toggleStyle(.switch)
                    .controlSize(.small)
                    .labelsHidden()
            }

            if manipulator.trigger.hotKey != nil {
                VStack(alignment: .leading, spacing: 10) {
                    // Tap count
                    HStack(spacing: 8) {
                        Text("Tap count:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .trailing)
                        Stepper(value: hotKeyTapCountBinding, in: 1...5) {
                            Text("\(manipulator.trigger.hotKey?.tapCount ?? 2)")
                                .font(.system(.body, design: .monospaced))
                                .frame(minWidth: 24)
                        }
                        .controlSize(.small)
                        Text("taps\(manipulator.trigger.hotKey?.tapCount ?? 2 > 1 ? " (multi-tap)" : " (single)")")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Tap timeout
                    HStack(spacing: 8) {
                        Text("Timeout:")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(width: 80, alignment: .trailing)
                        TextField("ms", value: hotKeyTimeoutBinding, formatter: NumberFormatter())
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 70)
                            .font(.system(.body, design: .monospaced))
                        Text("ms between taps")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    // Hold required toggle
                    Toggle(isOn: hotKeyHoldRequiredBinding) {
                        Text("Require final tap to be held")
                            .font(.caption)
                    }
                    .toggleStyle(.switch)
                    .controlSize(.small)

                    if manipulator.trigger.hotKey?.holdRequired == true {
                        HStack(spacing: 8) {
                            Text("Hold duration:")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(width: 80, alignment: .trailing)
                            TextField("ms", value: hotKeyHoldThresholdBinding, formatter: NumberFormatter())
                                .textFieldStyle(.roundedBorder)
                                .frame(width: 70)
                                .font(.system(.body, design: .monospaced))
                            Text("ms")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .padding(.leading, 20)
            }
        }
        .padding(.vertical, 4)
    }

    // MARK: - Hot Key Bindings

    private var hotKeyEnabledBinding: Binding<Bool> {
        Binding(
            get: { manipulator.trigger.hotKey != nil },
            set: { newValue in
                store.updateManipulator(manipulator.id) {
                    if newValue {
                        $0.trigger.hotKey = HotKeyTriggerConfig(
                            tapCount: 2,
                            tapTimeoutMilliseconds: 400,
                            holdRequired: false,
                            holdThresholdMilliseconds: 500
                        )
                    } else {
                        $0.trigger.hotKey = nil
                    }
                }
            }
        )
    }

    private var hotKeyTapCountBinding: Binding<Int> {
        Binding(
            get: { manipulator.trigger.hotKey?.tapCount ?? 2 },
            set: { newValue in
                store.updateManipulator(manipulator.id) {
                    if $0.trigger.hotKey != nil {
                        $0.trigger.hotKey?.tapCount = max(1, min(newValue, 5))
                    }
                }
            }
        )
    }

    private var hotKeyTimeoutBinding: Binding<Int> {
        Binding(
            get: { manipulator.trigger.hotKey?.tapTimeoutMilliseconds ?? 400 },
            set: { newValue in
                store.updateManipulator(manipulator.id) {
                    $0.trigger.hotKey?.tapTimeoutMilliseconds = max(50, newValue)
                }
            }
        )
    }

    private var hotKeyHoldRequiredBinding: Binding<Bool> {
        Binding(
            get: { manipulator.trigger.hotKey?.holdRequired ?? false },
            set: { newValue in
                store.updateManipulator(manipulator.id) {
                    $0.trigger.hotKey?.holdRequired = newValue
                }
            }
        )
    }

    private var hotKeyHoldThresholdBinding: Binding<Int> {
        Binding(
            get: { manipulator.trigger.hotKey?.holdThresholdMilliseconds ?? 500 },
            set: { newValue in
                store.updateManipulator(manipulator.id) {
                    $0.trigger.hotKey?.holdThresholdMilliseconds = max(100, newValue)
                }
            }
        )
    }

    @ViewBuilder
    private var consumerTriggerEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select a media/consumer key to trigger this manipulator.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Consumer key", selection: consumerKeyBinding) {
                Text("Select...").tag("")
                ForEach(ConsumerKeyCode.allCases) { key in
                    Text(key.label).tag(key.rawValue)
                }
            }
            .labelsHidden()
        }
    }

    @ViewBuilder
    private var pointingTriggerEditor: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Select a mouse button to trigger this manipulator.")
                .font(.caption)
                .foregroundStyle(.secondary)

            Picker("Mouse button", selection: pointingButtonBinding) {
                Text("Select...").tag("")
                ForEach(PointingButton.allCases) { btn in
                    Text(btn.label).tag(btn.rawValue)
                }
            }
            .labelsHidden()
        }
    }

    private var typedStringTriggerEditor: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Type a string to match. When the typed text matches, the manipulator fires.")
                .font(.caption)
                .foregroundStyle(.secondary)

            // Target string
            HStack {
                Text("Match string:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 100, alignment: .trailing)
                TextField("e.g. teh", text: typedStringBinding)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))
            }

            // Match mode picker
            HStack {
                Text("Match mode:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 100, alignment: .trailing)
                Picker("Match mode", selection: typedStringMatchModeBinding) {
                    ForEach(StringTriggerMatchMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .labelsHidden()
                .pickerStyle(.segmented)
            }

            // Clear on match toggle
            Toggle(isOn: typedStringClearOnMatchBinding) {
                Text("Clear buffer after match")
                    .font(.caption)
            }

            // App-specific scope
            HStack {
                Text("App scope:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 100, alignment: .trailing)
                TextField("com.apple.Safari (leave empty for all apps)", text: typedStringAppBinding)
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.caption, design: .monospaced))
                    .foregroundStyle(.secondary)
            }

            // Timeout slider
            HStack {
                Text("Timeout:")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(width: 100, alignment: .trailing)
                Slider(value: typedStringTimeoutBinding, in: 0.5...10, step: 0.5)
                    .frame(maxWidth: 200)
                Text(String(format: "%.1fs", manipulator.trigger.stringTrigger?.timeoutSeconds ?? 2.0))
                    .font(.caption.monospaced())
                    .foregroundStyle(.secondary)
                    .frame(width: 40, alignment: .trailing)
                Text("inactivity clears the buffer")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }

            // Help text for selected match mode
            Text(stringTriggerHelpText)
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .padding(.top, 2)
        }
    }

    /// Returns the help text for the currently selected string trigger match mode.
    private var stringTriggerHelpText: String {
        manipulator.trigger.stringTrigger?.matchMode.helpText
            ?? StringTriggerMatchMode.fullMatch.helpText
    }

    @ViewBuilder
    private var conditionsSection: some View {
        StepCard(title: "Only if") {
            VStack(alignment: .leading, spacing: 8) {
                if manipulator.conditions.isEmpty {
                    Text("No conditions. This manipulator will fire in any context.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(manipulator.conditions) { condition in
                        ConditionStepRow(
                            condition: condition,
                            onChange: { transform in
                                store.updateCondition(condition.id, in: manipulator.id, transform)
                            },
                            onDelete: {
                                store.removeCondition(condition.id, from: manipulator.id)
                            }
                        )
                    }
                }
                AddStepMenu(
                    label: "Add condition",
                    items: ConditionKind.allCases.map { kind in
                        AddStepMenu.Item(id: kind.rawValue, title: kind.rawValue)
                    },
                    action: { item in
                        let kind = ConditionKind(rawValue: item.id) ?? .frontmostApp
                        store.updateManipulator(manipulator.id) { manipulator in
                            var condition = Condition()
                            condition.kind = kind
                            manipulator.conditions.append(condition)
                        }
                    }
                )
            }
        }
    }

    @ViewBuilder
    private var actionsSection: some View {
        StepCard(title: "Do") {
            VStack(alignment: .leading, spacing: 8) {
                if manipulator.actions.isEmpty {
                    Text("No actions. Add one to make this manipulator do something.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(manipulator.actions) { action in
                        ActionStepRow(
                            store: store,
                            action: action,
                            onChange: { transform in
                                store.updateAction(action.id, in: manipulator.id, transform)
                            },
                            onDelete: {
                                store.removeAction(action.id, from: manipulator.id)
                            }
                        )
                    }
                }
                AddStepMenu(
                    label: "Add action",
                    items: ActionKind.allCases.map { kind in
                        AddStepMenu.Item(id: kind.rawValue, title: kind.rawValue)
                    },
                    action: { item in
                        let kind = ActionKind(rawValue: item.id) ?? .sendKey
                        store.updateManipulator(manipulator.id) { $0.actions.append(Action(kind: kind)) }
                    }
                )
            }
        }
    }

    // MARK: - Additional Triggers Section

    private var additionalTriggersSection: some View {
        StepCard(title: "Additional Triggers") {
            VStack(alignment: .leading, spacing: 12) {
                ForEach(manipulator.additionalTriggers) { trigger in
                    AdditionalTriggerCard(
                        store: store,
                        manipulator: manipulator,
                        trigger: trigger
                    )
                }
                Button {
                    store.addAdditionalTrigger(to: manipulator.id)
                } label: {
                    Text("Add Another Trigger").font(.body)
                }
                .buttonStyle(.borderless)
            }
        }
    }

    private var parametersSection: some View {
        StepCard(title: "Parameters") {
            ManipulatorParametersEditor(
                parameters: manipulator.parameters,
                onChange: { newParams in
                    store.updateManipulator(manipulator.id) { $0.parameters = newParams }
                }
            )
        }
    }

    private var notesSection: some View {
        StepCard(title: "Description") {
            TextField("Optional notes for this manipulator", text: notesBinding, axis: .vertical)
                .lineLimit(2...6)
                .textFieldStyle(.roundedBorder)
                .font(.body)
        }
    }

    private var deleteButton: some View {
        HStack {
            Spacer()
            Button(role: .destructive) {
                store.deleteManipulator(manipulator.id)
            } label: {
                Text("Delete Manipulator")
            }
            .buttonStyle(.borderless)
        }
    }

    // MARK: - Bindings

    private var nameBinding: Binding<String> {
        Binding(
            get: { manipulator.name },
            set: { newValue in store.updateManipulator(manipulator.id) { $0.name = newValue } }
        )
    }

    private var enabledBinding: Binding<Bool> {
        Binding(
            get: { manipulator.isEnabled },
            set: { newValue in store.updateManipulator(manipulator.id) { $0.isEnabled = newValue } }
        )
    }

    private var folderBinding: Binding<String> {
        Binding(
            get: { manipulator.folder },
            set: { newValue in store.updateManipulator(manipulator.id) { $0.folder = newValue } }
        )
    }

    private var notesBinding: Binding<String> {
        Binding(
            get: { manipulator.notes },
            set: { newValue in store.updateManipulator(manipulator.id) { $0.notes = newValue } }
        )
    }

    private var manipulatorTypeBinding: Binding<ManipulatorType> {
        Binding(
            get: { manipulator.manipulatorType },
            set: { newValue in
                store.updateManipulator(manipulator.id) { $0.manipulatorType = newValue
                    if newValue == .mouseBasic {
                        $0.trigger.keyType = .pointing
                    }
                }
            }
        )
    }

    private var triggerNameBinding: Binding<String> {
        Binding(
            get: { manipulator.trigger.triggerName },
            set: { newValue in
                store.updateManipulator(manipulator.id) { $0.trigger.triggerName = newValue }
            }
        )
    }

    private var triggerTypeBinding: Binding<TriggerKeyType> {
        Binding(
            get: { manipulator.trigger.keyType },
            set: { newValue in
                store.updateManipulator(manipulator.id) { manip in
                    manip.trigger.keyType = newValue
                    if newValue == .any { manip.trigger.anyKey = true }
                    else { manip.trigger.anyKey = false }
                    // Initialise string trigger options when typed-string type is selected
                    if newValue == .typedString && manip.trigger.stringTrigger == nil {
                        manip.trigger.stringTrigger = StringTriggerOptions()
                    }
                }
            }
        )
    }

    private var consumerKeyBinding: Binding<String> {
        Binding(
            get: { manipulator.trigger.steps.first?.key ?? "" },
            set: { newValue in
                store.updateManipulator(manipulator.id) {
                    $0.trigger.steps = newValue.isEmpty ? [] : [KeyShortcut(key: newValue)]
                }
            }
        )
    }

    private var pointingButtonBinding: Binding<String> {
        Binding(
            get: { manipulator.trigger.steps.first?.key ?? "" },
            set: { newValue in
                store.updateManipulator(manipulator.id) {
                    $0.trigger.steps = newValue.isEmpty ? [] : [KeyShortcut(key: newValue)]
                }
            }
        )
    }

    /// Binding to the typed-string trigger string value.
    private var typedStringBinding: Binding<String> {
        Binding(
            get: { manipulator.trigger.stringTrigger?.string ?? "" },
            set: { newValue in
                store.updateManipulator(manipulator.id) {
                    if $0.trigger.stringTrigger == nil {
                        $0.trigger.stringTrigger = StringTriggerOptions()
                    }
                    $0.trigger.stringTrigger?.string = newValue
                }
            }
        )
    }

    /// Binding to the typed-string match mode.
    private var typedStringMatchModeBinding: Binding<StringTriggerMatchMode> {
        Binding(
            get: { manipulator.trigger.stringTrigger?.matchMode ?? .fullMatch },
            set: { newValue in
                store.updateManipulator(manipulator.id) {
                    if $0.trigger.stringTrigger == nil {
                        $0.trigger.stringTrigger = StringTriggerOptions()
                    }
                    $0.trigger.stringTrigger?.matchMode = newValue
                }
            }
        )
    }

    /// Binding to the typed-string timeout (seconds).
    private var typedStringTimeoutBinding: Binding<Double> {
        Binding(
            get: { manipulator.trigger.stringTrigger?.timeoutSeconds ?? 2.0 },
            set: { newValue in
                store.updateManipulator(manipulator.id) {
                    if $0.trigger.stringTrigger == nil {
                        $0.trigger.stringTrigger = StringTriggerOptions()
                    }
                    $0.trigger.stringTrigger?.timeoutSeconds = max(0.1, newValue)
                }
            }
        )
    }

    /// Binding to the typed-string clearOnMatch toggle.
    private var typedStringClearOnMatchBinding: Binding<Bool> {
        Binding(
            get: { manipulator.trigger.stringTrigger?.clearOnMatch ?? true },
            set: { newValue in
                store.updateManipulator(manipulator.id) {
                    if $0.trigger.stringTrigger == nil {
                        $0.trigger.stringTrigger = StringTriggerOptions()
                    }
                    $0.trigger.stringTrigger?.clearOnMatch = newValue
                }
            }
        )
    }

    /// Binding to the typed-string app bundle ID.
    private var typedStringAppBinding: Binding<String> {
        Binding(
            get: { manipulator.trigger.stringTrigger?.appBundleID ?? "" },
            set: { newValue in
                store.updateManipulator(manipulator.id) {
                    if $0.trigger.stringTrigger == nil {
                        $0.trigger.stringTrigger = StringTriggerOptions()
                    }
                    $0.trigger.stringTrigger?.appBundleID = newValue
                }
            }
        )
    }
}

// MARK: - Step card shell

struct StepCard<Content: View>: View {
    let title: String
    @ViewBuilder var content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.headline)
                .foregroundStyle(.secondary)
            content()
        }
        .padding(12)
        .background(.background.tertiary, in: RoundedRectangle(cornerRadius: 8))
    }
}

// MARK: - Add step menu

struct AddStepMenu: View {
    struct Item: Identifiable, Hashable {
        let id: String
        let title: String
    }

    let label: String
    let items: [Item]
    let action: (Item) -> Void

    var body: some View {
        Menu {
            ForEach(items) { item in
                Button {
                    action(item)
                } label: {
                    Text(item.title)
                }
            }
        } label: {
            Text(label).font(.body)
        }
        .menuStyle(.borderlessButton)
        .fixedSize()
    }
}

// MARK: - Trigger step badge

struct TriggerStepBadge: View {
    let step: KeyShortcut
    let onDelete: () -> Void

    var body: some View {
        HStack(spacing: 4) {
            Text(step.displayLabel)
                .font(.system(.body, design: .monospaced))
            Button {
                onDelete()
            } label: {
                Image(systemName: "xmark")
                    .font(.caption2)
            }
            .buttonStyle(.borderless)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(.background.tertiary, in: RoundedRectangle(cornerRadius: 6))
        .overlay(
            RoundedRectangle(cornerRadius: 6)
                .stroke(.separator, lineWidth: 1)
        )
    }
}

// MARK: - Tag editor field

struct TagEditorField: View {
    @ObservedObject var store: RemapStore
    let manipulator: Manipulator
    @State private var newTag: String = ""

    var body: some View {
        FlowLayout(spacing: 4) {
            ForEach(manipulator.tags.sorted(), id: \.self) { tag in
                Button {
                    store.toggleTag(tag, on: manipulator.id)
                } label: {
                    HStack(spacing: 4) {
                        Text(tag).font(.caption)
                        Image(systemName: "xmark")
                            .font(.caption2)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(Capsule().fill(Color.accentColor.opacity(0.15)))
                    .overlay(Capsule().stroke(Color.accentColor.opacity(0.4), lineWidth: 1))
                }
                .buttonStyle(.plain)
            }
            HStack(spacing: 4) {
                TextField("Add tag", text: $newTag)
                    .textFieldStyle(.plain)
                    .font(.caption)
                    .frame(minWidth: 60)
                    .onSubmit { addCurrentTag() }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(Capsule().fill(.gray.opacity(0.12)))
            if !newTag.isEmpty {
                Button("Add") { addCurrentTag() }
                    .buttonStyle(.borderless)
                    .font(.caption)
            }
        }
    }

    private func addCurrentTag() {
        let trimmed = newTag.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        store.updateManipulator(manipulator.id) { $0.tags.insert(trimmed) }
        newTag = ""
    }
}




