import SwiftUI
import WebKit

// MARK: - Main Widgets View

struct WidgetsView: View {
    @ObservedObject var store: RemapStore

    var body: some View {
        NavigationSplitView {
            WidgetsSidebar(store: store)
                .navigationTitle("Widgets")
        } detail: {
            WidgetEditorPane(store: store)
                .frame(minWidth: 520)
        }
        .toolbar {
            ToolbarItem(placement: .navigation) {
                Menu {
                    Section("Pre-built Templates") {
                        ForEach(WidgetTemplate.available) { template in
                            Button {
                                store.addWidgetFromTemplate(template)
                            } label: {
                                Label(template.name, systemImage: template.icon)
                            }
                        }
                    }
                    Divider()
                    Button {
                        store.addWidget()
                    } label: {
                        Label("Blank HTML Widget", systemImage: "chevron.left.forwardslash.chevron.right")
                    }
                    Button {
                        var widget = WidgetItem(name: "Web Page", kind: .url)
                        widget.urlString = "https://"
                        store.addWidget(widget)
                    } label: {
                        Label("URL Widget", systemImage: "link")
                    }
                } label: {
                    Image(systemName: "plus")
                }
                .help("Add a new widget")
            }
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    store.importWidgetFromPanel()
                } label: {
                    Image(systemName: "tray.and.arrow.down")
                }
                .help("Import a widget file (⌘⌥I)")

                Button {
                    if let id = store.selectedWidgetID {
                        store.exportWidget(id)
                    }
                } label: {
                    Image(systemName: "tray.and.arrow.up")
                }
                .disabled(store.selectedWidgetID == nil)
                .help("Export the selected widget (⌘⌥E)")

                ProfileSwitcherButton(store: store)
            }
        }
    }
}

// MARK: - Sidebar

private struct WidgetsSidebar: View {
    @ObservedObject var store: RemapStore
    @State private var itemToDelete: WidgetItem?

    var body: some View {
        VStack(spacing: 0) {
            searchField
            itemList
        }
        .frame(minWidth: 260, maxWidth: 360)
        .alert(
            "Delete \"\(itemToDelete?.name ?? "")\"?",
            isPresented: Binding(
                get: { itemToDelete != nil },
                set: { if !$0 { itemToDelete = nil } }
            )
        ) {
            Button("Cancel", role: .cancel) { itemToDelete = nil }
            Button("Delete", role: .destructive) {
                if let id = itemToDelete?.id {
                    store.deleteWidget(id)
                }
                itemToDelete = nil
            }
        } message: {
            Text("This action cannot be undone.")
        }
    }

    private var searchField: some View {
        HStack {
            Image(systemName: "magnifyingglass")
                .foregroundStyle(.tertiary)
            TextField("Search widgets…", text: $store.searchText)
                .textFieldStyle(.plain)
                .font(.subheadline)
            if !store.searchText.isEmpty {
                Button {
                    store.searchText = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .foregroundStyle(.tertiary)
                }
                .buttonStyle(.plain)
            }
        }
        .padding(8)
        .background(Color(nsColor: .controlBackgroundColor))
    }

    private var itemList: some View {
        let filteredItems: [WidgetItem] = {
            let query = store.searchText.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
            guard !query.isEmpty else { return store.widgets }
            return store.widgets.filter {
                $0.name.lowercased().contains(query) || $0.summary.lowercased().contains(query)
            }
        }()

        return Group {
            if store.widgets.isEmpty {
                ContentUnavailableView {
                    Label("No Widgets", systemImage: "sparkles")
                } description: {
                    Text("Add a widget from a template or create a custom HTML widget.")
                } actions: {
                    Button("Add Widget") {
                        store.addWidget()
                    }
                }
            } else if filteredItems.isEmpty {
                ContentUnavailableView {
                    Label("No Results", systemImage: "magnifyingglass")
                } description: {
                    Text("Try a different search query.")
                }
            } else {
                List(selection: $store.selectedWidgetID) {
                    ForEach(Array(filteredItems.enumerated()), id: \.element.id) { index, item in
                        WidgetItemRow(store: store, item: item, index: index)
                            .tag(item.id)
                            .contextMenu {
                                contextMenuItems(for: item)
                            }
                    }
                    .onMove { source, dest in
                        store.moveWidget(from: source, to: dest)
                    }
                    .onDelete { indexSet in
                        if let i = indexSet.first, filteredItems.indices.contains(i) {
                            itemToDelete = filteredItems[i]
                        }
                    }
                }
                .listStyle(.inset(alternatesRowBackgrounds: true))
            }
        }
    }

