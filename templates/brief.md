# 派单任务书（本地版）

CONTROLLER 派泳道时发的一段文字（Orca `orca worktree create --agent claude --prompt "<本模板填充后>"` 或对既有工人 `orca terminal send`）。泳道先读仓库 AGENTS.md 与 `DRIVE/CREW.md`，再读本任务书。

```text
Lane: <泳道代码，如 L1> · Controller: captain · Crew: live-cockpit
Branch: <feature/<任务名>>（从 master 切）
Worktree: 由 Orca 创建，路径即你所在目录
Owns: <本泳道可编辑的文件/目录清单；清单外一律报 CONTROLLER>
Do not touch: <其他在岗泳道的文件，逐条列>
Plan: required | exempt: <豁免理由，见 CREW.md 规则11>
Scope: <干什么，一段话；验收标准写清楚>

开工四步：
0. 环境初始化：按仓库约定装依赖（如 `uv sync` / `cd shell && npm install`）——REQUIRED_CHECKS 依赖它们，裸依赖跑检查必红
1. 读 D:/projects/live-cockpit-crew/CREW.md（契约）与你所在仓库的 AGENTS.md（纪律）
2. 首次汇报第一行发机械行：LANE <code> onboarded crew=live-cockpit base=master head=<sha12> drive-ok=<yes|no>
3. Plan: required 时，先报大白话计划等批准再动产品代码；exempt 直接干

干完（收工三件套，缺一不算完）：
1. 在冻结的分支头上跑 CREW.md 的 REQUIRED_CHECKS，两条全绿
2. 向 CONTROLLER 交 READY 块（templates/READY.md 格式）
3. 写 D:/projects/live-cockpit-crew/reports/<code>.md（templates/report.md 格式）

永不：merge/rebase 进 master、碰别的泳道分支、抢 9121 端口（规则13）、READY 后继续 push。
```

## 填写要点（CONTROLLER 备忘）

- `Owns:` 必须列全——模糊所有权 = 冲突隐患
- `Do not touch:` 对照 DIGEST.md 的 In progress 表填
- 两条泳道会抢 9121 时，先按规则 13 裁决再派单
- 任务书只装**任务本身**；纪律不进任务书（纪律在仓库 AGENTS.md 自动加载，散文不需要 100% 执行）
