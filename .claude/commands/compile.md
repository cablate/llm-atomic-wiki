---
description: 從 atoms/ 編譯 wiki 頁面（依 CLAUDE.md schema）
argument-hint: "[可選：branch 名稱或 topic，例如 mcp 或 mcp-server-design]"
---

## /compile — 編譯 atoms 為 wiki 頁面

依據 `CLAUDE.md` 與 `METHODOLOGY.md` Phase 6 執行 Compile 操作。

### 流程

1. **選定範圍**：
   - 若 `$ARGUMENTS` 指定了 branch（例如 `mcp`），列出該 branch 所有 atoms，提議 3–8 顆一組的頁面切分
   - 若指定了 topic（例如 `mcp-server-design`），直接針對該主題選 atoms
   - 若未指定，先讀 `atoms/` 結構，向使用者提議要 compile 的優先順序
2. **並行鎖定檔名**：若要並行編譯多頁，**先**列好完整 slug 清單（`<branch>-<topic-slug>.md`），取得使用者確認後再分派；agent 填內容不命名檔案。
3. **逐頁編譯**：
   - 檔名 `<branch>-<topic-slug>.md`，全小寫連字號
   - 第一行必須是 `# Title`
   - 相關概念首次出現用 `[[slug]]` 連結（slug 必須對應已存在的 wiki 檔）
   - 1500–2500 字為目標；>2500 考慮拆，<800 考慮合併
   - 時間敏感主張用具體版本 / 日期（`v3.5`、`as of 2026-04`），避免 `目前` / `最新` / `現在`
   - 頁尾列出來源 atoms：`*Compiled from atoms: branch/slug-a, branch/slug-b, ...*`
4. **收尾**：
   ```bash
   ./scripts/gen-index.sh
   ./scripts/lint.sh
   ./scripts/log-append.sh "Compile: 新增/更新 <slug>.md（來自 N 顆 atoms）"
   ```
5. 若 `lint.sh` 報 error（不是 warning），先修完再宣告完成。

### 硬性規則

- **不要 patch wiki 掩蓋 atom 層問題**：wiki 錯是因 atom 錯 → 回去修 atom 再 recompile
- **不要用粗體 / 斜體補救不清楚的寫作**：需要強調才看得懂 = 該重寫
- **不要單顆 atom 一頁**：典型 3–8 顆 atoms 合成一頁
- **並行 compile 一定要先鎖 slug**：否則會出現 `mcp-server.md` 與 `mcp-server-design.md` 這種命名碰撞

### 使用者參數
$ARGUMENTS
