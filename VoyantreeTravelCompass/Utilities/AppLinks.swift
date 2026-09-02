import UIKit

enum AppLinks: String {
    case privacy = "https://voyantreetravel340compass.site/privacy/445"
    case terms = "https://voyantreetravel340compass.site/terms/445"

    var url: URL? { URL(string: rawValue) }

    static func open(_ link: AppLinks) {
        if let url = link.url {
            UIApplication.shared.open(url)
        }
    }
}
