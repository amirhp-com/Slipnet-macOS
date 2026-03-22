import Foundation

struct ScanConfig: Codable {
    var domain: String = ""
    var ipsFile: String = ""
    var singleIP: String = ""
    var timeout: String = "3000"
    var concurrency: String = "100"
    var port: String = "53"
    var enableE2E: Bool = false
    var e2eOnly: Bool = false
    var pubkey: String = ""
    var useNoizDNS: Bool = false
    var e2eConcurrency: String = "10"
    var e2eTimeout: String = "15000"
    var e2eURL: String = ""
    var e2eThreshold: String = "2"
    var configURI: String = ""
    var verifyPrism: Bool = false
    var prismTimeout: String = ""
    var probes: String = "5"
    var threshold: String = "2"
    var responseSize: String = ""
    var prefilter: Bool = false
    var querySize: String = ""
    var outputFile: String = ""

    func buildArguments() -> [String] {
        var args: [String] = ["scan"]

        if !configURI.isEmpty {
            args += ["--config", configURI]
        } else if !domain.isEmpty {
            args += ["--domain", domain]
        }

        if !ipsFile.isEmpty {
            args += ["--ips", ipsFile]
        }
        if !singleIP.isEmpty {
            args += ["--ip", singleIP]
        }
        if timeout != "3000" && !timeout.isEmpty {
            args += ["--timeout", timeout]
        }
        if concurrency != "100" && !concurrency.isEmpty {
            args += ["--concurrency", concurrency]
        }
        if port != "53" && !port.isEmpty {
            args += ["--port", port]
        }
        if e2eOnly {
            args.append("--e2e-only")
        } else if enableE2E {
            args.append("--e2e")
        }
        if !pubkey.isEmpty {
            args += ["--pubkey", pubkey]
        }
        if useNoizDNS {
            args.append("--noizdns")
        }
        if e2eConcurrency != "10" && !e2eConcurrency.isEmpty {
            args += ["--e2e-concurrency", e2eConcurrency]
        }
        if e2eTimeout != "15000" && !e2eTimeout.isEmpty {
            args += ["--e2e-timeout", e2eTimeout]
        }
        if !e2eURL.isEmpty {
            args += ["--e2e-url", e2eURL]
        }
        if e2eThreshold != "2" && !e2eThreshold.isEmpty {
            args += ["--e2e-threshold", e2eThreshold]
        }
        if verifyPrism {
            args.append("--verify")
        }
        if !prismTimeout.isEmpty {
            args += ["--prism-timeout", prismTimeout]
        }
        if probes != "5" && !probes.isEmpty {
            args += ["--probes", probes]
        }
        if threshold != "2" && !threshold.isEmpty {
            args += ["--threshold", threshold]
        }
        if !responseSize.isEmpty {
            args += ["--response-size", responseSize]
        }
        if prefilter {
            args.append("--prefilter")
        }
        if !querySize.isEmpty {
            args += ["--query-size", querySize]
        }
        if !outputFile.isEmpty {
            args += ["--output", outputFile]
        }

        return args
    }
}