    @ViewBuilder
    private func contextMenuItems(for item: WidgetItem) -> some View {
        Button {
            store.toggleWidgetEnabled(item.id)
        } label: {
            Text(item.isEnabled ? "Disable" : "Enable")
            Image(systemName: item.isEnabled ? "pause" : "play")
        }

        Button {
            store.duplicateWidget(item.id)
        } label: {
            Text("Duplicate")
            Image(systemName: "plus.square.on.square")
        }

        Divider()

        Button(role: .destructive) {
            itemToDelete = item
        } label: {
            Text("Delete")
            Image(systemName: "trash")
        }
    }
}

// MARK: - Widget Item Row

private struct WidgetItemRow: View {
    @ObservedObject var store: RemapStore
    let item: WidgetItem
    var index: Int = 0

    var body: some View {
        HStack(spacing: 10) {
            // Kind icon
            Image(systemName: kindIcon)
                .font(.system(size: 13))
                .foregroundStyle(item.isEnabled ? .primary : .tertiary)
                .frame(width: 22)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(item.name)
                        .font(.body)
                        .lineLimit(1)
                    if !item.isEnabled {
                        Text("Disabled")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 1)
                            .background(.quaternary.opacity(0.3), in: Capsule())
                    }
                }
                Text(item.kind.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Size indicator
            Text("\(Int(item.width))×\(Int(item.height))")
                .font(.caption2)
                .foregroundStyle(.tertiary)
                .monospacedDigit()
        }
        .padding(.vertical, 4)
        .opacity(item.isEnabled ? 1 : 0.6)
    }

    private var kindIcon: String {
        switch item.kind {
        case .html: return "chevron.left.forwardslash.chevron.right"
        case .url: return "link"
        case .template: return "square.on.square"
        }
    }
}

// MARK: - Editor Pane

private struct WidgetEditorPane: View {
    @ObservedObject var store: RemapStore
    @State private var showDeleteConfirmation = false
    @State private var showTemplatePicker = false
    @State private var previewUpdateID = UUID()

