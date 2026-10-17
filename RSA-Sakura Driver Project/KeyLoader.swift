//
//  KeyLoader.swift
//  MyApp
//
//  Created by quanfu on 2026/10/14.
//
public import Combine
import Foundation

// MARK: - 密钥模型
struct EncryptionKey: Identifiable, Hashable {
    let id: String
    let name: String
}

@MainActor
final class KeyLoader: ObservableObject {
    static let shared = KeyLoader()
    
    @Published var keys: [EncryptionKey] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    func loadKeys() {
        isLoading = true
        errorMessage = nil

        // 从 AppPaths 取路径；若还没有就先 discover
        if AppPaths.shared.sharewareRoot == nil {
            AppPaths.shared.discover()
        }

        guard let root = AppPaths.shared.sharewareRoot,
              let macDir = AppPaths.shared.macDirectory,
              let xinitool = AppPaths.shared.xinitoolPath else {
            isLoading = false
            errorMessage = AppPaths.shared.errorMessage ?? "RSA-Sakura 路径未初始化"
            return
        }

        let rootPath = root.path
        let macPath = macDir.path
        let xinitoolPath = xinitool.path

        Task.detached(priority: .userInitiated) {
            let result = Self.runXinitool(
                xinitoolPath: xinitoolPath,
                workingDirectory: rootPath,
                macDirectory: macPath
            )
            await MainActor.run {
                self.isLoading = false
                switch result {
                case .success(let names):
                    self.keys = names.map { EncryptionKey(id: $0, name: $0) }
                case .failure(let error):
                    self.errorMessage = error.localizedDescription
                }
            }
        }
    }

    private nonisolated static func runXinitool(
        xinitoolPath: String,
        workingDirectory: String,
        macDirectory: String
    ) -> Result<[String], Error> {
        var env = ProcessInfo.processInfo.environment
        env["HOME"] = NSHomeDirectory()
        env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

        // 动态库搜索路径：mac 子目录是 libxscmutil.dylib 所在位置
        let libPaths = [
            macDirectory,
            "/usr/local/lib",
            workingDirectory
        ].joined(separator: ":")

        let existingDyld = env["DYLD_LIBRARY_PATH"] ?? ""
        let existingFallback = env["DYLD_FALLBACK_LIBRARY_PATH"] ?? ""
        env["DYLD_LIBRARY_PATH"] = existingDyld.isEmpty ? libPaths : "\(libPaths):\(existingDyld)"
        env["DYLD_FALLBACK_LIBRARY_PATH"] = existingFallback.isEmpty ? libPaths : "\(libPaths):\(existingFallback)"

        let process = Process()
        process.environment = env
        process.executableURL = URL(fileURLWithPath: xinitoolPath)
        process.arguments = [
            "-i", "./xrsao.ini",
            "-l",
            "-crsa_key_list",
            "-kkey"
        ]
        process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            let msg = """
            无法启动 xinitool
            路径: \(xinitoolPath)
            工作目录: \(workingDirectory)
            错误: \(error.localizedDescription)
            """
            return .failure(NSError(
                domain: "xinitool", code: -1,
                userInfo: [NSLocalizedDescriptionKey: msg]
            ))
        }

        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        if process.terminationStatus != 0 {
            return .failure(NSError(
                domain: "xinitool",
                code: Int(process.terminationStatus),
                userInfo: [NSLocalizedDescriptionKey: "xinitool 返回错误：\(output)"]
            ))
        }

        let names = output
            .split(separator: "\n")
            .map { $0.trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        return .success(names)
    }
}
