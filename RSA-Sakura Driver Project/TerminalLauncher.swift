//
//  TerminalLauncher.swift
//  RSA-Sakura Driver Project
//
//  Created by quanfu on 2026/10/14.
//
import Foundation

/// 在 Terminal.app 中打开一个新窗口，并执行给定命令。
/// 命令会交给 shell 解析，所以可以包含管道、&&、cd 等。
func openTerminalAndRun(_ command: String) {
    // AppleScript 字符串里需要转义反斜杠和双引号
    let escaped = command
        .replacingOccurrences(of: "\\", with: "\\\\")
        .replacingOccurrences(of: "\"", with: "\\\"")

    let script = """
    tell application "Terminal"
        do script "\(escaped)"
        activate
    end tell
    """

    let process = Process()
    process.executableURL = URL(fileURLWithPath: "/usr/bin/osascript")
    process.arguments = ["-e", script]

    let errPipe = Pipe()
    process.standardError = errPipe

    do {
        try process.run()
    } catch {
        print("打开终端失败：\(error.localizedDescription)")
        return
    }

    process.waitUntilExit()

    if process.terminationStatus != 0 {
        let data = errPipe.fileHandleForReading.readDataToEndOfFile()
        let msg = String(data: data, encoding: .utf8) ?? ""
        print("osascript 失败：\(msg)")
    }
}

extension String {
    /// 用单引号包裹并转义内部单引号，供 shell 安全使用。
    /// 例如：路径里带空格、引号、美元符号时，直接拼进命令会出错，用它包一下即可。
    var shellQuoted: String {
        "'" + self.replacingOccurrences(of: "'", with: "'\\''") + "'"
    }
}
