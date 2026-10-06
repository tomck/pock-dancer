import AppKit
import ImageIO

/// Plays the selected dancer's frames on a layer. Frames are read from disk as they're
/// needed, so even a seven-minute dancer uses almost no memory. They're 2x images: 60px
/// high shown at 30pt, the Touch Bar's height.
class DancerView: NSView {

    private var dancer: DancerInfo?
    private var wantsPlayback = false
    private var timer: Timer?
    private var startTime = Date()
    private var lastIndex = -1

    private var size: NSSize {
        guard let dancer = dancer else { return NSSize(width: 60, height: 30) }
        return NSSize(width: Double(dancer.width) / 2, height: Double(dancer.height) / 2)
    }

    override var intrinsicContentSize: NSSize { size }

    init() {
        super.init(frame: .zero)
        wantsLayer = true
        layer?.backgroundColor = NSColor.black.cgColor
        layer?.contentsGravity = .resizeAspect
        layer?.magnificationFilter = .trilinear
        dancer = DancerLibrary.selected()
        NotificationCenter.default.addObserver(self, selector: #selector(selectionChanged),
                                               name: DancerLibrary.selectionDidChange, object: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) is not supported")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    @objc private func selectionChanged() {
        stopTimer()
        dancer = DancerLibrary.selected()
        layer?.contents = nil
        invalidateIntrinsicContentSize()
        if wantsPlayback { startTimer() }
    }

    /// Shown in Pock's customization palette, before the widget is running.
    var previewImage: NSImage {
        let size = self.size
        let frame = dancer.flatMap { image(of: $0, at: $0.count / 3) }
        return NSImage(size: size, flipped: false) { rect in
            NSColor.black.setFill()
            NSBezierPath(roundedRect: rect, xRadius: 4, yRadius: 4).fill()
            if let frame = frame {
                NSImage(cgImage: frame, size: size).draw(in: rect)
            }
            NSColor.white.withAlphaComponent(0.4).setStroke()
            let border = NSBezierPath(roundedRect: rect.insetBy(dx: 0.5, dy: 0.5), xRadius: 4, yRadius: 4)
            border.lineWidth = 1
            border.stroke()
            return true
        }
    }

    func start() {
        wantsPlayback = true
        // Pick up dancers converted since the widget loaded.
        if dancer == nil { selectionChanged() } else { startTimer() }
    }

    func stop() {
        wantsPlayback = false
        stopTimer()
    }

    private func startTimer() {
        guard timer == nil, let dancer = dancer else { return }
        startTime = Date()
        lastIndex = -1
        let timer = Timer(timeInterval: 1.0 / dancer.fps, repeats: true) { [weak self] _ in
            self?.showCurrentFrame()
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func showCurrentFrame() {
        guard let dancer = dancer else { return }
        let index = Int(Date().timeIntervalSince(startTime) * dancer.fps) % dancer.count
        guard index != lastIndex, let frame = image(of: dancer, at: index) else { return }
        lastIndex = index
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        layer?.contents = frame
        CATransaction.commit()
    }

    private func image(of dancer: DancerInfo, at index: Int) -> CGImage? {
        let url = dancer.directory.appendingPathComponent(String(format: "frames/frame_%05d.png", index + 1))
        guard let source = CGImageSourceCreateWithURL(url as CFURL, nil) else { return nil }
        return CGImageSourceCreateImageAtIndex(source, 0, [kCGImageSourceShouldCacheImmediately: true] as CFDictionary)
    }
}
