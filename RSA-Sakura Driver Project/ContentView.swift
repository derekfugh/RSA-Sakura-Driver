import SwiftUI

// 定义四种内容类型
enum ContentMode: String, CaseIterable, Identifiable {
//    case settings_v = "设置 settings"
    case settings_v = "授权 Signature"
    case keys_v = "密钥 Keys"
    case files_v = "文件 Files"
    case folder_v = "目录 Folder"

    var id: String { rawValue }
}

struct ContentView: View {
    @AppStorage("selectedMode") private var selectedMode: ContentMode = .settings_v

    var body: some View {
        Group {
            switch selectedMode {
            case .files_v:
                FilesView()
            case .keys_v:
                KeysView()
            case .folder_v:
                FolderView()
            case .settings_v:
                SettingsView()
            }
        }
        .frame(width: 421, height: 218)
        // .navigationTitle("RSA-Sakura")
        .toolbar {
            // 右上角下拉框
            ToolbarItem(placement: .primaryAction) {
            /*
            ToolbarItemGroup(placement: .primaryAction) {
                Button {
                    guard let root = AppPaths.shared.sharewareRoot?.path else {
                        return
                    }
                    openTerminalAndRun("cd \(root.shellQuoted)")
                } label: {
                    Image(nsImage: NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 18, height: 18)
                }
                .help("打开终端并进入主目录 Open Terminal in Root")
            */
                Picker("模式", selection: $selectedMode) {
                    ForEach(ContentMode.allCases) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)
                .frame(width: 120)
            }
        }
    }
}

struct KeyPicker: View {
    @Binding var selectedKeyID: String
    //@StateObject private var loader = KeyLoader()
    @ObservedObject private var loader = KeyLoader.shared

    var body: some View {
        HStack(spacing: 8) {
            Text("密钥 key")
                .foregroundStyle(.secondary)

            if loader.isLoading {
                ProgressView().controlSize(.small)
            } else if let error = loader.errorMessage {
                Text("加载失败：\(error)")
                    .foregroundStyle(.red)
                    .font(.caption)
                    .lineLimit(1)
            } else if loader.keys.isEmpty {
                Text("没有可用密钥 / No keys available")
                    .foregroundStyle(.yellow)
                    .font(.caption)
            } else {
                Picker("", selection: $selectedKeyID) {
                    ForEach(loader.keys) { key in
                        Text(key.name).tag(key.id)
                    }
                }
                .labelsHidden()
                .pickerStyle(.menu)
                .frame(width: 160)
            }

            Button {
                loader.loadKeys()
            } label: {
                Image(systemName: "arrow.clockwise")
            }
            .buttonStyle(.borderless)
            .help("刷新密钥列表 Refresh")
        }
        .onAppear {
            if loader.keys.isEmpty {
                loader.loadKeys()
            }
        }
        .onChange(of: loader.keys) { _, newKeys in
            if selectedKeyID.isEmpty, let first = newKeys.first {
                selectedKeyID = first.id
            } else if !newKeys.contains(where: { $0.id == selectedKeyID }) {
                selectedKeyID = newKeys.first?.id ?? ""
            }
        }
    }
}

// 单个拖放标签
struct DropZoneLabel: View {
    let text: String
    let subtitle: String?
    let isHighlighted: Bool
    let onDrop: ([URL]) -> Void
    let isTargeted: (Bool) -> Void

    var body: some View {
        VStack(spacing: 4) {
            Text(text)
                .font(.title2)
                .fontWeight(.medium)

            if let subtitle {
                Text(subtitle)
                    .font(.callout)
                    // .foregroundStyle(.secondary)
                    // .opacity(0.75)   // 跟随高亮/变暗，但视觉上仍比主标题淡
            }
        }
        .foregroundStyle(isHighlighted ? .primary : .tertiary)
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isHighlighted ? Color.blue.opacity(0.15) : Color.clear)
        )
        .animation(.easeInOut(duration: 0.15), value: isHighlighted)
        .dropDestination(for: URL.self) { urls, _ in
            onDrop(urls)
            return true
        } isTargeted: { targeted in
            isTargeted(targeted)
        }
    }
}

