---
description: 執行兩層 Lint（先 programmatic，再 LLM）
argument-hint: "[可選：programmatic | llm | full（預設 full）]"
---

## /lint — 兩層 Lint

依據 `CLAUDE.md` 的 Lint 規範執行。

### 流程

參數 `$ARGUMENTS` 決定要跑哪層（預設 `full`）。

#### 1. Programmatic Lint

```bash
./scripts/lint.sh
```

產出 `lint-report.md`，檢查四項：
- Ghost Links（指向不存在頁的連結）— **error**
- Orphan Pages（沒被任何頁連結過來的頁）— warning
- Format Violations（首行非 `# title`、檔名含大寫/底線）— **error**
- Outdated Markers（`最新版`、`截至 YYYY` 等時效字眼）— warning

若有 error，先修；error 全清才繼續 LLM Lint。

#### 2. LLM Lint

只在 programmatic 通過後執行。讀 `index.md` + 所有 `wiki/*.md`（**不讀 atoms** — Lint 檢的是 wiki 層品質），檢查：

1. **Contradictions（矛盾）**— A 頁說 X 是 best practice，B 頁說 X 已 deprecated → 兩邊都標，附路徑與引文
2. **Concept gaps（概念缺口）**— 多頁提到某概念但沒有專屬頁 → 列為候選新頁
3. **Expired claims（過期主張）**— 版本號 / 日期 / 時效字眼 → 驗證或標記
4. **Weak orphans（弱連結）**— 技術上有連結但與其他頁概念關聯薄弱

**輸出**：append 到 `lint-report.md` 的 `## LLM Lint` 區塊，依嚴重度排序（contradictions > concept gaps > expired > weak orphans）。

#### 3. 動作

- 決定要修哪些 → 改 atom → 重新 compile 受影響的 wiki 頁
- 記錄：`./scripts/log-append.sh "Lint: 修正 N 項（contradictions: X, expired: Y ...）"`

### 硬性規則

- **不要在 wiki 層硬修掩蓋 atom 問題**：錯在 atom，就回去改 atom
- **atoms 不可編輯**：發現 atom 錯 → 建新 atom + 舊的加 `superseded_by` + 搬 `_archive/`
- **不要刪 wiki 頁 / atom**：改用 `_archive/`

### 使用者參數
$ARGUMENTS
