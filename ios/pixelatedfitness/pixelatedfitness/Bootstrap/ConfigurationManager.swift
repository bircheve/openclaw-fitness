import Foundation

struct ConfigurationManager {
    private static var configPlist: [String: Any]? = {
        guard let path = Bundle.main.path(forResource: "Config-Debug", ofType: "plist"),
              let plist = NSDictionary(contentsOfFile: path) as? [String: Any] else {
            return nil
        }
        return plist
    }()

    static var bridgeBaseURL: String {
        configPlist?["Bridge_Base_URL"] as? String ?? "http://localhost:18792"
    }
}
