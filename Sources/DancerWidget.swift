import Foundation
import AppKit
import PockKit

class DancerWidget: PKWidget {

    static var identifier: String = "com.tomkoch.pock.Dancer"
    var customizationLabel: String = "Dancer"
    var view: NSView!

    private let dancerView = DancerView()

    required init() {
        self.view = dancerView
    }

    @objc var imageForCustomization: NSImage {
        return dancerView.previewImage
    }

    @objc func viewDidAppear() {
        dancerView.start()
    }

    @objc func viewWillDisappear() {
        dancerView.stop()
    }
}