    var body: some View {
        Group {
            if let item = store.selectedWidget {
                editorContent(item: item)
            } else {
                ContentUnavailableView {
                    Label("Select a Widget", systemImage: "sparkles")
                } description: {
                    Text("Choose a widget from the sidebar or add a new one.")
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert(
            "Delete \"\(store.selectedWidget?.name ?? "")\"?",
            isPresented: $showDeleteConfirmation
        ) {
            Button("Cancel", role: .cancel) {}
            Button("Delete", role: .destructive) {
                if let id = store.selectedWidgetID {
                    store.deleteWidget(id)
                }
            }
        } message: {
            Text("This action cannot be undone.")
        }
        .sheet(isPresented: $showTemplatePicker) {
            TemplatePickerSheet(store: store)
        }
        .id(previewUpdateID)
    }

    private func editorContent(item: WidgetItem) -> some View {
        let binding = Binding(
            get: { item },
            set: { newItem in
                if let idx = store.widgets.firstIndex(where: { $0.id == newItem.id }) {
                    store.widgets[idx] = newItem
                    store.saveConfig()
                }
            }
        )

        return HSplitView {
            // Left: Properties editor
            propertiesEditor(item: binding.wrappedValue, binding: binding)
                .frame(minWidth: 320, idealWidth: 400)

            // Right: Live preview
            previewPanel(item: binding.wrappedValue)
                .frame(minWidth: 280, idealWidth: 360)
        }
    }

    // MARK: - Properties Editor

    private func propertiesEditor(item: WidgetItem, binding: Binding<WidgetItem>) -> some View {
        Form {
            // ── Basic Settings ──
            Section {
                HStack {
                    Text("Name")
                    Spacer()
                    TextField("Widget Name", text: binding.name)
                        .frame(width: 200)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Type")
                    Spacer()
                    Text(item.kind.rawValue)
                        .foregroundStyle(.secondary)
                }

                Toggle("Enabled", isOn: binding.isEnabled)
            } header: {
                Label("Basic", systemImage: "gearshape")
            }

            // ── Appearance ──
            Section {
                HStack {
                    Text("Width")
                    Spacer()
                    TextField("Width", value: binding.width, format: .number)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                    Text("px")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Height")
                    Spacer()
                    TextField("Height", value: binding.height, format: .number)
                        .frame(width: 80)
                        .textFieldStyle(.roundedBorder)
                        .multilineTextAlignment(.trailing)
                    Text("px")
                        .foregroundStyle(.secondary)
                }

                HStack {
                    Text("Corner Radius")
                    Spacer()
                    Slider(value: binding.cornerRadius, in: 0...24, step: 1)
                        .frame(width: 120)
                    Text("\(Int(item.cornerRadius))px")
                        .font(.caption.monospacedDigit())
                        .foregroundStyle(.secondary)
                        .frame(width: 32)
                }

                HStack {
                    Text("Background")
                    Spacer()
                    ColorPicker("", selection: Binding(
                        get: { Color(hex: item.backgroundColor) ?? Color(nsColor: .windowBackgroundColor) },
                        set: { newColor in
                            binding.backgroundColor.wrappedValue = newColor.toHex() ?? "#1a1a2e"
                        }
                    ))
                    .labelsHidden()
                }

                HStack {
                    Text("Text Color")
                    Spacer()
                    ColorPicker("", selection: Binding(
                        get: { Color(hex: item.textColor) ?? .white },
                        set: { newColor in
                            binding.textColor.wrappedValue = newColor.toHex() ?? "#ffffff"
                        }
                    ))
                    .labelsHidden()
                }

                if item.kind != .url {
                    HStack {
                        Text("Refresh Interval")
                        Spacer()
                        Picker("", selection: binding.refreshInterval) {
                            Text("None").tag(0.0)
                            Text("1 sec").tag(1.0)
                            Text("5 sec").tag(5.0)
                            Text("10 sec").tag(10.0)
                            Text("30 sec").tag(30.0)
                            Text("1 min").tag(60.0)
                            Text("5 min").tag(300.0)
                        }
                        .labelsHidden()
                        .frame(width: 120)
                    }
                }
            } header: {
                Label("Appearance", systemImage: "paintpalette")
            }

            // ── Content ──
            Section {
                switch item.kind {
                case .html:
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text("HTML Content")
                            Spacer()
                            Button("Use Template…") {
                                showTemplatePicker = true
                            }
                            .controlSize(.small)
                            .buttonStyle(.bordered)
                        }
                        HTMLTextEditor(text: binding.htmlContent)
                            .frame(minHeight: 300)
                            .overlay(
                                RoundedRectangle(cornerRadius: 6)
                                    .stroke(Color(nsColor: .separatorColor).opacity(0.3), lineWidth: 1)
                            )
                    }

                case .url:
                    HStack {
                        Text("URL")
                        Spacer()
                        TextField("https://example.com", text: binding.urlString)
                            .frame(width: 260)
                            .textFieldStyle(.roundedBorder)
                            .multilineTextAlignment(.trailing)
                            .font(.body.monospaced())
                    }

                case .template:
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            Text("Template")
                            Spacer()
                            if let tid = item.templateID,
                               let template = WidgetTemplate.available.first(where: { $0.id == tid }) {
                                Label(template.name, systemImage: template.icon)
                                    .foregroundStyle(.secondary)
                            }
                            Button("Change Template…") {
                                showTemplatePicker = true
                            }
                            .controlSize(.small)
                            .buttonStyle(.bordered)
                        }

                        if let tid = item.templateID,
                           let template = WidgetTemplate.available.first(where: { $0.id == tid }) {
                            Text(template.description)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            } header: {
                Label("Content", systemImage: "doc.text")
            }

            // ── Preview Controls ──
            Section {
                HStack {
                    Button("Refresh Preview") {
                        previewUpdateID = UUID()
                    }
                    .controlSize(.small)

                    Button("Open in Window…") {
                        openInWindow(item: item)
                    }
                    .controlSize(.small)
                }
            } header: {
                Label("Preview", systemImage: "eye")
            }
        }
        .formStyle(.grouped)
        .scrollIndicators(.visible)
    }

    // MARK: - Preview Panel

    private func previewPanel(item: WidgetItem) -> some View {
        VStack(spacing: 0) {
            HStack {
                Image(systemName: "eye")
                    .foregroundStyle(.secondary)
                Text("Live Preview")
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(Int(item.width))×\(Int(item.height))")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                    .monospacedDigit()
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .background(.quaternary.opacity(0.3))

            WebView(
                html: item.kind == .url ? nil : item.resolvedHTML(with: store.engine.variables),
                url: item.kind == .url ? URL(string: item.urlString) : nil,
                backgroundColor: item.backgroundColor,
                refreshInterval: item.refreshInterval > 0 ? item.refreshInterval : nil
            )
            .frame(width: min(item.width, 500), height: min(item.height, 400))
            .clipShape(RoundedRectangle(cornerRadius: item.cornerRadius))
            .padding()
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color(nsColor: .windowBackgroundColor))
        }
    }

    // MARK: - Open in Window

    private func openInWindow(item: WidgetItem) {
        let window = NSWindow(
            contentRect: NSRect(x: 0, y: 0, width: item.width, height: item.height),
            styleMask: [.titled, .closable, .resizable, .miniaturizable],
            backing: .buffered,
            defer: false
        )
        window.title = item.name
        window.isReleasedWhenClosed = false
        let hostingVC = NSHostingController(
            rootView: WebView(
                html: item.kind == .url ? nil : item.resolvedHTML(with: store.engine.variables),
                url: item.kind == .url ? URL(string: item.urlString) : nil,
                backgroundColor: item.backgroundColor,
                refreshInterval: item.refreshInterval > 0 ? item.refreshInterval : nil
            )
            .frame(width: item.width, height: item.height)
            .clipShape(RoundedRectangle(cornerRadius: item.cornerRadius))
        )
        window.contentViewController = hostingVC
        window.makeKeyAndOrderFront(nil)
    }
}

// MARK: - HTML Text Editor (Simplified Code Editor)

private struct HTMLTextEditor: NSViewRepresentable {
    @Binding var text: String

    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.borderType = .noBorder

        let textView = NSTextView()
        textView.isEditable = true
        textView.isSelectable = true
        textView.font = NSFont.monospacedSystemFont(ofSize: 11, weight: .regular)
        textView.textColor = NSColor.textColor
        textView.backgroundColor = NSColor.textBackgroundColor
        textView.string = text
        textView.delegate = context.coordinator
        textView.autoresizingMask = [.width]
        textView.isVerticallyResizable = true
        textView.isHorizontallyResizable = false
        textView.textContainer?.widthTracksTextView = true
        textView.textContainer?.lineBreakMode = .byWordWrapping

        scrollView.documentView = textView
        return scrollView
    }

    func updateNSView(_ scrollView: NSScrollView, context: Context) {
        guard let textView = scrollView.documentView as? NSTextView else { return }
        if textView.string != text {
            textView.string = text
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(text: $text)
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var text: Binding<String>

        init(text: Binding<String>) {
            self.text = text
        }

        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            text.wrappedValue = textView.string
        }
    }
}

// MARK: - WebView (WKWebView Wrapper)

private struct WebView: NSViewRepresentable {
    let html: String?
    let url: URL?
    let backgroundColor: String
    var refreshInterval: TimeInterval? = nil

