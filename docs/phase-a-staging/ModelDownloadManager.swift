// STAGED (Phase A) — not in the build until the model archive is hosted and the app
// target is ready to wire `MLXModelEngine`. Pure Foundation; no MLX dependency here, so
// this file *could* compile today if dropped into the app target, but it has no caller
// and downloads a URL that doesn't exist yet — keeping it staged until Phase A wiring.

import Foundation
import CryptoKit

/// Lifecycle states for the on-device model download/unpack.
public enum ModelDownloadState: Equatable, Sendable {
    case idle
    case downloading
    case unpacking
    case ready
    case failed(String)
}

/// First-launch download + integrity-check + unpack of the ~2GB converted on-device model
/// (Qwen3-4B-Instruct-2507 + sbc-lora adapter merged, 4-bit quantized via `mlx_lm convert`).
///
/// Downloads once to Application Support, verifies a SHA256, unzips, and caches the local
/// model directory URL for `MLXModelEngine` to load. Resumable across app relaunches and
/// network interruptions via `URLSessionDownloadTask`'s resume-data support.
@Observable
@MainActor
public final class ModelDownloadManager: NSObject {

    // MARK: - Public, observable state

    public private(set) var progress: Double = 0
    public private(set) var state: ModelDownloadState = .idle

    /// The directory containing the unpacked model, once `state == .ready`.
    public private(set) var modelDirectoryURL: URL?

    // MARK: - Configuration

    private let remoteArchiveURL: URL
    private let expectedSHA256Hex: String
    private let modelDirectoryName: String

    // MARK: - Paths

    private lazy var applicationSupportDirectory: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("SBCModel", isDirectory: true)
    }()

    private var archiveDestinationURL: URL {
        applicationSupportDirectory.appendingPathComponent("model.zip")
    }

    private var resumeDataURL: URL {
        applicationSupportDirectory.appendingPathComponent("model.download.resume")
    }

    private var unpackedModelDirectoryURL: URL {
        applicationSupportDirectory.appendingPathComponent(modelDirectoryName, isDirectory: true)
    }

    /// Marker file written only after a full verify+unpack succeeds, so a half-finished
    /// unpack from a killed app is never mistaken for a ready model.
    private var readyMarkerURL: URL {
        unpackedModelDirectoryURL.appendingPathComponent(".ready")
    }

    // MARK: - Session

    private lazy var urlSession: URLSession = {
        let config = URLSessionConfiguration.default
        return URLSession(configuration: config, delegate: self, delegateQueue: nil)
    }()

    private var downloadTask: URLSessionDownloadTask?

    /// Continuation used to bridge the delegate callbacks back into the async `start()` call.
    private var completionContinuation: CheckedContinuation<Void, Error>?

    // MARK: - Init

    /// - Parameters:
    ///   - remoteArchiveURL: HTTPS URL to the hosted `.zip` of the converted MLX model directory.
    ///   - expectedSHA256Hex: SHA256 of the downloaded zip, lowercase hex, for integrity verification.
    ///   - modelDirectoryName: Name of the directory the zip unpacks to (e.g. "sbc-mlx-4bit").
    public init(
        remoteArchiveURL: URL,
        expectedSHA256Hex: String,
        modelDirectoryName: String = "sbc-mlx-4bit"
    ) {
        self.remoteArchiveURL = remoteArchiveURL
        self.expectedSHA256Hex = expectedSHA256Hex.lowercased()
        self.modelDirectoryName = modelDirectoryName
        super.init()
    }

    // MARK: - Public API

    /// Ensures the model is present locally, downloading/unpacking if needed. Safe to call
    /// repeatedly (e.g. on every app launch); returns immediately if already `.ready`.
    public func ensureModelAvailable() async {
        if FileManager.default.fileExists(atPath: readyMarkerURL.path) {
            modelDirectoryURL = unpackedModelDirectoryURL
            state = .ready
            progress = 1
            return
        }

        do {
            try FileManager.default.createDirectory(
                at: applicationSupportDirectory,
                withIntermediateDirectories: true
            )
            state = .downloading
            try await download()
            state = .unpacking
            try verifyChecksum()
            try unpackArchive()
            try markReady()
            modelDirectoryURL = unpackedModelDirectoryURL
            state = .ready
            progress = 1
            cleanupArchive()
        } catch {
            state = .failed(String(describing: error))
        }
    }

    /// Cancels an in-flight download, persisting resume data so a later `ensureModelAvailable()`
    /// call can pick up where it left off.
    public func cancel() {
        downloadTask?.cancel { [weak self] resumeData in
            guard let self else { return }
            if let resumeData {
                try? resumeData.write(to: self.resumeDataURL)
            }
        }
    }

    // MARK: - Download

    private func download() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
            self.completionContinuation = continuation

            if let resumeData = try? Data(contentsOf: resumeDataURL) {
                self.downloadTask = urlSession.downloadTask(withResumeData: resumeData)
                try? FileManager.default.removeItem(at: resumeDataURL)
            } else {
                self.downloadTask = urlSession.downloadTask(with: remoteArchiveURL)
            }
            self.downloadTask?.resume()
        }
    }

    // MARK: - Verification

    private func verifyChecksum() throws {
        let data = try Data(contentsOf: archiveDestinationURL, options: .mappedIfSafe)
        let digest = SHA256.hash(data: data)
        let hex = digest.map { String(format: "%02x", $0) }.joined()
        guard hex == expectedSHA256Hex else {
            throw ModelDownloadError.checksumMismatch(expected: expectedSHA256Hex, actual: hex)
        }
    }

    // MARK: - Unpack

    private func unpackArchive() throws {
        // `Archive.unzipItem` (Apple's Compression/`ZIPFoundation`-style API) is not available
        // in plain Foundation on all platforms; this uses `Process` to shell out to the
        // system `unzip` (available on iOS via `/usr/bin/unzip`... NOTE: NOT AVAILABLE on
        // iOS device sandboxes). VERIFY AT WIRING TIME: iOS has no `Process`/shell-out —
        // this must be replaced with `Foundation`'s `FileManager` + a real unzip library
        // (e.g. ZIPFoundation via SPM, or Apple's Archive framework) before this ships.
        // Left as pseudo-code so the responsibility (verify → unpack → mark ready → prune
        // the zip) is unambiguous; the concrete unzip call is a Phase A TODO.
        try FileManager.default.createDirectory(
            at: unpackedModelDirectoryURL,
            withIntermediateDirectories: true
        )
        throw ModelDownloadError.unzipNotImplemented
    }

    private func markReady() throws {
        FileManager.default.createFile(atPath: readyMarkerURL.path, contents: Data())
    }

    private func cleanupArchive() {
        try? FileManager.default.removeItem(at: archiveDestinationURL)
    }
}

