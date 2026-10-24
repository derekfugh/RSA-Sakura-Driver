# RSA-Sakura Driver

一个 macOS 上的 RSA 密钥管理、文件与目录加解密工具，基于 SwiftUI 构建，支持拖拽操作。

A macOS app for RSA key management, file and folder encryption/decryption, built with SwiftUI and drag-and-drop support.

![演示](https://your-image-host.com/demo.gif](https://github.com/user-attachments/assets/58630771-b5db-4df6-9fe4-10a0a034c515)
---

## 功能 Features

- **授权签名 Signature**：检测授权状态，拖入文件解锁/锁定，查看原始输出，销毁钥匙串和签名。
  - License status detection, drag-and-drop unlock/lock, raw output viewer, destroy keychain & signature.
- **密钥 Keys**：生成 RSA 密钥对，可设置密钥名、位数、p&q 位差、公钥位数 e bits、快速模式；重建钥匙串。
  - Generate RSA key pairs with configurable name, bits, p&q difference, e bits, and fast mode; rebuild keychain.
- **文件 Files**：拖拽文件到上半区加密、下半区解密；支持自动覆盖、更签、恢复、多核/多线程设置、密码本提取密钥。
  - Drag files to the top half to encrypt, bottom half to decrypt; supports overwrite, re-sign, recover, multi-core/threaded settings, and key extraction.
- **目录 Folder**：拖拽目录到四象限分别执行加密、压缩、解密、解压；支持递归遍历、自动覆盖、文件类型过滤。
  - Drag folders into four quadrants to encrypt, zip, decrypt, or unzip; supports recursive traversal, overwrite, and file type filtering.

---

## 系统要求 Requirements

- macOS 14.0 (Sonoma) 或更高版本 / macOS 14.0 (Sonoma) or later
- Apple Silicon (M 系列) 或 Intel Mac / Apple Silicon (M-series) or Intel Mac
- 需要先安装 RSA-Sakura 231029（樱花加密）核心包，提供 `sigd`、`sige`、`xrsaoapp.sw`、`sxrsa.sw`、`dxrsa.sw`、`ezip`、`eunzip` 等命令
  - 下载地址 / Download: https://github.com/derekfugh/RSA-Sakura
- Requires the RSA-Sakura 231029 (樱花加密) core package (`sigd`, `sige`, `xrsaoapp.sw`, `sxrsa.sw`, `dxrsa.sw`, `ezip`, `eunzip`, etc.)
  - Download: https://github.com/derekfugh/RSA-Sakura

---

## 安装 Installation

### 1. 下载 Download

从 [Releases](https://github.com/derekfugh/RSA-Sakura-Driver/releases) 页面下载最新的 `RSA-Sakura.Driver.tar.gz`，解压得到 `RSA-Sakura Driver.app`。

Download the latest `RSA-Sakura.Driver.tar.gz` from the [Releases](https://github.com/derekfugh/RSA-Sakura-Driver/releases) page and extract it to get `RSA-Sakura Driver.app`.

### 2. 复制到应用程序目录 Move to Applications

将 App 拖入 `/Applications`（应用程序）文件夹。

Drag the app into the `/Applications` folder.

### 3. 处理 Gatekeeper（首次打开必看）/ Gatekeeper (required on first launch)

本应用未经 Apple 开发者签名和公证，macOS 会阻止首次打开。任选以下一种方式：

This app is not signed or notarized by Apple, so macOS will block it on first launch. Choose one of the following:

**方式一：右键打开（推荐）/ Option 1: Right-click Open (recommended)**

在“访达”中找到 App，**按住 Control 键点击（或右键点击）** → 选择 **“打开”** → 在弹窗中再次点击 **“打开”**。

In Finder, **Control-click (or right-click)** the app → choose **"Open"** → click **"Open"** again in the dialog.

**方式二：清除隔离属性 / Option 2: Remove quarantine attribute**

打开终端，执行：

```bash
sudo xattr -cr /Applications/"RSA-Sakura Driver.app"
```

**方式三：本机临时签名（可选）/ Option 3: Ad-hoc sign locally (optional)**

```bash
codesign --force --deep --sign - /Applications/"RSA-Sakura Driver.app"
```

完成后即可正常双击打开。

After that, you can open the app normally.

---

## 使用 Usage

启动后，窗口右上角的下拉菜单可切换四个功能页：

After launching, use the dropdown menu in the top-right corner to switch between four tabs:

| 模式 Mode | 说明 Description |
|---|---|
| 授权 Signature | 检测授权状态，拖入文件解锁/锁定 / Check license status, drag files to unlock/lock |
| 密钥 Keys | 生成密钥对、重建钥匙串 / Generate key pairs, rebuild keychain |
| 文件 Files | 拖拽文件加密/解密，支持更签与恢复 / Drag files to encrypt/decrypt, with re-sign and recover support |
| 目录 Folder | 拖拽目录加密/压缩/解密/解压 / Drag folders to encrypt/zip/decrypt/unzip |

### 拖拽操作说明 Drag-and-Drop Guide

- **文件页 Files**：拖入窗口后，上半区为“加密”，下半区为“解密”。只接受文件，目录请到“目录”页处理。
  - After dragging into the window, the top half is "Encrypt" and the bottom half is "Decrypt". Only files are accepted; use the Folder tab for directories.
- **目录页 Folder**：拖入窗口后，四个象限分别为“加密”“压缩”“解密”“解压”。只接受目录，文件请到“文件”页处理。
  - After dragging into the window, the four quadrants are "Encrypt", "Zip", "Decrypt", and "Unzip". Only folders are accepted; use the Files tab for files.
- 拖拽前请先在“密钥”页选择或生成一个密钥。
  - Select or generate a key in the Keys tab before dragging.

---

## 常见问题 FAQ

**Q：打开时提示“无法打开，因为无法验证开发者”？**
A：这是 macOS Gatekeeper 的拦截，不是文件损坏。按上面“处理 Gatekeeper”中的任一方式操作即可。

**Q: The app says "cannot be opened because the developer cannot be verified"?**
A: This is macOS Gatekeeper blocking an unsigned app, not a corrupted file. Follow any method in the "Gatekeeper" section above.

**Q：拖入文件后提示“请先选择一个密钥”？**
A：先到“密钥”页生成或选择一个密钥，再回到“文件”或“目录”页拖拽。

**Q: It says "Please select a key first" after dropping files?**
A: Generate or select a key in the Keys tab first, then return to the Files or Folder tab.

**Q：中文在英文系统上能显示吗？**
A：应用内文字为中英双语硬编码。英文部分在任何系统上都能正常显示；中文部分依赖 macOS 系统字体 fallback，通常也能显示，最坏情况为方框但不影响英文理解。

**Q: Will Chinese text display on an English macOS?**
A: The UI uses hardcoded bilingual strings. English text always renders correctly. Chinese text relies on macOS font fallback and usually displays fine; in rare cases it may show as boxes, but the English part remains readable.

---

## 从源码构建 Build from Source

1. 克隆仓库 / Clone the repo:
   ```bash
   git clone https://github.com/derekfugh/RSA-Sakura-Driver.git
   ```
2. 用 Xcode 打开 `RSA-Sakura Driver Project.xcodeproj`。
   Open `RSA-Sakura Driver Project.xcodeproj` in Xcode.
3. 选择你的开发团队（或留空使用本地签名），点击 Run。
   Select your development team (or leave empty for local signing) and click Run.
4. 导出 App：**Product → Archive → Distribute App → Copy App**。
   Export the app: **Product → Archive → Distribute App → Copy App**.

---

## 许可证 License

本项目暂未指定开源许可证。如需使用、修改或分发，请先联系作者。
No license has been specified yet. Please contact the author before using, modifying, or distributing.

---

## 反馈 Feedback

- 提交 Issue：[GitHub Issues](https://github.com/derekfugh/RSA-Sakura-Driver/issues)
- 提交 Pull Request 欢迎 / Pull requests are welcome.

---

## 相关项目 Related Projects

- **RSA-Sakura 231029（樱花加密）**：本应用依赖的核心命令行工具包，提供 `sigd`、`sige`、`xrsaoapp.sw`、`sxrsa.sw`、`dxrsa.sw`、`ezip`、`eunzip` 等命令。日常也称作 Sakura🌸、樱花🌸。
  - https://github.com/derekfugh/RSA-Sakura
- **RSA-Sakura Driver**：本应用，macOS GUI 前端
  - https://github.com/derekfugh/RSA-Sakura-Driver

---

**免责声明 Disclaimer**：本工具仅用于合法数据的加解密与密钥管理。请遵守当地法律法规。
This tool is intended for lawful data encryption/decryption and key management only. Please comply with local laws and regulations.
