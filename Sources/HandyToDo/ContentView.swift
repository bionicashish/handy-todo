import SwiftUI
import CoreText

// MARK: - Helpers

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        self.init(
            red:   Double((int >> 16) & 0xFF) / 255,
            green: Double((int >> 8)  & 0xFF) / 255,
            blue:  Double( int        & 0xFF) / 255
        )
    }
}

private extension Font {
    static func googleSansFlex(size: CGFloat = 14) -> Font {
        let variationKey = NSFontDescriptor.AttributeName(
            rawValue: kCTFontVariationAttribute as String
        )
        let variations: [NSNumber: NSNumber] = [
            NSNumber(value: 1_196_572_996): NSNumber(value: 100.0), // GRAD
            NSNumber(value: 1_380_928_836): NSNumber(value: 100.0)  // ROND
        ]
        let descriptor = NSFontDescriptor(name: "Google Sans Flex", size: size)
            .addingAttributes([variationKey: variations])
        if let nsFont = NSFont(descriptor: descriptor, size: size) {
            return Font(nsFont)
        }
        return .system(size: size)
    }
}

// MARK: - Checkmark (from handy-check.svg)

private struct CheckmarkShape: Shape {
    func path(in rect: CGRect) -> Path {
        let sx = rect.width  / 12
        let sy = rect.height / 12
        var p = Path()
        p.move(to:    CGPoint(x: 1.875 * sx, y: 6.75  * sy))
        p.addLine(to: CGPoint(x: 4.5   * sx, y: 9.375 * sy))
        p.addLine(to: CGPoint(x: 10.5  * sx, y: 3.375 * sy))
        return p
    }
}

// MARK: - Custom Checkbox

private struct HandyCheckbox: View {
    @Binding var isOn: Bool
    @State private var isHovered = false

    private let ink  = Color(hex: "1b1b1b")
    private let blue = Color(hex: "387DFF")
    private let hov  = Color(hex: "f5f5f5")

    var body: some View {
        ZStack {
            if isOn {
                RoundedRectangle(cornerRadius: 5).fill(blue)
                CheckmarkShape()
                    .stroke(Color.white,
                            style: StrokeStyle(lineWidth: 1.5, lineCap: .round, lineJoin: .round))
                    .frame(width: 12, height: 12)
            } else {
                RoundedRectangle(cornerRadius: 5).fill(isHovered ? hov : .white)
                RoundedRectangle(cornerRadius: 5)
                    .stroke(ink.opacity(isHovered ? 0.7 : 0.3), lineWidth: 0.5)
            }
        }
        .frame(width: 16, height: 16)
        .animation(.easeInOut(duration: 0.12), value: isOn)
        .onHover { isHovered = $0 }
        .onTapGesture { isOn.toggle() }
    }
}

// MARK: - NSTextView wrapper (single render path, consistent line height)

private struct TodoTextView: NSViewRepresentable {
    @Binding var text: String
    var isCompleted: Bool
    @Binding var isEditing: Bool
    var nsFont: NSFont
    var onCommit: () -> Void

    private let lineHeight: CGFloat = 18
    private static let ink = NSColor(red: 0x1b/255, green: 0x1b/255, blue: 0x1b/255, alpha: 1)

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeNSView(context: Context) -> NSScrollView {
        let tv = context.coordinator.textView
        tv.delegate = context.coordinator
        tv.isEditable = true   // always editable; delegate drives isEditing state
        tv.isSelectable = true
        tv.isRichText = false
        tv.drawsBackground = false
        tv.backgroundColor = .clear
        tv.textContainerInset = .zero
        tv.textContainer?.lineFragmentPadding = 0
        tv.textContainer?.widthTracksTextView = true
        tv.textContainer?.heightTracksTextView = false
        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.autoresizingMask = [.width]
        tv.font = nsFont

        let sv = NSScrollView()
        sv.documentView = tv
        sv.hasVerticalScroller = false
        sv.hasHorizontalScroller = false
        sv.drawsBackground = false
        sv.backgroundColor = .clear
        sv.autohidesScrollers = true
        // Pin document view to top of clip view
        sv.contentView.postsBoundsChangedNotifications = false
        return sv
    }

    func updateNSView(_ sv: NSScrollView, context: Context) {
        applyContent(to: context.coordinator.textView)
        context.coordinator.parent = self
    }

    func sizeThatFits(_ proposal: ProposedViewSize, nsView sv: NSScrollView, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0 else { return nil }
        let tv = context.coordinator.textView
        tv.frame.size.width = width
        tv.sizeToFit()
        return CGSize(width: width, height: max(tv.frame.height, lineHeight))
    }