    init(html: String? = nil, url: URL? = nil, backgroundColor: String = "#1a1a2e", refreshInterval: TimeInterval? = nil) {
        self.html = html
        self.url = url
        self.backgroundColor = backgroundColor
        self.refreshInterval = refreshInterval
    }

    func makeNSView(context: Context) -> WKWebView {
        let config = WKWebViewConfiguration()
        config.mediaTypesRequiringUserActionForPlayback = .all

        let webView = WKWebView(frame: .zero, configuration: config)
        webView.setValue(false, forKey: "drawsBackground")
        webView.navigationDelegate = context.coordinator

        if let refreshInterval {
            let timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
                context.coordinator.refresh(webView)
            }
            context.coordinator.timer = timer
        }

        loadContent(webView: webView)
        return webView
    }

    func updateNSView(_ webView: WKWebView, context: Context) {
        loadContent(webView: webView)

        // Update refresh interval
        context.coordinator.timer?.invalidate()
        if let refreshInterval {
            let timer = Timer.scheduledTimer(withTimeInterval: refreshInterval, repeats: true) { _ in
                context.coordinator.refresh(webView)
            }
            context.coordinator.timer = timer
        }
    }

    private func loadContent(webView: WKWebView) {
        if let html {
            webView.loadHTMLString(html, baseURL: nil)
        } else if let url {
            webView.load(URLRequest(url: url))
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(backgroundColor: backgroundColor)
    }

    class Coordinator: NSObject, WKNavigationDelegate {
        let backgroundColor: String
        var timer: Timer?

        init(backgroundColor: String) {
            self.backgroundColor = backgroundColor
        }

        func webView(_ webView: WKWebView, didFinish navigation: WKNavigation!) {
            // Inject background color into the page
            let js = """
            document.body.style.backgroundColor = '\(backgroundColor)';
            """
            webView.evaluateJavaScript(js, completionHandler: nil)
        }

        func refresh(_ webView: WKWebView) {
            webView.reload()
        }

        deinit {
            timer?.invalidate()
        }
    }
}

// MARK: - Template Picker Sheet

private struct TemplatePickerSheet: View {
    @ObservedObject var store: RemapStore
    @Environment(\.dismiss) private var dismiss
    @State private var selectedTemplate: WidgetTemplate?
    @State private var searchText = ""

