import Foundation

final class XMLNode: @unchecked Sendable {
    let name: String
    var text: String
    var attributes: [String: String]
    var children: [XMLNode]
    weak var parent: XMLNode?

    init(name: String, text: String = "", attributes: [String: String] = [:], children: [XMLNode] = []) {
        self.name = name
        self.text = text
        self.attributes = attributes
        self.children = children
    }

    func firstChild(named name: String) -> XMLNode? {
        children.first { $0.name == name }
    }

    func children(named name: String) -> [XMLNode] {
        children.filter { $0.name == name }
    }

    func textValue(forChild name: String) -> String? {
        firstChild(named: name)?.text.nilIfBlank
    }
}

struct XMLParserService {
    func parse(data: Data) throws -> XMLNode {
        let delegate = XMLTreeBuilder()
        let parser = Foundation.XMLParser(data: data)
        parser.delegate = delegate
        guard parser.parse(), let root = delegate.root else {
            throw parser.parserError ?? ARSOError.parsingFailed("XML dokumenta ni bilo mogoče razčleniti.")
        }
        return root
    }
}

private final class XMLTreeBuilder: NSObject, Foundation.XMLParserDelegate {
    private(set) var root: XMLNode?
    private var stack: [XMLNode] = []

    func parser(_ parser: Foundation.XMLParser, didStartElement elementName: String, namespaceURI: String?, qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        let node = XMLNode(name: elementName, attributes: attributeDict)
        if let parent = stack.last {
            node.parent = parent
            parent.children.append(node)
        } else {
            root = node
        }
        stack.append(node)
    }

    func parser(_ parser: Foundation.XMLParser, foundCharacters string: String) {
        stack.last?.text += string
    }

    func parser(_ parser: Foundation.XMLParser, foundCDATA CDATABlock: Data) {
        if let string = String(data: CDATABlock, encoding: .utf8) {
            stack.last?.text += string
        }
    }

    func parser(_ parser: Foundation.XMLParser, didEndElement elementName: String, namespaceURI: String?, qualifiedName qName: String?) {
        stack.last?.text = stack.last?.text.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        _ = stack.popLast()
    }
}
