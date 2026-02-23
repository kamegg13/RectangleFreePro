//
//  ProFeaturesViewController.swift
//  Rectangle
//
//  Onglet "Pro" dans les Préférences — entièrement en code (pas de storyboard).
//  Sections : Hyper Key, Custom Sizes (1-5), Menu Customization.
//

import Cocoa

class ProFeaturesViewController: NSViewController {

    private var tableView: NSTableView!
    private var sizes: [CustomWindowSize] = []

    // MARK: - Lifecycle

    override func loadView() {
        view = NSView(frame: NSRect(x: 0, y: 0, width: 520, height: 600))
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadSizes()
        setupUI()
    }

    // MARK: - Data helpers

    private func loadSizes() {
        let saved = Defaults.customSizes.typedValue ?? []
        sizes = (0..<5).map { i in
            i < saved.count ? saved[i] : CustomWindowSize(name: "Custom \(i + 1)", width: 0.5, height: 0.5)
        }
    }

    private func saveSizes() {
        Defaults.customSizes.typedValue = sizes
    }

    // MARK: - UI setup

    private func setupUI() {
        let outerScroll = NSScrollView()
        outerScroll.translatesAutoresizingMaskIntoConstraints = false
        outerScroll.hasVerticalScroller = true
        outerScroll.borderType = .noBorder
        outerScroll.autohidesScrollers = true
        view.addSubview(outerScroll)

        NSLayoutConstraint.activate([
            outerScroll.topAnchor.constraint(equalTo: view.topAnchor),
            outerScroll.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            outerScroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            outerScroll.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])

        let content = NSStackView()
        content.orientation = .vertical
        content.alignment = .leading
        content.spacing = 20
        content.translatesAutoresizingMaskIntoConstraints = false
        content.edgeInsets = NSEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)

        content.addArrangedSubview(sectionHeader("Hyper Key"))
        content.addArrangedSubview(makeHyperKeyView())
        content.addArrangedSubview(makeDivider())

        content.addArrangedSubview(sectionHeader("Custom Sizes (Slots 1–5)"))
        content.addArrangedSubview(makeCustomSizesView())
        content.addArrangedSubview(makeDivider())

        content.addArrangedSubview(sectionHeader("Menu Customization"))
        content.addArrangedSubview(makeMenuCustomizationView())

        outerScroll.documentView = content