// MARK: - URLSessionDownloadDelegate

extension ModelDownloadManager: URLSessionDownloadDelegate {

    public nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didWriteData bytesWritten: Int64,
        totalBytesWritten: Int64,
        totalBytesExpectedToWrite: Int64
    ) {
        guard totalBytesExpectedToWrite > 0 else { return }
        let fraction = Double(totalBytesWritten) / Double(totalBytesExpectedToWrite)
        Task { @MainActor [weak self] in
            self?.progress = fraction
        }
    }

    public nonisolated func urlSession(
        _ session: URLSession,
        downloadTask: URLSessionDownloadTask,
        didFinishDownloadingTo location: URL
    ) {
        Task { @MainActor [weak self] in
            guard let self else { return }
            do {
                if FileManager.default.fileExists(atPath: self.archiveDestinationURL.path) {
                    try FileManager.default.removeItem(at: self.archiveDestinationURL)
                }
                try FileManager.default.moveItem(at: location, to: self.archiveDestinationURL)
                self.completionContinuation?.resume()
            } catch {
                self.completionContinuation?.resume(throwing: error)
            }
            self.completionContinuation = nil
        }
    }

    public nonisolated func urlSession(
        _ session: URLSession,
        task: URLSessionTask,
        didCompleteWithError error: Error?
    ) {
        guard let error else { return }
        Task { @MainActor [weak self] in
            self?.completionContinuation?.resume(throwing: error)
            self?.completionContinuation = nil
        }
    }
}

// MARK: - Errors

public enum ModelDownloadError: Error, Sendable {
    case checksumMismatch(expected: String, actual: String)
    case unzipNotImplemented
}