struct KeychainIconButton: View {
    let helpText: String
    let showBorder: Bool          // 👈 是否显示圆角边框
    let action: () -> Void

    @State private var isHovering = false
    @State private var isPressed = false

    init(
        helpText: String,
        showBorder: Bool = false,
        action: @escaping () -> Void
    ) {
        self.helpText = helpText
        self.showBorder = showBorder
        self.action = action
    }
    
    private func loadKeychainIcon() -> NSImage {
        if let url = Bundle.main.url(forResource: "Keychain", withExtension: "icns"),
           let img = NSImage(contentsOf: url) {
            return img
        }
        return NSApp.applicationIconImage
    }
    var body: some View {
        Button {
            action()
        } label: {
            // Image(nsImage: NSImage(named: "Keychain.icns") ?? NSApp.applicationIconImage)
            Image(nsImage: loadKeychainIcon())
                .resizable()
                .frame(width: 32, height: 32)
                .opacity(isHovering ? 1.0 : 0.85)         // 悬停变亮
                .scaleEffect(isPressed ? 0.9 : 1.0)       // 按下缩放
                .padding(2)                                        // 👈 图标与边框之间留白
                .background(
                    RoundedRectangle(cornerRadius: 6)
                        .stroke(
                            isHovering ? Color.accentColor : Color.secondary.opacity(0.5),
                            lineWidth: isHovering ? 1.5 : 1.0
                        )
                        .opacity(showBorder ? 1.0 : 0.0)           // 👈 不显示时透明
                        .scaleEffect(isPressed ? 0.92 : 1.0)       // 👈 按下时边框同步缩放
                )
                .animation(.easeOut(duration: 0.1), value: isHovering)
                .animation(.easeOut(duration: 0.08), value: isPressed)
        }
        .buttonStyle(.plain)                              // 去掉系统默认样式
        .onHover { hovering in
            isHovering = hovering
        }
        .simultaneousGesture(
            DragGesture(minimumDistance: 0)
                .onChanged { _ in isPressed = true }
                .onEnded { _ in isPressed = false }
        )
        .help(helpText)          // 👈 用参数
    }
}

// 四种内容视图
struct SettingsView: View {
    @StateObject private var checker = LicenseChecker()
    private var isInstalled: Bool {
        checker.state == .locked || checker.state == .unlocked
    }
    
    @State private var showError = false
    @State private var errorMessage = ""
    @State private var outerTargeted = false
    @State private var isTargetingUnlock = false
    private var isDragging: Bool {
        outerTargeted || isTargetingUnlock
    }
    /// 只有已锁定状态才允许拖入
    private var canDropForUnlock: Bool {
        checker.state == .locked
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Text("授权状态 / License Status : ")
                    .foregroundStyle(.secondary)

                statusLabel

                Spacer()

                Button {
                    checker.check()
                } label: {
                    Image(systemName: "arrow.clockwise")
                }
                .buttonStyle(.borderless)
                .help("重新检测")
            }

