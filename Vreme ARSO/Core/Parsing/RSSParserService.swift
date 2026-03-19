import Foundation

struct RSSItem: Identifiable, Sendable {
    let id: String
    let title: String
    let description: String
    let link: URL?
    let publicationDate: Date?
}

struct RSSFeed: Sendable {
    let title: String
    let items: [RSSItem]
}

struct RSSParserService {
    func parse(data: Data) throws -> RSSFeed {
        let root = try XMLParserService().parse(data: data)
        let channel = root.firstChild(named: "channel") ?? root
        let items = channel.children(named: "item").map { itemNode in
            RSSItem(
                id: itemNode.textValue(forChild: "guid") ?? UUID().uuidString,
                title: itemNode.textValue(forChild: "title") ?? "",
                description: itemNode.textValue(forChild: "description") ?? "",
                link: itemNode.textValue(forChild: "link").flatMap(URL.init(string:)),
                publicationDate: itemNode.textValue(forChild: "pubDate").flatMap(DateFormatterSI.rss.date(from:))
            )
        }

        return RSSFeed(
            title: channel.textValue(forChild: "title") ?? "RSS vir",
            items: items
        )
    }
}
