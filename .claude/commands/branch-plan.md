---
description: 設計 / 檢查 / 調整 branch 結構（atoms 目錄分類）
argument-hint: "[可選：propose | review | split <branch> | merge <A> <B> | rename <old> <new>]"
---

## /branch-plan — Branch 結構規劃

Branch（`atoms/<branch>/`）是這個知識庫的骨架。依 `CLAUDE.md` 與 `METHODOLOGY.md` Phase 1 的規範操作，**絕不自行新增 / 改名 / 合併 branch，必須由使用者確認**。

### 子指令（由 `$ARGUMENTS` 判讀）

#### `propose`（預設，當 `atoms/` 還是空的）
- 讀使用者給的 raw/ 清單或對話中描述的知識領域
- 提議一組 branch（每個附上一段 boundary 定義）
- 每個 branch 必須同時滿足四條件：**Independence / Scale（預期 5+ atoms）/ Clear boundary / Teaching independence**
- 只提議，**不建立目錄**；由使用者勾選後再實際建立 `atoms/<branch>/` 資料夾

#### `review`
- 掃 `atoms/` 下每個 branch
- 依 CLAUDE.md「When to merge / remove」「When to split」條款給建議：
  - Hollow（<3 atoms 且無成長軌跡）→ 考慮合併 / 併入 tag
  - Overlap（>50% atoms 與另一 branch tags 重疊）→ 合併或重劃邊界
  - Bloat（>30 atoms 且自然成群）→ 考慮拆分
- 把建議寫到 `lint-report.md` 的 `## Branch Review` 區塊

#### `split <branch>`
- 讀 `atoms/<branch>/` 所有 atoms
- 提議 2–3 個子群的分法，每個附新 branch 邊界
- 使用者確認後：
  1. 建新 branch 目錄
  2. 搬移 atoms、更新每顆 frontmatter `id`
  3. Recompile 受影響的 wiki 頁
  4. `scripts/log-append.sh "Branch split: <old> → <new-1>, <new-2>"`

#### `merge <A> <B>`
- 讀兩 branch 所有 atoms，評估是否真的該合併
- 使用者確認後：搬移 → 改 id → recompile → log

#### `rename <old> <new>`
- 改目錄、改所有 atom frontmatter 的 `id` 前綴、改所有 wiki 檔名前綴與 `[[link]]`
- 跑 `gen-index.sh` + `lint.sh` 確認無 ghost links
- log-append

### 硬性規則

- **最終定奪在使用者**：AI 不知道你的教學定位與內容差異化，只提議
- **Branch 只用小寫連字號**（`harness-engineering` 不是 `HarnessEngineering` 或 `harness_engineering`）
- **不要 `rm`**：被淘汰的 branch 整個搬到 `atoms/_archive/<branch>/`

### 使用者參數
$ARGUMENTS
