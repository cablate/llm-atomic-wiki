# llm-atomic-wiki

> **Andrej Karpathy 的 [LLM Wiki](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)** 是這整套東西的源頭。
> 我把他的 pattern 從零跑完一輪、踩完該踩的坑，然後加了四個規模大起來後會撐不住的地方。

**584 篇貼文 · 8,668 則回覆 · 630 個原子 · 83 頁 wiki · 11 個分支**

這個 repo 只給你框架——方法論、schema、腳本、資料夾結構。fork 下去跑你自己的素材，我實際的原子跟 wiki 都不在這包裡。

🇺🇸 [English README](README.md) · 📖 [這個 repo 的故事](STORY.zh-TW.md)

---

## 在 Karpathy 的 pattern 上加了什麼

Karpathy 的 gist 用最少的零件把整個 pattern 講完。下面四件事是我跑到一定規模後撞上的問題——是延伸他的做法，不是取代。

```
Karpathy:   raw ─→ wiki
本 repo:    raw ─→ atoms（按主題分支組織）─→ wiki
```

四件事：

**1. 原子層。** Karpathy 從 raw 一步編譯到 wiki。我在中間加了 atoms——一個原子等於一個論點，附 frontmatter（來源、類型、深度、標籤、日期）。原子是 source of truth，wiki 是 derived cache。當 wiki 頁面寫錯事實時，你回到原子查證，不是回到原始素材。這解決了原 gist 留言區 `frosk1` 提的「資訊損失」與「false sense of source of truth」問題。

**2. 主題分支落在原子層。** Karpathy 的 wiki 是扁平的。我把原子按主題分到 repo root 的分支資料夾（一個分支一個資料夾），編譯成扁平的 wiki 頁面、檔名帶主題前綴（`wiki/<branch>-<subtopic>.md`）。原子層好瀏覽、wiki 層好用 index 定位。

**3. 兩層 Lint。** Karpathy 把「找矛盾、幽靈連結、孤立頁面、過時聲明」混成一個 Lint 操作。我拆開：程式層（`scripts/lint.sh`）處理確定性檢查（幽靈連結、孤立頁面、格式違規、時效標記），秒級完成；LLM 層處理語意檢查（矛盾、過期判斷）。程式層先跑，避免 LLM 注意力被格式問題吃掉。

**4. 平行編譯的命名鎖。** Karpathy 一次寫一頁。當 N 個 agent 平行編譯時，會給同一批內容生出不同檔名（`mcp-plus-skills.md` vs `mcp-plus-skills-architecture.md`）。解法是 fan out 之前先鎖定 slug 命名空間。Agent 把內容填進預定義好的槽位，不負責取名字。

---

## 證據

| 階段 | 數值 |
|------|------|
| 原始素材 | 584 篇貼文 + 8,668 則回覆 + 講座/課程素材 |
| 過濾通過率 | 貼文留 70–90%，回覆留約 13%（87% 是噪音） |
| 萃取原子 | 630（immutable，source of truth） |
| 分支數 | 11（一個資料夾一個主題，放在 root） |
| 編譯 wiki 頁 | 83（每頁 3–8 個原子） |
| Lint warnings（收緊後）| 16（從 47 降下來，靠收緊 regex） |
| 最大分支 | 101 個原子 |
| 最小分支 | 23 個原子 |

---

## 流程怎麼跑

```
┌─────────┐  Ingest    ┌────────────┐  Compile   ┌─────────┐
│  raw/   │ ─────────▶ │ <branch>/  │ ─────────▶ │  wiki/  │
│         │  (LLM      │ atom.md    │  (LLM      │ flat    │
│ 素材    │  萃取)     │ atom.md    │  群組)     │ 頁面    │
└─────────┘            │ ...        │            └────┬────┘
                       └────────────┘                 │
                                                      │
                                ┌─────────────────────┼─────────────────────┐
                                ▼                     ▼                     ▼
                          gen-index.sh           lint.sh              log-append.sh
                              │                     │                     │
                              ▼                     ▼                     ▼
                          index.md           lint-report.md            log.md
```

對照 Karpathy 的迴圈：

```
Karpathy:   raw → wiki → {Ingest, Query, Lint}
本 repo:    raw → atoms → wiki → {Ingest, Query, 程式 Lint, LLM Lint}
```

真正的活幹在 atoms 層。Wiki 可以從 atoms 重建，atoms 不能從 wiki 重建。

---

## 這 repo 裡有什麼

