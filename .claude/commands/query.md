---
description: 從 wiki 查答案（先讀 index.md 定位，不掃全庫）
argument-hint: "<問題>"
---

## /query — 從知識庫查詢

依據 `CLAUDE.md` 的 Query 規範執行。

### 流程

1. **讀 `index.md`** 定位：絕對不要一次載入整個 wiki。
2. **載入命中的頁面**：只讀 index.md 指向的相關頁，合成回答。
3. **明確區分**：
   - 「這是 wiki 裡已有的內容」
   - 「這是我基於 wiki 的綜合推論」
4. **引用來源**：列出你讀了哪些 wiki 頁（slug）。
5. **回寫判斷**：若你的綜合回答本身值得留存（新的視角 / 整合），主動提議寫回為新 atom（告知建議 branch 與 slug，取得使用者同意後再建立）。

### 硬性規則

- **別把 wiki 當 source of truth** — atoms 才是。若答案有疑問，追到 atom。
- **不要硬編造**：wiki 沒有就老實說沒有；不要拿訓練資料填空而不標示。

### 使用者問題
$ARGUMENTS
