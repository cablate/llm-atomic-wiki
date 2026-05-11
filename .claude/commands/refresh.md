---
description: 重建 index.md、追加 log.md（任何變更後必跑）
argument-hint: "<這次變更的一句話描述>"
---

## /refresh — 變更後收尾

任何 Ingest / Compile 或動到 wiki 之後，一定要跑這個，保持 `index.md` 與 `log.md` 同步。

### 流程

1. **重建 index**：
   ```bash
   ./scripts/gen-index.sh
   ```
2. **記錄變更**：
   ```bash
   ./scripts/log-append.sh "$ARGUMENTS"
   ```
   若 `$ARGUMENTS` 為空，先向使用者要一句話描述（例如 `"Compile: 新增 mcp-server-design.md（來自 5 顆 atoms）"`）。
3. **檢查 log.md 第一行是否正確、日期是否正確**（`log-append.sh` 會 prepend 在 header 後）。

### 何時不需要 lint

`/refresh` 不自動跑 lint。動過 wiki 頁（新增 / 修改）後請另外執行 `/lint`。

### 使用者參數
$ARGUMENTS
