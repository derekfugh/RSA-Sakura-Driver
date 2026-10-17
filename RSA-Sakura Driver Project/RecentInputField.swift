//
//  RecentInputField.swift
//  RSA-Sakura Driver Project
//
//  Created by quanfu on 2026/10/14.
//
import SwiftUI

struct RecentInputField: View {
    let title: String
    @Binding var text: String
    let historyKey: String
    let maxItems: Int

    @AppStorage private var historyJSON: String

    init(
        title: String,
        text: Binding<String>,
        historyKey: String,
        maxItems: Int = 12
    ) {
        self.title = title
        self._text = text
        self.historyKey = historyKey
        self.maxItems = maxItems
        self._historyJSON = AppStorage(wrappedValue: "[]", historyKey)
    }

    var body: some View {
        HStack(spacing: 6) {
            Text(title)
                .foregroundStyle(.secondary)

            TextField("", text: $text)
                .textFieldStyle(.roundedBorder)
                .onSubmit { commit() }

            // 👇 明确提示用户怎么提交
            Button {
                commit()
            } label: {
                Image(systemName: "plus")
            }
            .buttonStyle(.borderless)
            .help("添加到历史记录 Add to History")

            // 👇 Menu 自带箭头，不要再加 Image
            Menu {
                if history.isEmpty {
                    Text("暂无历史记录 No History")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(history, id: \.self) { item in
                        Button(item) {
                            text = item
                        }
                    }
                    Divider()
                    Button("清空历史 Clear History", role: .destructive) {
                        history = []
                    }
                }
            } label: {
                // 空 label，Menu 会只显示系统箭头
                Color.clear
                    .frame(width: 16, height: 16)
            }
            .menuStyle(.borderlessButton)
            .frame(width: 20)
            .help("选择历史记录 Select from History")
        }
    }

    private var history: [String] {
        get {
            guard let data = historyJSON.data(using: .utf8),
                  let arr = try? JSONDecoder().decode([String].self, from: data)
            else { return [] }
            return arr
        }
        nonmutating set {
            guard let data = try? JSONEncoder().encode(newValue),
                  let str = String(data: data, encoding: .utf8)
            else { return }
            historyJSON = str
        }
    }

    private func commit() {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            print("[RecentInputField] commit: 输入为空，跳过")
            return
        }

        var items = history
        items.removeAll { $0 == trimmed }
        items.insert(trimmed, at: 0)
        if items.count > maxItems {
            items = Array(items.prefix(maxItems))
        }
        history = items

        print("[RecentInputField] commit 成功，当前历史 \(items.count) 条：")
        for (i, item) in items.enumerated() {
            print("  [\(i)] \(item)")
        }
    }
}
