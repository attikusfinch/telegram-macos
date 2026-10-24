import XCTest
@testable import TGUIKit
import Cocoa

open class BeforeTextButtonBarView: BarView {

    public static let pillHeight: CGFloat = 40
    private static let horizontalPad: CGFloat = 20

    public let button: TextButton = TextButton()
    private var progressIndicator: ProgressIndicator?
    private weak var progressAnchor: NSView?
    private var _isFitted: Bool
    private var currentTexts: [ControlState: String] = [:]

    public init(controller: ViewController, text: String, style: ControlStyle = navigationButtonStyle, glassForceAppearance: LiquidGlassAppearance? = nil) {

        var pillStyle = style
        pillStyle.foregroundColor = presentation.colors.text
        button.autoSizeToFit = false
        button.set(font: pillStyle.font, for: .Normal)
        button.set(color: pillStyle.foregroundColor, for: .Normal)
        button.set(text: text, for: .Normal)
        button.set(background: .clear, for: .Normal)
        button.disableActions()

        _isFitted = false
        currentTexts[.Normal] = text
        super.init(controller: controller)

        self.style = pillStyle
        button.style = pillStyle

        self.addSubview(button)
        progressAnchor = button.subviews.last

        button.disableActions()
        button.animates = false
        button.scaleOnClick = true

        button.layer?.cornerRadius = BeforeTextButtonBarView.pillHeight / 2
        button.layer?.masksToBounds = true
        self.layer?.masksToBounds = false
        button.setGlassEffect(forceAppearance: glassForceAppearance)
        self.stretchReferenceView = button
        self.stretchTransformView = button
    }

    public var direction: TextButtonImageDirection = .left {
        didSet {
            button.direction = direction
        }
    }

    public func set(image: CGImage, for state: ControlState) -> Void {
        button.set(image: image, for: state)
        _isFitted = false
        (superview as? NavigationBarView)?.viewFrameChanged(Notification(name: NSView.frameDidChangeNotification))
    }

    public func set(color: NSColor, for state: ControlState) -> Void {
        _isFitted = false
        button.set(color: color, for: state)
    }

    public func set(font: NSFont, for state: ControlState) -> Void {
        button.set(font: font, for: state)
        _isFitted = false
        (superview as? NavigationBarView)?.viewFrameChanged(Notification(name: NSView.frameDidChangeNotification))
    }

    public func set(text: String, for state: ControlState) -> Void {
        if currentTexts[state] == text {
            return
        }
        currentTexts[state] = text
        if !isLoading {
            button.set(text: text, for: state)
        }
        _isFitted = false
        (superview as? NavigationBarView)?.viewFrameChanged(Notification(name: NSView.frameDidChangeNotification))
    }

    public func removeImage(for state: ControlState) {
        button.removeImage(for: state)
    }

    @discardableResult open override func set(handler: @escaping (Control) -> Void, for event: ControlEvent) -> UInt32 {
        return button.set(handler: handler, for: event)
    }

    @discardableResult open override func set(handler: @escaping (Control) -> Void, for state: ControlState) -> UInt32 {
        return button.set(handler: handler, for: state)
    }

    open override func removeAllHandlers() {
        button.removeAllHandlers()
    }

    open override func removeAllStateHandlers() {
        button.removeAllStateHandlers()
    }

    public override var isFitted: Bool {
        return _isFitted
    }

    open override func fit(to maxWidth: CGFloat, transition: ContainedViewLayoutTransition = .immediate) -> CGFloat {
        let pad = BeforeTextButtonBarView.horizontalPad
        let pillHeight = BeforeTextButtonBarView.pillHeight
        let addition = NSMakeSize(pad, 0)
        _isFitted = button.sizeToFit(addition, NSMakeSize(maxWidth, pillHeight), thatFit: false, transition: transition)
        return button.frame.width
    }

    public override var style: ControlStyle {
        didSet {
            button.set(font: style.font, for: .Normal)
            set(color: style.foregroundColor, for: .Normal)
            button.style = style
        }
    }

    open override var isEnabled: Bool {
        didSet {
            button.isEnabled = isEnabled
        }
    }

