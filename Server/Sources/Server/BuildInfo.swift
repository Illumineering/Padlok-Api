import Foundation

enum BuildInfo {
    /// The deployed commit SHA, or `dev` outside a release.
    ///
    /// Each deploy uploads the binary to /opt/padlok/<environment>/releases/<sha>/Server,
    /// and supervisor starts it through the releases/current symlink, so the folder the executable
    /// resolves to is named after the commit. Nothing has to be stamped in at build time.
    static let version: String = {
        let executable = URL(fileURLWithPath: CommandLine.arguments[0]).resolvingSymlinksInPath()
        let release = executable.deletingLastPathComponent()
        guard
            release.deletingLastPathComponent().lastPathComponent == "releases",
            isCommitSHA(release.lastPathComponent)
        else {
            return "dev"
        }
        return release.lastPathComponent
    }()

    /// A full git commit SHA: 40 lowercase hexadecimal characters, as `$GITHUB_SHA` names
    /// the release folders.
    static func isCommitSHA(_ name: String) -> Bool {
        name.utf8.count == 40 && name.utf8.allSatisfy { (0x30...0x39).contains($0) || (0x61...0x66).contains($0) }
    }
}