    private let categories = ["All", "Utilities", "Productivity", "System", "Developer"]

    @State private var selectedCategory = "All"

    var body: some View {
        VStack(spacing: 0) {
            // Header
            HStack {
                Text("Choose a Template")
                    .font(.title3.weight(.semibold))
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
            }
            .padding()
            .background(.quaternary.opacity(0.2))

            // Category filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.self) { category in
                        Button {
                            selectedCategory = category
                        } label: {
                            Text(category)
                                .font(.subheadline)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 5)
                                .background(
                                    selectedCategory == category
                                        ? Color.accentColor
                                        : Color(nsColor: .controlBackgroundColor),
                                    in: Capsule()
                                )
                                .foregroundStyle(selectedCategory == category ? .white : .primary)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal)
                .padding(.vertical, 8)
            }
            .background(.quaternary.opacity(0.1))

            // Search
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.tertiary)
                TextField("Search templates…", text: $searchText)
                    .textFieldStyle(.plain)
                if !searchText.isEmpty {
                    Button { searchText = "" } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.tertiary)
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(8)
            .background(Color(nsColor: .controlBackgroundColor))

            // Template grid
            ScrollView {
                LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 12), count: 2), spacing: 12) {
                    ForEach(filteredTemplates) { template in
                        TemplateCard(
                            template: template,
                            isSelected: selectedTemplate?.id == template.id,
                            onSelect: { selectedTemplate = template },
                            onDoubleClick: {
                                applyTemplate(template)
                            }
                        )
                    }
                }
                .padding()
            }

            // Footer
            HStack {
                Spacer()
                Button("Cancel") {
                    dismiss()
                }
                .keyboardShortcut(.cancelAction)

                Button("Use Template") {
                    if let template = selectedTemplate {
                        applyTemplate(template)
                    }
                }
                .keyboardShortcut(.defaultAction)
                .disabled(selectedTemplate == nil)
            }
            .padding()
            .background(.quaternary.opacity(0.2))
        }
        .frame(width: 560, height: 480)
    }

    private var filteredTemplates: [WidgetTemplate] {
        let templates = WidgetTemplate.available
        let categoryFiltered: [WidgetTemplate]
        if selectedCategory == "All" {
            categoryFiltered = templates
        } else {
            categoryFiltered = templates.filter { $0.category == selectedCategory }
        }
        guard !searchText.isEmpty else { return categoryFiltered }
        let query = searchText.lowercased()
        return categoryFiltered.filter {
            $0.name.lowercased().contains(query) ||
            $0.description.lowercased().contains(query) ||
            $0.category.lowercased().contains(query)
        }
    }

    private func applyTemplate(_ template: WidgetTemplate) {
        if let id = store.selectedWidgetID {
            store.updateWidget(id) { item in
                item.kind = .template
                item.templateID = template.id
                item.htmlContent = template.htmlContent
                item.name = template.name
                item.icon = template.icon
            }
        } else {
            store.addWidgetFromTemplate(template)
        }
        dismiss()
    }
}

// MARK: - Template Card

private struct TemplateCard: View {
    let template: WidgetTemplate
    let isSelected: Bool
    let onSelect: () -> Void
    let onDoubleClick: () -> Void

    var body: some View {
        Button {
            onSelect()
        } label: {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 8) {
                    Image(systemName: template.icon)
                        .font(.title3)
                        .foregroundStyle(Color.accentColor)
                        .frame(width: 24)

                    VStack(alignment: .leading, spacing: 2) {
                        Text(template.name)
                            .font(.body.weight(.medium))
                            .lineLimit(1)
                        Text(template.category)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(template.description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color.accentColor.opacity(0.08) : Color(nsColor: .controlBackgroundColor))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .strokeBorder(
                        isSelected ? Color.accentColor : Color(nsColor: .separatorColor).opacity(0.3),
                        lineWidth: isSelected ? 2 : 1
                    )
            )
        }
        .buttonStyle(.plain)
        .onTapGesture(count: 2) {
            onDoubleClick()
        }
    }
}

// MARK: - Color Hex Extension

private extension Color {
    init?(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            return nil
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }

    func toHex() -> String? {
        let color = NSColor(self).usingColorSpace(.sRGB)
        guard let color else { return nil }
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        color.getRed(&r, green: &g, blue: &b, alpha: &a)
        return String(format: "#%02X%02X%02X", Int(r * 255), Int(g * 255), Int(b * 255))
    }
}