            if !checker.rawOutput.isEmpty {
                DisclosureGroup {
                    ScrollView {
                        Text(checker.rawOutput)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(maxHeight: 120)
                } label: {
                    Text("查看原始输出 (Raw Output)")
                        .foregroundStyle(.secondary)   // 👈 固定为次要色，不随展开变化
                }
            }
            
            HStack(spacing: 12) {
                Image(systemName: "gearshape")
                    .font(.system(size: 48))
                    .font(.title3)
                    .foregroundStyle(.secondary)

                // Spacer()

                Button("解锁 Unlock") {
                    openTerminalAndRun("sigd")
                }
                .disabled(checker.state != .locked)
                .frame(maxWidth: .infinity)
                
                Button("锁定 Lock") {
                    openTerminalAndRun("sige")
                }
                .disabled(checker.state != .unlocked)
                .frame(maxWidth: .infinity)
                
                Button("版本 Ver.") {
                    openTerminalAndRun("xrsaoapp.sw \\?; xrsaoapp.sw -\\?")
                }
                .disabled(!isInstalled)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            
            HStack {
                Spacer()
                Button("销毁钥匙串和签名  Destroy Keychain & Signature") {
                        openTerminalAndRun("sigrm")
                }
                Spacer()
            }
            .disabled(!isInstalled)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .onAppear {
            checker.check()
        }
        .onChange(of: isDragging) { _, dragging in
            if !dragging {
                isTargetingUnlock = false
                outerTargeted = false
            }
        }
        .alert("无法处理 / Unable to Process", isPresented: $showError) {
            Button("确定 / OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
        .dropDestination(for: URL.self) { urls, _ in
            false   // 👈 只检测，不处理，让 overlay 里的 DropZoneLabel 接管
        } isTargeted: { targeted in
            if canDropForUnlock {
                outerTargeted = targeted
            }
        }
        .overlay {
            if isDragging {
                unlockOverlay
                    .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isDragging)
    }

    @ViewBuilder
    private var statusLabel: some View {
        switch checker.state {
        case .locked:
            Text("已锁定 Locked")
                .font(.headline)
                .foregroundStyle(.red)
        case .unlocked:
            Text("已解锁 Unlocked")
                .font(.headline)
                .foregroundStyle(.green)
        case .notInstalled:
            Text("未安装 Uninstalled")
                .font(.headline)
                .foregroundStyle(.orange)
        case .unknown:
            Text("检测中 checking …")
                .font(.headline)
                .foregroundStyle(.secondary)
        case .error(let msg):
            Text("错误 Error ：\(msg)")
                .font(.headline)
                .foregroundStyle(.red)
        }
    }
    private var unlockOverlay: some View {
        DropZoneLabel(
            text: "解锁",
            subtitle: "Unlock",
            isHighlighted: isTargetingUnlock
        ) { urls in
            _ = handleUnlockDrop(urls)
        } isTargeted: { targeted in
            isTargetingUnlock = targeted
        }
        .padding(12)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
    }
    private func handleUnlockDrop(_ urls: [URL]) -> Bool {
        // 1. 状态校验：只有已锁定才允许
        guard checker.state == .locked else {
            return false
        }

        // 2. 只取第一个
        guard let first = urls.first else {
            return false
        }

        // 3. 必须是文件，不能是目录
        let isDirectory = (try? first.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        if isDirectory {
            errorMessage = "只接受文件，不接受目录。请拖入单个文件。\nOnly files are accepted, not folders. Please drop a single file."
            showError = true
            return false
        }

        // 4. 执行解锁命令（TODO：等你确认具体命令）
        print("[SettingsView] Unlock with file: \(first.path)")
        openTerminalAndRun("sigd \(first.path.shellQuoted)")

        return true
    }
}

struct KeysView: View {
    @AppStorage("keysView.name") private var keyName: String = ""
    @AppStorage("keysView.bits") private var bits: Int = 2048
    @AppStorage("keysView.diff") private var difference: Int = -1
    @AppStorage("keysView.eBits") private var eBits: Int = 0
    @AppStorage("keysView.fastMode") private var fastMode: Bool = true

    @State private var showError = false
    @State private var errorMessage = ""
    private func generateKey() {
        // 1. 名称校验
        let name = keyName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty else {
            errorMessage = "请先填写密钥名称。\nPlease enter a key name."
            showError = true
            return
        }

        // 2. 主目录校验
        guard let root = AppPaths.shared.sharewareRoot?.path else {
            errorMessage = "未找到 RSA-Sakura 主目录。请确认程序已正确安装。\nRSA-Sakura root directory not found. Please make sure the app is installed correctly."
            showError = true
            return
        }

        // 3. 拼参数
        var parts: [String] = ["xrsaoapp.sw"]
        parts.append("-k\(name)")
        parts.append(".")
        parts.append("-b\(bits)")
        if difference != -1 {
            parts.append("-0\(difference)")
        }
        if eBits != 0 {
            parts.append("-m\(eBits)")
        }
        if fastMode {
            parts.append("-t")
        }

        let cmd = "cd \(root.shellQuoted) && " + parts.joined(separator: " ")

        openTerminalAndRun(cmd)
        print("[KeysView] Generate: \(cmd)")
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 12) {
                /*
                Image(systemName: "gearshape")
                    .font(.system(size: 48))
                    .font(.title3)
                    .foregroundStyle(.secondary)
                */
                Text("密钥对名称 Key Pair Name")
                    .foregroundStyle(.secondary)
                
                TextField("", text: $keyName)
                    .textFieldStyle(.roundedBorder)
                    .frame(maxWidth: .infinity)   // 👈 占满剩余宽度
                    .onChange(of: keyName) { _, newValue in
                        let allowed = CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789.@-_")
                        let filtered = newValue.unicodeScalars.filter { allowed.contains($0) }
                        var result = String(String.UnicodeScalarView(filtered))
                        if result.count > 18 {
                            result = String(result.prefix(18))
                        }
                        if result != newValue {
                            keyName = result
                        }
                    }
                Text("\(keyName.count)/18")
                    .font(.caption)
                    .foregroundStyle(
                        keyName.count > 18 ? Color.red :
                        keyName.count == 18 ? Color.yellow :
                        Color.secondary
                    )
            }
            .padding(.leading, 0)   // 👈 缩进
            .padding(.trailing, 0)
            .frame(maxWidth: .infinity)
            
            HStack {
                Text("位数 bits")
                    .foregroundStyle(.secondary)
                TextField("", value: $bits, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .multilineTextAlignment(.trailing)
                    .onChange(of: bits) { _, newValue in
                        // 👈 只做绝对边界的保护（1 和 500000）
                        if newValue < 1 {
                            bits = 1
                        } else if newValue > 488_319 {
                            bits = 488_319
                        }
                    }
                // 👇 上下箭头，按住可连续变化
                Stepper("", value: $bits, in: 1...488_319)
                    .labelsHidden()
                Text("（5 ～ 488319）")
                    .font(.caption)
                    .foregroundStyle(bits < 5 ? .red : .secondary)   // 👈 小于 5 变红
                Spacer()
            }
            .padding(.leading, 0)   // 👈 缩进
            .padding(.trailing, 0)
            .frame(maxWidth: .infinity)
            
            HStack {
                Text("p&q 位差 Difference")
                    .foregroundStyle(.secondary)
                TextField("", value: $difference, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .multilineTextAlignment(.trailing)
                    // 👈 不再自动修正
                    /*
                    .onChange(of: difference) { _, newValue in
                        let upper = max(bits - 1, -1)
                        if newValue < -1 {
                            difference = -1
                        } else if newValue > upper {
                            difference = upper
                        }
                    }
                    */
                Stepper("", value: $difference, in: -1...max(bits - 1, -1))
                    .labelsHidden()

                Text("(-1 ; 0 ~ \(max(bits - 1, -1)))")
                        .font(.caption)
                        .foregroundStyle(
                            (difference < -1 || difference > max(bits - 1, -1))
                                ? .red : .secondary
                        )   // 👈 上下越界都变红

                Spacer()
            }
            .padding(.leading, 0)   // 👈 缩进
            .padding(.trailing, 0)
            .frame(maxWidth: .infinity)
            
            HStack {
                Text("公钥位数 e bits")
                    .foregroundStyle(.secondary)
                TextField("", value: $eBits, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 100)
                    .multilineTextAlignment(.trailing)
                    // 👈 不再自动修正
                    /*
                    .onChange(of: eBits) { _, newValue in
                        let upper = max(bits - 1, 0)
                        if newValue < 0 {
                            eBits = 0
                        } else if newValue > upper {
                            eBits = upper
                        }
                    }
                    */
                Stepper("", value: $eBits, in: 0...max(bits, 0))
                    .labelsHidden()
                Text("(0 ; 1 ~ \(max(bits, 0)))")
                    .font(.caption)
                    .foregroundStyle(
                        (eBits < 0 || eBits > max(bits, 0))
                            ? .red : .secondary
                    )   // 👈 上下越界都变红

                Spacer()
            }
            .padding(.leading, 0)   // 👈 缩进
            .padding(.trailing, 0)
            .frame(maxWidth: .infinity)
            
            HStack(spacing: 12) {
                Toggle("快速模式 Fast Mode", isOn: $fastMode)
                    .toggleStyle(.checkbox)
                    .foregroundStyle(.secondary)

                Spacer()

                Button("生成密钥 Generate") {
                    generateKey()
                }
                /*
                Button {
                    openTerminalAndRun("npeminicp")
                } label: {
                    Image(nsImage: NSImage(named: "Keychain") ?? NSApp.applicationIconImage)
                        .resizable()
                        .frame(width: 32, height: 32)
                }
                .buttonStyle(.borderless)
                .help("钥匙串 Keychain")
                */
                KeychainIconButton(helpText: "重建钥匙串 Rebuild Keychain + 测试 Test",  showBorder: true) {
                    let cmd = "npeminicp; xrsaoapp.sw -k\(keyName)"
                    openTerminalAndRun(cmd)
                    print("[KeysView] Rebuild: \(cmd)")
                }
            }
            .padding(.leading, 0)
            .padding(.trailing, 0)
            .frame(maxWidth: .infinity)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        // 👈 删掉 onChange(of: bits) 里的自动修正
        /*
        .onChange(of: bits) { _, newBits in
            let upper = max(newBits - 1, -1)

            // 位差修正
            if difference > upper { difference = upper }
            if difference < -1 { difference = -1 }

            // 公钥位数修正
            let eUpper = max(newBits - 1, 0)
            if eBits > eUpper { eBits = eUpper }
            if eBits < 0 { eBits = 0 }
        }
        */
        .alert("无法生成密钥 / Unable to Generate Key", isPresented: $showError) {
            Button("确定 / OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
}

struct FilesView: View {
    @State private var outerTargeted = false
    @State private var isTargetingEncrypt = false
    @State private var isTargetingDecrypt = false
    
    @AppStorage("selectedKeyID") private var selectedKeyID: String = ""
    @AppStorage("filesView.overwrite") private var overwrite: Bool = false
    @AppStorage("filesView.recover") private var recover: Bool = false
    @AppStorage("filesView.reSign") private var reSign: Bool = false

    // 弹框状态
    @State private var showError = false
    @State private var errorMessage = ""

    private var isDragging: Bool {
        outerTargeted || isTargetingEncrypt || isTargetingDecrypt
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 21) {
                Image(systemName: "doc.on.doc")
                    .font(.system(size: 48))
                    .font(.title3)
                    .foregroundStyle(isDragging ? .blue : .secondary)
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * 0.12
                    }
                KeyPicker(selectedKeyID: $selectedKeyID)
            }
            .frame(maxWidth: .infinity)
            
            HStack(spacing: 12) {
                Toggle("自动覆写 Overwrite", isOn: $overwrite)
                        .toggleStyle(.checkbox)
                Button("多核/多线程 Multi-core/Threading") {
                    openTerminalAndRun("xcompensate")
                }
                .font(.headline)
                //.frame(maxWidth: .infinity)
                .padding(0)
            }
            .frame(maxWidth: .infinity)
            
            HStack(spacing: 12) {
                Text("密钥:")
                    .foregroundStyle(.secondary)
                Toggle("更签 re-sign", isOn: $reSign)
                    //.foregroundStyle(.pink)
                    .foregroundStyle(.pink.opacity(reSign ? 1.0 : 0.48))
                    .toggleStyle(.checkbox)
                Toggle("恢复 Recover", isOn: $recover)
                    //.foregroundStyle(.green)
                    .foregroundStyle(.green.opacity(recover ? 1.0 : 0.48))
                    .toggleStyle(.checkbox)
                KeychainIconButton(helpText: "重建钥匙串 Rebuild Keychain", showBorder: true) {
                    var cmd = "npeminicp; xrsaoapp.sw"
                    if reSign {
                        // TODO: 更签对应的命令参数，等你确认
                        cmd = "sigx \(selectedKeyID)"
                    } else if recover {
                        cmd = "xrsaoapp.sw -x\(selectedKeyID)"
                    }
                    openTerminalAndRun(cmd)
                }
            }
            .onChange(of: reSign) { _, newValue in
                if newValue { recover = false }
            }
            .onChange(of: recover) { _, newValue in
                if newValue { reSign = false }
            }
            
            /*
            HStack() {
                Button("密码本: 提取密钥 rsa-keeper") {
                    openTerminalAndRun("rsa-keeper")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
            }
            .frame(maxWidth: .infinity)
            */
            HStack(spacing: 21) {
                Text("密码本:")
                    .foregroundStyle(.secondary)
                Button("提取密钥 rsa-keeper") {
                    openTerminalAndRun("rsa-keeper")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                Button("设置 config-keeper") {
                    openTerminalAndRun("config-keeper")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
            }
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: isDragging) { _, dragging in
            if !dragging {
                isTargetingEncrypt = false
                isTargetingDecrypt = false
                outerTargeted = false
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isDragging)
        .dropDestination(for: URL.self) { _, _ in
            false
        } isTargeted: { targeted in
            outerTargeted = targeted
        }
        // 👇 拖拽时覆盖整个窗口
        .overlay {
            if isDragging {
                dragOverlay
                    .transition(.opacity)
            }
        }
        // 弹框
        .alert("无法处理 / Unable to Process", isPresented: $showError) {
            Button("确定 / OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    // 👇 拖拽时的上下两半覆盖层
    private var dragOverlay: some View {
        VStack(spacing: 0) {
            DropZoneLabel(
                text: "加密文件",
                subtitle: "Encrypt File(s)",
                isHighlighted: isTargetingEncrypt
            ) { urls in
                handleFiles(urls, action: "加密")
            } isTargeted: { targeted in
                isTargetingEncrypt = targeted
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Divider()

            DropZoneLabel(
                text: "解密文件",
                subtitle: "Decrypt File(s)",
                isHighlighted: isTargetingDecrypt
            ) { urls in
                handleFiles(urls, action: "解密")
            } isTargeted: { targeted in
                isTargetingDecrypt = targeted
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)   // 盖住下层内容
    }
    
    /// 统一处理拖入的 URL：只接受文件，含目录则拦截
    private func handleFiles(_ urls: [URL], action: String) {
        // 1. 检查是否混有目录
        let hasDirectory = urls.contains { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) == true
        }

        if hasDirectory {
            errorMessage = "检测到目录。这里只接受文件，请把目录拖到“目录”标签页处理。\nFolder detected. Only files are accepted here. Please drop folders in the Folder tab."
            showError = true
            return   // 不作进一步处理
        }

        // 2. 密钥校验
        let key = selectedKeyID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            errorMessage = "请先选择一个密钥。\nPlease select a key first."
            showError = true
            return
        }
        
        // 3. 拼命令
        let overwriteFlag = overwrite ? "--overwrite " : ""
        let flag = (action == "加密") ? "-e" : "-d"
        let filesArg = urls.map { $0.path.shellQuoted }.joined(separator: " ")
        let line = "sxrsa.sw \(overwriteFlag)\(flag)\(key.shellQuoted) \(filesArg)"

        // 4. 执行 + 打印
        openTerminalAndRun(line)
        print("[FilesView] \(action)：\(line)")
    }
}

struct FolderView: View {
    @State private var outerTargeted = false
    @State private var isTargetingEncrypt = false
    @State private var isTargetingDecrypt = false
    @State private var isTargetingZip = false
    @State private var isTargetingUnzip = false

    @AppStorage("selectedKeyID") private var selectedKeyID: String = ""
    @AppStorage("folderView.inputValue") private var inputValue: String = ""
    @AppStorage("filesView.overwrite") private var overwrite: Bool = false
    @AppStorage("folderView.recursive") private var recursive: Bool = true
    // @AppStorage("folderView.zipunzip") private var zipunzip: Bool = false
    
    // 👇 弹框状态
    @State private var showError = false
    @State private var errorMessage = ""

    private var isDragging: Bool {
        outerTargeted || isTargetingEncrypt || isTargetingZip
                || isTargetingDecrypt || isTargetingUnzip
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 33) {
                Image(systemName: "folder.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(isDragging ? .blue : .secondary)
                    .containerRelativeFrame(.horizontal) { length, _ in
                        length * 0.12
                    }
                KeyPicker(selectedKeyID: $selectedKeyID)
            }
            .frame(maxWidth: .infinity)
            
            RecentInputField(
                title: "类型 Type ",
                text: $inputValue,
                historyKey: "folderView.recentInputs",
                maxItems: 21
            )
            .padding(.horizontal, 0)
            
            HStack(spacing: 21) {
                Toggle("遍历目录 Recursive", isOn: $recursive)
                    .toggleStyle(.checkbox)
                Toggle("自动覆写 Overwrite", isOn: $overwrite)
                    .toggleStyle(.checkbox)
                KeychainIconButton(helpText: "重建钥匙串 Rebuild Keychain", showBorder: true) {
                    let cmd = "npeminicp; xrsaoapp.sw"
                    openTerminalAndRun(cmd)
                }
            }
            .padding(4)
            .frame(maxWidth: .infinity)
            
            HStack(spacing: 21) {
                /*
                Toggle("压缩/解压 Zip/Unzip", isOn: $zipunzip)
                    .toggleStyle(.checkbox)
                */
                Button("密码本: 提取密钥 rsa-keeper") {
                    openTerminalAndRun("rsa-keeper")
                }
                .font(.headline)
                // .frame(maxWidth: .infinity)
                
                Button("校验工具 SMX") {
                    openTerminalAndRun("dcp; ssmx; dsmx; smx-configure 0")
                }
            }
            .frame(maxWidth: .infinity)
            
            /*
            HStack(spacing: 21) {
                Text("密码本: ")
                Button("提取密钥 rsa-keeper") {
                    openTerminalAndRun("rsa-keeper")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                Button("设置 config-keeper") {
                    openTerminalAndRun("config-keeper")
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
            }
            //.padding(8)
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
            */
            /*
            if isDragging {
                VStack(spacing: 8) {
                    DropZoneLabel(
                        text: "加密目录",
                        subtitle: "Encrypt Folder(s)",
                        isHighlighted: isTargetingEncrypt
                    ) { urls in
                        handleFolders(urls, action: "加密")
                    } isTargeted: { targeted in
                        isTargetingEncrypt = targeted
                    }

                    DropZoneLabel(
                        text: "解密目录",
                        subtitle: "Decrypt Folder(s)",
                        isHighlighted: isTargetingDecrypt
                    ) { urls in
                        handleFolders(urls, action: "解密")
                    } isTargeted: { targeted in
                        isTargetingDecrypt = targeted
                    }
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
            */
        }
        .contentShape(Rectangle())   // 让空白区域也能接收点击
        .onTapGesture {
            NSApp.keyWindow?.makeFirstResponder(nil)
        }
        .padding(.horizontal, 18)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .onChange(of: isDragging) { _, dragging in
            if dragging {
                NSApp.keyWindow?.makeFirstResponder(nil)
            } else {
                // 拖拽结束：重置所有悬停状态，防止残留
                isTargetingEncrypt = false
                isTargetingZip = false
                isTargetingDecrypt = false
                isTargetingUnzip = false
                outerTargeted = false
            }
        }
        .animation(.easeInOut(duration: 0.2), value: isDragging)
        .dropDestination(for: URL.self) { _, _ in
            false
        } isTargeted: { targeted in
            outerTargeted = targeted
        }
        // 👇 拖拽时覆盖整个窗口
        //*
        .overlay {
            if isDragging {
                dragOverlay
                    .transition(.opacity)
            }
        }
        //*/
        // 👇 弹框
        .alert("无法处理 / Unable to Process", isPresented: $showError) {
            Button("确定 / OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    // 👇 拖拽时的上下两半覆盖层
    //*
    private var dragOverlay: some View {
        VStack(spacing: 0) {
            /*
            DropZoneLabel(
                text: "加密 / 压缩",
                subtitle: "Encrypt / Zip",
                isHighlighted: isTargetingEncrypt
            ) { urls in
                handleFolders(urls, action: zipunzip ? "压缩" : "加密")
            } isTargeted: { targeted in
                isTargetingEncrypt = targeted
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            */
            HStack(spacing: 0) {
                DropZoneLabel(
                    text: "加密",
                    subtitle: "Encrypt",
                    isHighlighted: isTargetingEncrypt
                ) { urls in
                    handleFolders(urls, action: "加密")
                } isTargeted: { targeted in
                    isTargetingEncrypt = targeted
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                DropZoneLabel(
                    text: "压缩",
                    subtitle: "Zip",
                    isHighlighted: isTargetingZip
                ) { urls in
                    handleFolders(urls, action: "压缩")
                } isTargeted: { targeted in
                    isTargetingZip = targeted
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            /*
            Divider()
            DropZoneLabel(
                text: "解密 / 解压",
                subtitle: "Decrypt / Unzip",
                isHighlighted: isTargetingDecrypt
            ) { urls in
                handleFolders(urls, action: zipunzip ? "解压" : "解密")
            } isTargeted: { targeted in
                isTargetingDecrypt = targeted
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            */
            HStack(spacing: 0) {
                DropZoneLabel(
                    text: "解密",
                    subtitle: "Decrypt",
                    isHighlighted: isTargetingDecrypt
                ) { urls in
                    handleFolders(urls, action: "解密")
                } isTargeted: { targeted in
                    isTargetingDecrypt = targeted
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                DropZoneLabel(
                    text: "解压",
                    subtitle: "Unzip",
                    isHighlighted: isTargetingUnzip
                ) { urls in
                    handleFolders(urls, action: "解压")
                } isTargeted: { targeted in
                    isTargetingUnzip = targeted
                }
                .padding(12)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)   // 盖住下层内容
    }
    //*/
    /// 统一处理拖入的 URL：只接受目录，含文件则拦截
    private func handleFolders(_ urls: [URL], action: String) {
        // 1. 检查是否混有文件
        let hasFile = urls.contains { url in
            (try? url.resourceValues(forKeys: [.isDirectoryKey]).isDirectory) != true
        }

        if hasFile {
            errorMessage = "检测到文件。这里只接受目录，请把文件拖到“文件”标签页处理。\nFile detected. Only folders are accepted here. Please drop files in the Files tab."
            showError = true
            return   // 不作进一步处理
        }

        // 2. 密钥校验
        let key = selectedKeyID.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !key.isEmpty else {
            errorMessage = "请先选择一个密钥。\nPlease select a key first."
            showError = true
            return
        }
        
        // 3. 文件类型校验
        let fileType = inputValue.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !fileType.isEmpty else {
            errorMessage = "请先在“输入”里填写文件类型，例如 \"*.c\" \"*.h\"。\nPlease enter the file type in the Input field, e.g. \"*.c\" \"*.h\"."
            showError = true
            return
        }
        
        // 4. 每个目录一条命令
        let recursiveFlag = recursive ? "--recursive " : "--non-recursive "
        let overwriteFlag = overwrite ? "--overwrite " : ""
        let flag: String
        let rsa_zip_cmd: String
        if (action == "压缩") {
            rsa_zip_cmd = "ezip"
            flag = ""
        } else if (action == "解压") {
            rsa_zip_cmd = "eunzip"
            flag = ""
        } else {
            rsa_zip_cmd = "dxrsa.sw"
            flag = (action == "加密") ? "-e\(key.shellQuoted)" : "-d\(key.shellQuoted)"
        }
        for folder in urls {
            let line = "\(rsa_zip_cmd) \(recursiveFlag)\(overwriteFlag)\(flag) \(folder.path.shellQuoted) \(fileType)"
            openTerminalAndRun(line)
            print("[FolderView] \(action)目录：\(line)")
        }
    }
}

#Preview {
    ContentView()
}