    open var isLoading: Bool = false {
        didSet {
            if isLoading {
                button.set(text: "", for: .Normal)
            } else {
                button.set(text: currentTexts[.Normal] ?? "", for: .Normal)
            }
            if isLoading {
                if progressIndicator == nil {
                    let indicator = ProgressIndicator(frame: NSMakeRect(0, 0, 18, 18))
                    if let anchor = progressAnchor, anchor.superview === button {
                        button.addSubview(indicator, positioned: .above, relativeTo: anchor)
                    } else {
                        button.addSubview(indicator)
                    }
                    progressIndicator = indicator
                }
            } else if let indicator = progressIndicator {
                indicator.removeFromSuperview()
                progressIndicator = nil
            }
            button.userInteractionEnabled = !isLoading
            needsLayout = true
        }
    }

    override open func updateLocalizationAndTheme(theme: PresentationTheme) {
        super.updateLocalizationAndTheme(theme: theme)
        button.set(color: presentation.colors.text, for: .Normal)
        button.set(background: .clear, for: .Normal)
        button.updateLocalizationAndTheme(theme: theme)
    }

    open override func layout() {
        super.layout()
        updateLayout(size: frame.size, transition: .immediate)
    }

    open override func updateLayout(size: NSSize, transition: ContainedViewLayoutTransition) {
        let pillHeight = BeforeTextButtonBarView.pillHeight
        let w = max(button.frame.width, isLoading ? pillHeight : 0)
        let btnSize = NSMakeSize(w, pillHeight)
        let x = floorToScreenPixels(backingScaleFactor, (size.width - w) / 2)
        let y = floorToScreenPixels(backingScaleFactor, (size.height - pillHeight) / 2)
        transition.updateFrame(view: button, frame: NSMakeRect(x, y, btnSize.width, btnSize.height))
        button.updateLayout(size: btnSize, transition: transition)
        progressIndicator?.center()
    }

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    required public init(frame frameRect: NSRect) {
        fatalError("init(frame:) has not been implemented")
    }

}

import XCTest
@testable import TGUIKit
final class EvidenceNavigationBarView: NavigationBarView {
    var freezeLayout = false
    public override func layout() {
        if !freezeLayout { super.layout() }
    }
}
final class DoneEvidenceCaptureTests: XCTestCase {
    func testCapture() throws {
        TGUIKitTestBootstrap.install()
        for before in [true, false] {
            let controller = ViewController()
            let root = View(frame: NSMakeRect(0, 0, 420, 120))
            root.backgroundColor = presentation.colors.background
            let nav = EvidenceNavigationBarView(frame: NSMakeRect(0, 0, 420, 64))
            root.addSubview(nav)
            let title = NSTextField(labelWithString: "Chat Automations")
            title.font = NSFont.systemFont(ofSize: 16, weight: .medium)
            title.textColor = presentation.colors.text
            title.sizeToFit()
            title.frame.origin = NSMakePoint(20, 26)
            root.addSubview(title)
            let bar: BarView
            if before {
                let button = BeforeTextButtonBarView(controller: controller, text: "Done")
                button.isLoading = true
                bar = button
            } else {
                let button = TextButtonBarView(controller: controller, text: "Done")
                button.isLoading = true
                bar = button
            }
            nav.switchViews(left: BarView(controller: controller), center: BarView(controller: controller), right: bar, controller: controller, style: .push, animationStyle: .init(duration: 0, function: .linear), liveSwiping: false)
            nav.needsLayout = false
            if let button = bar as? BeforeTextButtonBarView {
                button.isLoading = false
                button.set(text: "Done", for: .Normal)
                button.layoutSubtreeIfNeeded()
            } else if let button = bar as? TextButtonBarView {
                button.isLoading = false
                button.set(text: "Done", for: .Normal)
                if nav.needsLayout { nav.layoutSubtreeIfNeeded() }
            }
            nav.freezeLayout = true
            let note = NSTextField(labelWithString: "Native component test · fixed window size · no account data")
            note.font = NSFont.systemFont(ofSize: 11)
            note.textColor = presentation.colors.grayText
            note.sizeToFit()
            note.frame.origin = NSMakePoint(20, 86)
            root.addSubview(note)
            root.displayIfNeeded()
            let rep = try XCTUnwrap(root.bitmapImageRepForCachingDisplay(in: root.bounds))
            root.cacheDisplay(in: root.bounds, to: rep)
            let data = try XCTUnwrap(rep.representation(using: .png, properties: [:]))
            try data.write(to: URL(fileURLWithPath: "/Users/amir/Desktop/tg-macos/.build/review/done-\(before ? "before" : "after").png"))
        }
    }
}