```
llm-atomic-wiki/
├── README.md              ← 英文版
├── README.zh-TW.md        ← 你在這
├── STORY.md / STORY.zh-TW.md  ← 跑完一輪的個人故事（雙語）
├── METHODOLOGY.md         ← 6 階段流水線（英文）
├── METHODOLOGY.zh-TW.md   ← 原始中文方法論
├── CLAUDE.md              ← 給 LLM 的 schema
├── LICENSE
│
├── raw/                   ← 你的原始素材丟這（gitignore）
│
├── <branch-1>/            ← 每個主題一個資料夾，原子放裡面（gitignore）
├── <branch-2>/            ← 例：ai-agent/、ai-skills/、mcp/...
├── ...
│
├── wiki/                  ← 編譯產物，扁平（gitignore）
│
├── index.md               ← 自動產生的導航（gitignore）
├── log.md                 ← 變更紀錄，append-only（gitignore）
│
├── templates/
│   ├── atom.md            ← 建新原子時複製
│   └── wiki-page.md       ← 建新 wiki 頁時複製
│
└── scripts/
    ├── lint.sh            ← 程式層 Lint
    ├── gen-index.sh       ← 從 wiki/ 重建 index.md
    ├── log-append.sh      ← 追加一筆變更到 log.md
    └── README.md
```

框架檔（README、METHODOLOGY、CLAUDE、scripts、templates）進版控。實際內容（raw、分支資料夾、wiki、產出的 index/log）gitignore——這是刻意的也是核心設計。這個 repo 是 kit，不是資料。

---

## 快速上手

1. **Fork 這個 repo。**
2. **讀 `METHODOLOGY.md`** ——從 raw 到 wiki 的六階段，加上維護迴圈。
3. **讀 `CLAUDE.md`** ——正式 spec（原子格式、wiki 格式、分支規則、操作、禁忌）。
4. **編輯 `.gitignore`** ——把列出的分支名換成你自己的。
5. **把素材丟進 `raw/`** ——任何文字格式都行。PDF、逐字稿、貼文匯出、文章。
6. **用 LLM 驅動流水線** ——把 Claude Code（或你的 agent）指向 `CLAUDE.md`，叫它 ingest 一批。
7. **每次編譯後跑腳本：**
   ```bash
   ./scripts/gen-index.sh        # 重建 wiki 索引
   ./scripts/lint.sh             # 程式層健康檢查
   ./scripts/log-append.sh "..." # 記錄變更
   ```
8. **每週或大量 ingest 後跑一輪 LLM Lint** ——詳見 `METHODOLOGY.md`。

整個迴圈：`Ingest → Compile → Index/Log → Lint → Query`。隨素材累積反覆跑。

---

## 深入閱讀

- **[STORY.zh-TW.md](STORY.zh-TW.md)** ——個人故事：為什麼跑、什麼有用、什麼出乎意料。
- **[METHODOLOGY.md](METHODOLOGY.md)** ——六階段流水線（骨架 → 段落分類 → 萃取 → 品質整理 → 外部校驗 → wiki 編譯）和三個維護操作。
- **[METHODOLOGY.zh-TW.md](METHODOLOGY.zh-TW.md)** ——原始中文版方法論，內容更詳盡。
- **[CLAUDE.md](CLAUDE.md)** ——告訴 LLM 怎麼操作這個 repo 的正式 spec。

---

## 為什麼這值得（以及什麼時候不值得）

Karpathy 的論點是知識應該是持久的複利產物，不該每次查詢都從原始素材重新生成——Compile 勝過 RAG。我同意，但有條件：

- **知識量在 ~200 頁 wiki 以內。** 超過後 index.md 掃描效能掉，需要搭配向量搜尋。
- **知識相對穩定。** 你整理的是認知地圖、不是即時新聞。更新頻率以天/週計，不是分鐘。
- **有單一觀點主人。** 個人知識整理，不是聚合一百個作者的意見。
- **品質比覆蓋率重要。** 50 頁寫透勝過 500 頁淺淺帶過。

不符合這些條件時，RAG 通常更合適。兩者不互斥——核心知識用 compile、長尾用 RAG。

這 gist 真正的洞察常被低估：Karpathy 的核心貢獻不在 wiki 品質好不好，在**LLM 不會厭倦維護 wiki 這件事**。大多數個人知識系統死掉不是結構爛，是維護成本太高、人撐不住。LLM 把維護成本的性質整個換掉——這才是 gist 指向的真正解鎖點，比任何格式細節都關鍵。

---

## Credit & License

Pattern、schema、操作（Ingest / Query / Lint）、compile > retrieve 的核心論點——全部是 **[Andrej Karpathy](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f)** 的。這個 repo 有用的話，先去讀他的 gist 比先讀我這包更值得。

MIT 授權（見 [LICENSE](LICENSE)）。這包裡的東西：
- 四個加在 Karpathy pattern 上的小擴充（原子層、主題分支、兩層 Lint、平行編譯命名鎖）
- 一份參考實作方法論
- 雙語 README 跟故事文件

fork 後覺得有用的話，去他的 gist 點星比點我的 repo 更該。
