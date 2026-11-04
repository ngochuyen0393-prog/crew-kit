# bootstrap.md · 新项目泳道装配流程（约 10 分钟）

目的：给一个项目实例化泳道体系。产出两样：**项目盘**（`D:/projects/<项目名>-crew/`）+ **仓库内纪律文件**（进 git）。全部参数在装配时向用户问清，不许编造。

## 前置问题（装配前问用户/查仓库确认）

1. 仓库主检出路径？（如 `D:/projects/<项目名>`）
2. 基准分支名？（master / main / …）
3. REQUIRED_CHECKS：收工前必须全绿的检查命令是什么？各自叫什么名（如 `pytest-pure`）？
4. 有没有独占资源要裁决（端口/设备/文件锁）？
5. 有没有泳道禁跑的检查层（如需真实桌面/真实账号的集成层）？

## 装配步骤

1. **建项目盘骨架**：`mkdir -p <盘>/{templates,bin,reports,handoffs,plans}`
2. **拷通用件**：把本技能 `templates/` 下全部文件拷进项目盘 `templates/`；`CREW.md.tmpl` 拷到项目盘根**改名 CREW.md** 并填参数；`AGENTS.md.tmpl` 拷到**仓库根**改名 AGENTS.md（填检查命令与项目盘路径）
3. **填 CREW.md**：至少填实 REPO_PATH / BASE / CHECK_NAMES（验证器机械读取的三行）+ 其余参数与本地规则；独占资源写成 Crew-specific rule 并注明日期与来源
4. **拷验证器**：本技能 `bin/validate-ready.sh` → 项目盘 `bin/`
5. **填仓库 AGENTS.md**：泳道铁律（模板已含），检查命令节按前置问题 3 填
6. **仓库 CLAUDE.md 加指路节**（两行：泳道体系存在 + 开工读 AGENTS.md 与项目盘 CREW.md）
7. **初始化 DIGEST.md / NOTES.md / flaky-ledger.md**（模板自带初始态，填日期）
8. **验证器实测**：用仓库当前分支真实 SHA 造合法 READY 块 → 必须 `READY-VALID`；再伪造 2-3 种（砍短 SHA / 改 pin / 树哈希谎报）→ 必须全部 `READY-REJECT` 且原因正确。**不实测不算装配完成**
9. **提交仓库侧**（AGENTS.md + CLAUDE.md 指路），提交信息中文 + `By CC.` 署名
10. **回写项目知识库**：decisions.md 记定案（装配日期/盘路径/否决项），progress.md 更新

## 提醒

- 任务书只装任务，纪律一行不写（纪律自动加载）
- 有远端（PR/CI）的项目：本套无远端适配不适用，回归 gstack 原版 captain 流程，别硬套
- 模板升级：改本技能 templates/ 后，已有项目盘**不自动跟随**（实例自包含）；下次装配才带上新模板
