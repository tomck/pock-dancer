import AppKit
import PockKit

/// The widget's pane in Pock's Widgets Manager: a dropdown to choose the dancer.
class DancerPreferencePane: NSViewController, PKWidgetPreference {

    static var nibName: NSNib.Name = "DancerPreferencePane"

    private let popUp = NSPopUpButton(frame: .zero, pullsDown: false)
    private let note = NSTextField(wrappingLabelWithString: "")

    override func viewDidLoad() {
        super.viewDidLoad()

        let label = NSTextField(labelWithString: "Dancer:")
        popUp.target = self
        popUp.action = #selector(dancerChosen)

        let row = NSStackView(views: [label, popUp])
        row.orientation = .horizontal
        row.spacing = 8
        row.alignment = .firstBaseline

        note.textColor = .secondaryLabelColor
        note.font = .systemFont(ofSize: NSFont.smallSystemFontSize)

        let stack = NSStackView(views: [row, note])
        stack.orientation = .vertical
        stack.alignment = .leading
        stack.spacing = 12
        stack.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(stack)
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 20),
            stack.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -20)
        ])
        reloadList()
    }

    override func viewWillAppear() {
        super.viewWillAppear()
        reloadList()
    }

    func reset() {
        if let first = DancerLibrary.all().first { DancerLibrary.select(first.name) }
        reloadList()
    }

    @objc private func dancerChosen() {
        if let name = popUp.selectedItem?.representedObject as? String {
            DancerLibrary.select(name)
        }
    }

    private func reloadList() {
        let dancers = DancerLibrary.all()
        popUp.removeAllItems()
        for dancer in dancers {
            popUp.addItem(withTitle: dancer.displayName)
            popUp.lastItem?.representedObject = dancer.name
        }
        popUp.isEnabled = !dancers.isEmpty
        if let current = DancerLibrary.selected(), let index = dancers.firstIndex(where: { $0.name == current.name }) {
            popUp.selectItem(at: index)
        }
        note.stringValue = dancers.isEmpty
            ? "No dancers found in ~/Library/Application Support/Pock/Dancers. Run convert.sh to add some."
            : "Add more dancers with convert.sh; they show up here without reinstalling."
    }
}
