---
description: 從 raw/ 擷取新素材為 atoms（依 CLAUDE.md schema）
argument-hint: "[可選：要處理的 raw/ 子路徑或檔名，如 raw/posts-2026-04.md]"
---

## /ingest — 擷取原始素材為 atoms

依據 `CLAUDE.md` 與 `METHODOLOGY.md` 的規範執行 Ingest 操作。

### 流程

1. **掃描 raw/**：若 `$ARGUMENTS` 有指定檔案 / 子路徑，只處理該範圍；否則列出 `raw/` 內所有新檔案並詢問要先處理哪一批。
2. **Phase 2 分段分類**：對每段內容標記 `extract` / `skip` / `deferred`，並依 `METHODOLOGY.md` 表格的預期萃取率做為對照。
3. **Phase 3 萃取**：
   - 每顆 atom 一個核心主張（one atom, one claim）
   - frontmatter 嚴格照 `CLAUDE.md` 的欄位，不要發明欄位
   - 檔名 `YYYY-MM-DD-<slug>.md`，全小寫、用連字號
   - 不知道該放哪個 branch 時列為 deferred candidate，**不要自行新增 branch**；先向使用者確認
4. **首批校準**：第一批 10–20 段後，主動向使用者匯報分類與萃取品質，取得確認後再繼續。
5. **收尾**：
   ```bash
   ./scripts/gen-index.sh
   ./scripts/log-append.sh "Ingest: <來源> → <branch>/... 新增 N 顆 atoms"
   ```

### 硬性規則

- **raw/ 唯讀**：不可修改 raw/ 下任何檔案
- **atoms 不可變**：已建立的 atom 不可編輯；要更新請建新 atom + 舊 atom 加 `superseded_by` + 搬到 `_archive/`
- **保留作者語氣**：這是個人知識庫，不是中性百科
- **不要複製貼上**：要精煉，不是加個標題就算 extract（見 METHODOLOGY.md 的「Bad atom vs Good atom」對照）
- **source_ids 必填**：沒有來源追溯的 atom 無法稽核

### 使用者參數
$ARGUMENTS
