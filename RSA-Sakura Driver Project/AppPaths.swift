//
//  AppPaths.swift
//  RSA-Sakura Driver Project
//
//  Created by quanfu on 2026/10/14.
//
import Foundation
import Combine

@MainActor
final class AppPaths: ObservableObject {
    static let shared = AppPaths()

    @Published private(set) var xrsaoappPath: URL?
    @Published private(set) var sharewareRoot: URL?   // .../xrsa_shareware
    @Published private(set) var macDirectory: URL?    // .../xrsa_shareware/mac
    @Published private(set) var xinitoolPath: URL?    // /usr/local/bin/xinitool 解析后
    @Published private(set) var errorMessage: String?

    private let cacheKey = "sharewareRootPath"

    private init() {
        // 先从缓存恢复，让 UI 立刻可用；随后再 discover 刷新
        /*
        if let cached = UserDefaults.standard.string(forKey: cacheKey) {
            let root = URL(fileURLWithPath: cached)
            if FileManager.default.fileExists(atPath: root.path) {
                self.sharewareRoot = root
                self.macDirectory = root.appendingPathComponent("mac")
            }
        }
         */
        // 不再从缓存恢复，启动后由 App 主动 discover()
    }

    /// 启动时调用：定位 xrsaoapp.sw，反推主目录，并顺带找到 xinitool
    func discover() {
        errorMessage = nil

        // 1. which xrsaoapp.sw
        guard let rawURL = Self.locateViaWhich("xrsaoapp.sw") else {
            errorMessage = "未找到 xrsaoapp.sw，请确认 RSA-Sakura 已正确安装"
            // 👇 全部清空，不要留旧值
            self.sharewareRoot = nil
            self.macDirectory = nil
            self.xrsaoappPath = nil
            self.xinitoolPath = nil
            return
        }

        // 2. 解析软链接，拿到真实路径
        //    例如 /Volumes/.../xrsa_shareware/mac/xrsaoapp.sw
        let realPath = rawURL.resolvingSymlinksInPath()

        // 3. 反推目录
        let macDir = realPath.deletingLastPathComponent()   // .../mac
        let rootDir = macDir.deletingLastPathComponent()    // .../xrsa_shareware

        guard macDir.lastPathComponent.lowercased() == "mac" else {
            errorMessage = "xrsaoapp.sw 路径结构异常：\(realPath.path)"
            return
        }

        // 4. 校验目录存在
        guard FileManager.default.fileExists(atPath: rootDir.path) else {
            errorMessage = "解析出的主目录不存在：\(rootDir.path)"
            return
        }

        self.sharewareRoot = rootDir
        self.macDirectory = macDir
        self.xrsaoappPath = realPath

        // 5. 顺便定位 xinitool
        if let xinitoolRaw = Self.locateViaWhich("xinitool") {
            self.xinitoolPath = xinitoolRaw.resolvingSymlinksInPath()
        } else {
            self.xinitoolPath = nil
        }

        // 6. 缓存根目录
        UserDefaults.standard.set(rootDir.path, forKey: cacheKey)
    }

    /// 用 /usr/bin/which 查找命令路径
    private static func locateViaWhich(_ command: String) -> URL? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/which")
        process.arguments = [command]

        var env = ProcessInfo.processInfo.environment
        env["PATH"] = "/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"
        process.environment = env

        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        do {
            try process.run()
            process.waitUntilExit()
        } catch {
            return nil
        }

        guard process.terminationStatus == 0 else { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let output = String(data: data, encoding: .utf8)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
              !output.isEmpty else {
            return nil
        }

        return URL(fileURLWithPath: output)
    }
}
