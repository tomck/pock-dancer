import Foundation

struct DancerInfo {
    let name: String      // folder name, e.g. "Evan_Michele"
    let directory: URL
    let width: Int        // frame size in pixels (2x)
    let height: Int
    let count: Int
    let fps: Double

    /// "Evan_Michele" -> "Evan Michele", "ScoobyDoo" -> "Scooby Doo"
    var displayName: String {
        let spaced = name.replacingOccurrences(of: "_", with: " ")
        return spaced.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression)
    }
}

/// Finds the converted dancers (see convert.sh) and remembers which one is selected.
enum DancerLibrary {

    static let selectionDidChange = Notification.Name("com.tomkoch.pock.Dancer.selectionDidChange")
    static let directory = URL(fileURLWithPath: NSHomeDirectory())
        .appendingPathComponent("Library/Application Support/Pock/Dancers")

    private static let defaultsKey = "com.tomkoch.pock.Dancer.selected"

    private struct Meta: Decodable {
        let width: Int
        let height: Int
        let count: Int
        let fps: Double
    }

    static func all() -> [DancerInfo] {
        let folders = (try? FileManager.default.contentsOfDirectory(at: directory, includingPropertiesForKeys: nil)) ?? []
        return folders.compactMap(info(for:)).sorted {
            $0.displayName.localizedCaseInsensitiveCompare($1.displayName) == .orderedAscending
        }
    }

    /// The chosen dancer, or the first available one if the choice is unset or has been removed.
    static func selected() -> DancerInfo? {
        let dancers = all()
        let name = UserDefaults.standard.string(forKey: defaultsKey)
        return dancers.first { $0.name == name } ?? dancers.first
    }

    static func select(_ name: String) {
        UserDefaults.standard.set(name, forKey: defaultsKey)
        NotificationCenter.default.post(name: selectionDidChange, object: nil)
    }

    private static func info(for folder: URL) -> DancerInfo? {
        guard let data = try? Data(contentsOf: folder.appendingPathComponent("meta.json")),
              let meta = try? JSONDecoder().decode(Meta.self, from: data),
              meta.count > 0, meta.width > 0, meta.height > 0
        else { return nil }
        return DancerInfo(name: folder.lastPathComponent, directory: folder,
                          width: meta.width, height: meta.height, count: meta.count, fps: meta.fps)
    }
}
