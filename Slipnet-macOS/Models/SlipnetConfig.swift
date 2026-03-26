import Foundation

struct SlipnetConfig: Identifiable, Codable, Hashable {
    var id: UUID
    var name: String
    var uri: String // slipnet://BASE64... or slipnet-enc://BASE64...
    var dnsResolver: String
    var isDirect: Bool
    var localPort: String
    var localHost: String
    var utlsFingerprint: String
    var querySize: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        name: String = "New Profile",
        uri: String = "",
        dnsResolver: String = "",
        isDirect: Bool = false,
        localPort: String = "",
        localHost: String = "127.0.0.1",
        utlsFingerprint: String = "",
        querySize: String = "",
        createdAt: Date = Date()
    ) {
        self.id = id
        self.name = name
        self.uri = uri
        self.dnsResolver = dnsResolver
        self.isDirect = isDirect
        self.localPort = localPort
        self.localHost = localHost
        self.utlsFingerprint = utlsFingerprint
        self.querySize = querySize
        self.createdAt = createdAt
    }

    func buildArguments() -> [String] {
        var args: [String] = []

        if !dnsResolver.isEmpty {
            args += ["--dns", dnsResolver]
        }
        if isDirect {
            args.append("--direct")
        }
        if !localPort.isEmpty {
            args += ["--port", localPort]
        }
        if localHost != "127.0.0.1" && !localHost.isEmpty {
            args += ["--host", localHost]
        }
        if !utlsFingerprint.isEmpty {
            args += ["--utls", utlsFingerprint]
        }
        if !querySize.isEmpty {
            args += ["--query-size", querySize]
        }
        if !uri.isEmpty {
            args.append(uri)
        }

        return args
    }
}