        NSLayoutConstraint.activate([
            content.widthAnchor.constraint(equalTo: outerScroll.widthAnchor),
            content.topAnchor.constraint(equalTo: outerScroll.contentView.topAnchor)
        ])
    }

    // MARK: - Common widgets

    private func sectionHeader(_ title: String) -> NSTextField {
        let label = NSTextField(labelWithString: title)
        label.font = NSFont.boldSystemFont(ofSize: 13)
        return label
    }

    private func makeDivider() -> NSView {
        let view = NSView()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.heightAnchor.constraint(equalToConstant: 1).isActive = true
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.separatorColor.cgColor
        return view
    }

    private func hintLabel(_ text: String) -> NSTextField {
        let label = NSTextField(labelWithString: text)
        label.font = NSFont.systemFont(ofSize: 11)
        label.textColor = .secondaryLabelColor
        label.maximumNumberOfLines = 0
        label.lineBreakMode = .byWordWrapping
        return label
    }

    // MARK: - Hyper Key section

    private func makeHyperKeyView() -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 6

        let checkbox = NSButton(
            checkboxWithTitle: "Enable Hyper Key (Caps Lock → tap = Escape, hold = Cmd+Ctrl+Alt+Shift)",
            target: self,
            action: #selector(toggleHyperKey)
        )
        checkbox.state = Defaults.hyperKeyEnabled.enabled ? .on : .off

        let hint = hintLabel("After enabling, record shortcuts with the Hyper modifier in the Shortcuts tab. Requires Accessibility permission.")

        stack.addArrangedSubview(checkbox)
        stack.addArrangedSubview(hint)
        return stack
    }

    @objc private func toggleHyperKey(_ sender: NSButton) {
        let enabled = sender.state == .on
        Defaults.hyperKeyEnabled.enabled = enabled
        Notification.Name.hyperKeyToggled.post(object: enabled)
    }

    // MARK: - Custom Sizes section

    private func makeCustomSizesView() -> NSView {
        let stack = NSStackView()
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 8

        stack.addArrangedSubview(hintLabel(
            "Width/Height ≤ 1.0 = screen ratio (0.5 = 50%), > 1 = pixels. " +
            "Center X/Y: 0.5 = centered, 0 = left/bottom, 1 = right/top. " +
            "Double-click a cell to edit."
        ))

        tableView = NSTableView()
        tableView.usesAlternatingRowBackgroundColors = true
        tableView.allowsColumnReordering = false
        tableView.rowHeight = 22
        tableView.columnAutoresizingStyle = .sequentialColumnAutoresizingStyle

        let cols: [(id: String, title: String, width: CGFloat, editable: Bool)] = [
            ("slot",    "#",        28,  false),
            ("name",    "Name",    100, true),
            ("width",   "Width",    68, true),
            ("height",  "Height",   68, true),
            ("centerX", "Center X", 65, true),
            ("centerY", "Center Y", 65, true)
        ]

        for col in cols {
            let column = NSTableColumn(identifier: NSUserInterfaceItemIdentifier(col.id))
            column.title = col.title
            column.width = col.width
            column.isEditable = col.editable
            tableView.addTableColumn(column)
        }

        tableView.delegate = self
        tableView.dataSource = self

        let tableScroll = NSScrollView()
        tableScroll.documentView = tableView
        tableScroll.hasVerticalScroller = false
        tableScroll.hasHorizontalScroller = false
        tableScroll.borderType = .bezelBorder
        tableScroll.translatesAutoresizingMaskIntoConstraints = false

        let headerH = tableView.headerView?.frame.height ?? 17
        let tableH = CGFloat(5) * tableView.rowHeight + headerH + 4
        tableScroll.heightAnchor.constraint(equalToConstant: tableH).isActive = true

        stack.addArrangedSubview(tableScroll)
        return stack
    }

    // MARK: - Menu Customization section

    private func makeMenuCustomizationView() -> NSView {
        let outer = NSStackView()
        outer.orientation = .vertical
        outer.alignment = .leading
        outer.spacing = 8

        outer.addArrangedSubview(hintLabel("Uncheck actions to hide them from the menu bar. Changes take effect immediately."))

        // Two-column layout
        let grid = NSStackView()
        grid.orientation = .horizontal
        grid.alignment = .top
        grid.distribution = .fillEqually
        grid.spacing = 16

        let leftCol = NSStackView()
        leftCol.orientation = .vertical
        leftCol.alignment = .leading
        leftCol.spacing = 4

        let rightCol = NSStackView()
        rightCol.orientation = .vertical
        rightCol.alignment = .leading
        rightCol.spacing = 4

        let actions = WindowAction.active.compactMap { action -> (WindowAction, String)? in
            guard let name = action.displayName else { return nil }
            return (action, name)
        }

        for (index, (action, displayName)) in actions.enumerated() {
            let checkbox = NSButton(checkboxWithTitle: displayName, target: self, action: #selector(toggleMenuAction))
            checkbox.tag = action.rawValue
            checkbox.state = MenuCustomizationManager.isHidden(action) ? .off : .on
            (index % 2 == 0 ? leftCol : rightCol).addArrangedSubview(checkbox)
        }

        grid.addArrangedSubview(leftCol)
        grid.addArrangedSubview(rightCol)
        outer.addArrangedSubview(grid)
        return outer
    }

    @objc private func toggleMenuAction(_ sender: NSButton) {
        guard let action = WindowAction(rawValue: sender.tag) else { return }
        MenuCustomizationManager.setHidden(sender.state == .off, for: action)
    }
}

// MARK: - NSTableViewDataSource

extension ProFeaturesViewController: NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int { 5 }

    func tableView(_ tableView: NSTableView, objectValueFor tableColumn: NSTableColumn?, row: Int) -> Any? {
        guard row < sizes.count else { return nil }
        let s = sizes[row]
        switch tableColumn?.identifier.rawValue {
        case "slot":    return "\(row + 1)"
        case "name":    return s.name
        case "width":   return String(format: "%.2f", s.width)
        case "height":  return String(format: "%.2f", s.height)
        case "centerX": return String(format: "%.2f", s.centerX)
        case "centerY": return String(format: "%.2f", s.centerY)
        default:        return nil
        }
    }

    func tableView(_ tableView: NSTableView, setObjectValue object: Any?, for tableColumn: NSTableColumn?, row: Int) {
        guard row < sizes.count, let str = object as? String else { return }
        let floatVal = Float(str)
        switch tableColumn?.identifier.rawValue {
        case "name":    sizes[row].name = str
        case "width":   sizes[row].width = floatVal ?? sizes[row].width
        case "height":  sizes[row].height = floatVal ?? sizes[row].height
        case "centerX": sizes[row].centerX = floatVal.map { max(0, min(1, $0)) } ?? sizes[row].centerX
        case "centerY": sizes[row].centerY = floatVal.map { max(0, min(1, $0)) } ?? sizes[row].centerY
        default: break
        }
        saveSizes()
    }
}

// MARK: - NSTableViewDelegate

extension ProFeaturesViewController: NSTableViewDelegate {}
