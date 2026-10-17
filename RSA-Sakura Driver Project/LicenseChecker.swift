//
//  LicenseChecker.swift
//  RSA-Sakura Driver Project
//
//  Created by quanfu on 2026/10/14.
//
import Foundation
import Combine

enum LicenseState: Equatable {
    case unknown          // 还没检测
    case notInstalled     // 没找到 xrsaoapp.sw
    case locked           // 输出里出现 Trial License
    case unlocked         // 输出正常，未出现 Trial License
    case error(String)    // 其他错误

    var labelText: String {
        switch self {
        case .unknown:        return "检测中…"
        case .notInstalled:   return "未安装"
        case .locked:         return "已锁定 locked"
        case .unlocked:       return "已解锁 unlocked"
        case .error(let msg): return "错误：\(msg)"
        }
    }
}

@MainActor
final class LicenseChecker: ObservableObject {
    @Published private(set) var state: LicenseState = .unknown
    @Published private(set) var rawOutput: String = ""

    func check() {
        state = .unknown
        rawOutput = ""

        // 👇 每次检测都重新 discover，不要跳过
        AppPaths.shared.discover()

        guard let xrsaoapp = AppPaths.shared.xrsaoappPath else {
            state = .notInstalled
            return
        }

        // 👇 额外做一次文件存在性检查，防止软链被删但路径还残留在内存里
        guard FileManager.default.fileExists(atPath: xrsaoapp.path) else {
            state = .notInstalled
            return
        }

        let xrsaoappPath = xrsaoapp.path
        let macDir = AppPaths.shared.macDirectory?.path ?? ""
        let rootDir = AppPaths.shared.sharewareRoot?.path ?? ""

        Task.detached(priority: .userInitiated) {
            let result = Self.runXrsaoapp(
                xrsaoappPath: xrsaoappPath,
                macDirectory: macDir,
                workingDirectory: rootDir
            )
            await MainActor.run {
                switch result {
                case .success(let output):
                    let cleaned = Self.stripANSI(output)
                    self.rawOutput = cleaned
                    if cleaned.lowercased().contains("trial license") {
                        self.state = .locked
                    } else {
                        self.state = .unlocked
                    }
                case .failure(let error):
                    self.state = .error(error.localizedDescription)
                }
            }
        }
    }

    private nonisolated static func stripANSI(_ text: String) -> String {
        let pattern = "\u{1B}\\[[0-9;]*[A-Za-z]"
        return text.replacingOccurrences(
            of: pattern,
            with: "",
            options: .regularExpression
        )
    }
    
    private nonisolated static func runXrsaoapp(
        xrsaoappPath: String,
        macDirectory: String,
        workingDirectory: String
    ) -> Result<String, Error> {
        var env = ProcessInfo.processInfo.environment
        env["HOME"] = NSHomeDirectory()
        env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

        let libPaths = [macDirectory, "/usr/local/lib", workingDirectory]
            .filter { !$0.isEmpty }
            .joined(separator: ":")

        let existingDyld = env["DYLD_LIBRARY_PATH"] ?? ""
        let existingFallback = env["DYLD_FALLBACK_LIBRARY_PATH"] ?? ""
        env["DYLD_LIBRARY_PATH"] = existingDyld.isEmpty ? libPaths : "\(libPaths):\(existingDyld)"
        env["DYLD_FALLBACK_LIBRARY_PATH"] = existingFallback.isEmpty ? libPaths : "\(libPaths):\(existingFallback)"

        let process = Process()
        process.environment = env
        process.executableURL = URL(fileURLWithPath: xrsaoappPath)
        // 注意：这里不传任何参数，直接跑，让它自己输出
        process.arguments = []
        if !workingDirectory.isEmpty {
            process.currentDirectoryURL = URL(fileURLWithPath: workingDirectory)
        }

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = pipe

        do {
            try process.run()
        } catch {
            return .failure(NSError(
                domain: "xrsaoapp",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "无法启动 xrsaoapp.sw：\(error.localizedDescription)"]
            ))
        }

        process.waitUntilExit()

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8) ?? ""

        // 即使退出码非 0，只要有输出也返回，交给上层判断
        return .success(output)
    }
}
