import Foundation
import BibleStoryCore

// ⚠️ CONSENT-GATED BETA EXPORTER — the ONLY place app code sends interaction data off-device.
// This is the reviewed exception to the privacy guard (scripts/privacy-audit.sh skips this file).
// It MUST only be invoked after a parent has consented for a beta tester
// (see docs/PARENTAL-CONSENT-BETA.md). It is NOT wired into the normal app flow — a beta/parent
// screen calls `upload(...)` explicitly. Prefer a SELF-HOSTED LangFuse so children's beta data
// stays on infrastructure you control.
//
// ⚠️ VERIFY the ingestion payload shape against your LangFuse version before relying on it.

/// Connection details for a (self-hosted or cloud) LangFuse project.
struct LangFuseConfig {
    var host: URL            // e.g. https://your-langfuse.example.com
    var publicKey: String
    var secretKey: String
}

enum LangFuseExporterError: Error { case badResponse(Int) }

/// Uploads on-device `InteractionTrace`s to LangFuse's ingestion API. De-identified:
/// the only "who" is the anonymous `sessionID`.
struct LangFuseExporter {
    let config: LangFuseConfig

    func upload(_ traces: [InteractionTrace]) async throws {
        guard !traces.isEmpty else { return }

        let iso = ISO8601DateFormatter()
        let batch: [[String: Any]] = traces.map { t in
            [
                "id": UUID().uuidString,           // ingestion event id
                "type": "trace-create",
                "timestamp": iso.string(from: t.createdAt),
                "body": [
                    "id": t.id.uuidString,
                    "sessionId": t.sessionID.uuidString,   // anonymous — never a name
                    "name": "ask-poli",
                    "timestamp": iso.string(from: t.createdAt),
                    "input": t.question,
                    "output": t.responseText,
                    "metadata": [
                        "behaviorClass": t.behaviorClass,
                        "tier": t.tier,
                        "crisisFired": t.crisisFired,
                        "deflected": t.deflected,
                        "latencyMs": t.latencyMs,
                        "modelVersion": t.modelVersion,
                        "feedback": t.feedback?.rawValue ?? "none",
                    ],
                ],
            ]
        }

        var request = URLRequest(url: config.host.appendingPathComponent("/api/public/ingestion"))
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        let creds = "\(config.publicKey):\(config.secretKey)"
        let basic = Data(creds.utf8).base64EncodedString()
        request.setValue("Basic \(basic)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: ["batch": batch])

        let (_, response) = try await URLSession.shared.data(for: request)
        let code = (response as? HTTPURLResponse)?.statusCode ?? -1
        guard (200..<300).contains(code) else { throw LangFuseExporterError.badResponse(code) }
    }
}
