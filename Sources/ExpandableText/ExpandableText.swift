//
//  ExpandableText.swift
//  ExpandableText
//
//  Created by ned on 23/02/23.
//

import Foundation
import SwiftUI

/**
An expandable text view that displays a truncated version of its contents with a "show more" button that expands the view to show the full contents.

 To create a new ExpandableText view, use the init method and provide the initial text string as a parameter. The text string will be automatically trimmed of any leading or trailing whitespace and newline characters.

Example usage with default parameters:
 ```swift
ExpandableText("Lorem ipsum dolor sit amet, consectetur adipiscing elit...")
    .font(.body)
    .foregroundColor(.primary)
    .lineLimit(3)
    .moreButtonText("more")
    .moreButtonColor(.accentColor)
    .expandAnimation(.default)
    .trimMultipleNewlinesWhenTruncated(true)
 ```
*/

public struct ExpandableText: View {

    @State private var isExpanded: Bool = false
    @State private var isTruncated: Bool = false

    @State private var intrinsicSize: CGSize = .zero
    @State private var truncatedSize: CGSize = .zero
    @State private var moreTextSize: CGSize = .zero

    private var attributedString: AttributedString?
    private var onTapGesture: (() -> Void)?
    private let text: String
    internal var font: Font = .body
    internal var color: Color? = nil
    internal var lineLimit: Int = 3
    internal var moreButtonText: String = "more"
    internal var lessButtonText: String = "Less"
    internal var moreButtonFont: Font?
    internal var moreButtonColor: Color = .accentColor
    internal var expandAnimation: Animation? = nil
    internal var collapseEnabled: Bool = false
    internal var trimMultipleNewlinesWhenTruncated: Bool = true
    
    /**
     Initializes a new `ExpandableText` instance with the specified text string, trimmed of any leading or trailing whitespace and newline characters.
     - Parameter text: The initial text string to display in the `ExpandableText` view.
     - Returns: A new `ExpandableText` instance with the specified text string and trimming applied.
     */
    public init(_ text: String, onTapGesture: (() -> Void)? = nil) {
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.onTapGesture = onTapGesture
    }

    public init(
        _ text: String,
        expandAnimation: Animation,
        onTapGesture: (() -> Void)? = nil
    ) {
        self.text = text.trimmingCharacters(in: .whitespacesAndNewlines)
        self.onTapGesture = onTapGesture
        self.expandAnimation = expandAnimation
    }

    public init(_ attributedString: AttributedString, onTapGesture: (() -> Void)? = nil) {
        self.attributedString = attributedString
        self.onTapGesture = onTapGesture
        self.text = String(attributedString.characters[...])
    }

    public init(
        _ attributedString: AttributedString,
        expandAnimation: Animation,
        onTapGesture: (() -> Void)? = nil
    ) {
        self.attributedString = attributedString
        self.onTapGesture = onTapGesture
        self.text = String(attributedString.characters[...])
        self.expandAnimation = expandAnimation
    }

    public var body: some View {
        content
            .lineLimit(isExpanded ? nil : lineLimit)
            .applyingTruncationMask(size: moreTextSize, enabled: shouldShowMoreButton)
            .readSize { size in
                truncatedSize = size
                if !isExpanded {
                    isTruncated = truncatedSize != intrinsicSize
                }
            }
            .background(
                content
                    .lineLimit(nil)
                    .fixedSize(horizontal: false, vertical: true)
                    .hidden()
                    .readSize { size in
                        intrinsicSize = size
                        if !isExpanded {
                            isTruncated = truncatedSize != intrinsicSize
                        }
                    }
            )
            .background(
                Text(moreButtonText)
                    .font(moreButtonFont ?? font)
                    .padding(.vertical, 8)
                    .padding(.horizontal, 6)
                    .hidden()
                    .readSize { moreTextSize = $0 }
            )
            .contentShape(Rectangle())
            .onTapGesture {
                if let onTapGesture {
                    onTapGesture()
                } else if (isExpanded && collapseEnabled) ||
                     shouldShowMoreButton {
                    toggleExpanded()
                }
            }
            .modifier(OverlayAdapter(alignment: .trailingLastTextBaseline, view: {
                if shouldShowToggleButton {
                    Button {
                        toggleExpanded()
                    } label: {
                        Text(toggleButtonText)
                            .font(moreButtonFont ?? font)
                            .foregroundColor(moreButtonColor)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 6)
                            .contentShape(Rectangle())
                    }
                }
            }))
    }
    
    private var content: some View {
        if let attributedString = attributedString {
            AnyView(
                Text(attributedString)
                    .font(font)
                    .applyForegroundColorIfNeeded(color)
                    .frame(maxWidth: .infinity, alignment: .leading)
            )
        } else {
            AnyView(
                Text(.init(
                    trimMultipleNewlinesWhenTruncated
                    ? (shouldShowMoreButton ? textTrimmingDoubleNewlines : text)
                    : text
                ))
                .font(font)
                .applyForegroundColorIfNeeded(color)
                .frame(maxWidth: .infinity, alignment: .leading)
            )
        }
    }

    private var shouldShowMoreButton: Bool {
        !isExpanded && isTruncated
    }

    private var shouldShowToggleButton: Bool {
        isTruncated
    }

    private var toggleButtonText: String {
        isExpanded ? lessButtonText : moreButtonText
    }
    
    private var textTrimmingDoubleNewlines: String {
        text.replacingOccurrences(of: #"\n\s*\n"#, with: "\n", options: .regularExpression)
    }

    private func toggleExpanded() {
        if let expandAnimation {
            withAnimation(expandAnimation) { isExpanded.toggle() }
        } else {
            isExpanded.toggle()
        }
    }
}

private extension View {
    @ViewBuilder
    func applyForegroundColorIfNeeded(_ color: Color?) -> some View {
        if let color = color {
            if #available(iOS 15.0, *) {
                self.foregroundStyle(color)
            } else {
                self.foregroundColor(color)
            }
        } else {
            self
        }
    }
}
#if DEBUG
struct ExpandableText_Previews: PreviewProvider {
    static var previews: some View {
        ExpandableText(
            "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Integer in augue ut ipsum euismod volutpat. Praesent non justo sed nisl feugiat posuere."
        )
            .font(.body)
            .lineLimit(3)
            .moreButtonText("more")
            .lessButtonText("less")
            .moreButtonColor(.blue)
            .padding()
            .previewLayout(.sizeThatFits)
    }
}
#endif

