import Foundation

struct LegalDocument: Equatable {
    enum Block: Equatable {
        case heading(String)
        case sectionHeading(String)
        case updated(String)
        case paragraph(String)
        case bullets([String])
    }

    let blocks: [Block]
}

enum LegalDocumentLoader {
    /// Parses one of the bundled `terms.html` / `privacy.html` resources into
    /// native blocks (`h1`, `h2`, `p`, `ul/li`, plus the "Last updated" line).
    /// Tag-by-tag scan, not a full HTML parser - the bundled files are static.
    static func load(_ fileName: String) -> LegalDocument {
        guard
            let url = Bundle.main.url(forResource: fileName, withExtension: "html"),
            let html = try? String(contentsOf: url, encoding: .utf8)
        else {
            return LegalDocument(blocks: [])
        }
        return parse(html: html)
    }

    static func parse(html: String) -> LegalDocument {
        let body = sliceBody(from: html)
        var blocks: [LegalDocument.Block] = []
        var cursor = body.startIndex

        while cursor < body.endIndex {
            guard let openStart = body[cursor...].firstIndex(of: "<") else { break }
            guard let openEnd = body[openStart...].firstIndex(of: ">") else { break }
            let tag = body[body.index(after: openStart)..<openEnd]
            let tagName = parseTagName(tag)

            let contentStart = body.index(after: openEnd)
            let closingMarker = "</\(tagName)>"
            guard let closingRange = body.range(of: closingMarker, range: contentStart..<body.endIndex) else {
                cursor = contentStart
                continue
            }

            let inner = body[contentStart..<closingRange.lowerBound]
            let attrs = String(tag)

            switch tagName {
            case "h1":
                blocks.append(.heading(decode(strip(String(inner)))))
            case "h2":
                blocks.append(.sectionHeading(decode(strip(String(inner)))))
            case "p":
                let text = decode(strip(String(inner)))
                if attrs.contains("class=\"updated\"") {
                    blocks.append(.updated(text))
                } else if !text.isEmpty {
                    blocks.append(.paragraph(text))
                }
            case "ul":
                let items = parseListItems(String(inner))
                if !items.isEmpty { blocks.append(.bullets(items)) }
            default:
                break
            }

            cursor = closingRange.upperBound
        }

        return LegalDocument(blocks: blocks)
    }

    private static func sliceBody(from html: String) -> Substring {
        if
            let openRange = html.range(of: "<body"),
            let bodyOpenEnd = html[openRange.lowerBound...].firstIndex(of: ">"),
            let closeRange = html.range(of: "</body>")
        {
            return html[html.index(after: bodyOpenEnd)..<closeRange.lowerBound]
        }
        return Substring(html)
    }

    private static func parseTagName(_ tag: Substring) -> String {
        var name = ""
        for char in tag {
            if char.isWhitespace || char == "/" { break }
            name.append(char)
        }
        return name.lowercased()
    }

    private static func parseListItems(_ inner: String) -> [String] {
        var items: [String] = []
        var cursor = inner.startIndex
        while cursor < inner.endIndex {
            guard let liOpen = inner.range(of: "<li", range: cursor..<inner.endIndex) else { break }
            guard let openEnd = inner[liOpen.upperBound...].firstIndex(of: ">") else { break }
            let contentStart = inner.index(after: openEnd)
            guard let liClose = inner.range(of: "</li>", range: contentStart..<inner.endIndex) else { break }
            let text = decode(strip(String(inner[contentStart..<liClose.lowerBound])))
            if !text.isEmpty { items.append(text) }
            cursor = liClose.upperBound
        }
        return items
    }

    /// Removes any remaining inline tags (e.g. `<strong>`) and collapses
    /// whitespace - we keep the text, drop the tag.
    private static func strip(_ raw: String) -> String {
        var result = ""
        var inTag = false
        for char in raw {
            if char == "<" { inTag = true; continue }
            if char == ">" { inTag = false; continue }
            if !inTag { result.append(char) }
        }
        return result
            .replacing("\n", with: " ")
            .replacing("\t", with: " ")
            .split(separator: " ", omittingEmptySubsequences: true)
            .joined(separator: " ")
    }

    private static func decode(_ text: String) -> String {
        text
            .replacing("&amp;",  with: "&")
            .replacing("&lt;",   with: "<")
            .replacing("&gt;",   with: ">")
            .replacing("&quot;", with: "\"")
            .replacing("&#39;",  with: "'")
            .replacing("&nbsp;", with: " ")
    }
}