    private func applyContent(to tv: NSTextView) {
        let ps = NSMutableParagraphStyle()
        ps.minimumLineHeight = lineHeight
        ps.maximumLineHeight = lineHeight

        let textColor: NSColor = isCompleted
            ? NSColor(red: 0xa4/255, green: 0xa4/255, blue: 0xa4/255, alpha: 1)
            : Self.ink
        var attrs: [NSAttributedString.Key: Any] = [
            .font: nsFont,
            .foregroundColor: textColor,
            .paragraphStyle: ps
        ]
        if isCompleted && !isEditing {
            attrs[.strikethroughStyle] = NSUnderlineStyle.single.rawValue
            attrs[.strikethroughColor] = NSColor(red: 0xba/255, green: 0xba/255, blue: 0xba/255, alpha: 1)
        }

        if tv.string != text {
            tv.string = text
        }
        let full = NSRange(location: 0, length: (tv.string as NSString).length)
        tv.textStorage?.setAttributes(attrs, range: full)
        tv.typingAttributes = attrs
        tv.sizeToFit()
    }

    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: TodoTextView
        let textView = NSTextView()

        init(_ parent: TodoTextView) { self.parent = parent }

        func textDidBeginEditing(_ n: Notification) {
            parent.isEditing = true
        }

        func textDidEndEditing(_ n: Notification) {
            parent.isEditing = false
        }

        func textDidChange(_ n: Notification) {
            guard let tv = n.object as? NSTextView else { return }
            parent.text = tv.string
        }

        func textView(_ tv: NSTextView, doCommandBy selector: Selector) -> Bool {
            if selector == #selector(NSResponder.insertNewline(_:)) {
                tv.window?.makeFirstResponder(nil)  // resign focus → textDidEndEditing
                parent.onCommit()
                return true
            }
            return false
        }
    }
}

// MARK: - Editable item row

private struct EditableItemRow: View {
    @Binding var item: ChecklistItem
    @State private var isEditing = false

    private let ink = Color(hex: "1b1b1b")
    private var nsFont: NSFont {
        let key = NSFontDescriptor.AttributeName(rawValue: kCTFontVariationAttribute as String)
        let vars: [NSNumber: NSNumber] = [
            NSNumber(value: 1_196_572_996): 100,
            NSNumber(value: 1_380_928_836): 100
        ]
        let desc = NSFontDescriptor(name: "Google Sans Flex", size: 14)
            .addingAttributes([key: vars])
        return NSFont(descriptor: desc, size: 14) ?? .systemFont(ofSize: 14)
    }

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            HandyCheckbox(isOn: $item.isCompleted)
                .padding(.vertical, 3)

            TodoTextView(
                text: $item.title,
                isCompleted: item.isCompleted,
                isEditing: $isEditing,
                nsFont: nsFont,
                onCommit: { isEditing = false }
            )
            .padding(.vertical, 2)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
    }
}

// MARK: - Ghost "add new" row (always last)

private struct GhostInputRow: View {
    var onAdd: (String) -> Void
    var autoFocus: Bool

    @State  private var text = ""
    @FocusState private var focused: Bool

    private let ink = Color(hex: "1b1b1b")

    var body: some View {
        HStack(alignment: .top, spacing: 10) {
            // Dimmed unchecked checkbox — purely decorative
            ZStack {
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color(hex: "A4A4A4"), lineWidth: 0.5)
                    .frame(width: 16, height: 16)
            }
            .padding(.vertical, 3)

            TextField(
                "",
                text: $text,
                prompt: Text("your to-do...")
                    .font(.googleSansFlex(size: 14))
                    .foregroundColor(Color(hex: "A4A4A4")),
                axis: .vertical
            )
            .font(.googleSansFlex(size: 14))
            .foregroundStyle(text.isEmpty ? Color(hex: "A4A4A4") : ink)
            .textFieldStyle(.plain)
            .padding(.vertical, 2)
            .focused($focused)
            .onSubmit {
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                if !trimmed.isEmpty { onAdd(trimmed) }
                text = ""
                DispatchQueue.main.async { focused = true }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 6)
        .onAppear {
            if autoFocus {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) { focused = true }
            }
        }
        .onChange(of: autoFocus) { _, shouldFocus in
            if shouldFocus {
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { focused = true }
            }
        }
    }
}

// MARK: - Root view

struct ContentView: View {
    @State var store: ChecklistStore

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    ForEach($store.items) { $item in
                        EditableItemRow(item: $item)
                    }

                    GhostInputRow(
                        onAdd: { store.add($0) },
                        autoFocus: store.items.isEmpty
                    )
                }
                .padding(.horizontal, 24)
                .padding(.top, 32)
                .padding(.bottom, 64)
            }

            Button(action: store.clearAll) {
                Image(systemName: "arrow.counterclockwise")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundStyle(Color(hex: "1b1b1b").opacity(0.35))
            }
            .buttonStyle(.plain)
            .padding(.trailing, 24)
            .padding(.bottom, 28)
            .help("Clear all tasks")
        }
        .frame(width: 400, height: 520)
        .background(Color.white)
        .onKeyPress(.escape) {
            NSApp.keyWindow?.orderOut(nil)
            return .handled
        }
    }
}
