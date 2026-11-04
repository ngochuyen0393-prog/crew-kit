---
name: crew-kit
description: >-
  Use whenever the user wants multi-agent parallel work on a project, in ANY of these
  phrasings (never wait for exact terms): 装配泳道/开泳道/泳道体系, 给项目装上那套多agent的
  东西/体系, 多个AI同时干活/并行开发/并行写代码, 派活/派单/分派任务给其他agent/工人, 开几个
  工人/开几个agent/开新工作区干活, 当工头/当队长/管一群agent, 合并列车/merge train/READY,
  or English: crew, lane, bootstrap crew, multi-agent crew, agent fleet, workers.
  Covers three roles: bootstrapping a project crew drive (new project), acting as captain
  CONTROLLER (dispatching lanes, merge trains), acting as a lane (submitting READY).
  Pairs with gstack's /captain discipline (rules source of truth); provides the local
  no-remote machinery. Do NOT use for single-agent work, plain Orca worktree handoff with
  no crew drive requested, or when the user just wants one subagent.
---

# crew-kit · captain × Orca 泳道体系（全局版）

多泳道协作的通用机械层：**纪律哲学来自 gstack `/captain`（规则原文以其 docs 为准），本技能提供本地无远端适配的模板与验证器**。每个项目一套实例盘（参数本地），机械与模板全局共享（本目录）。

## 何时干什么

| 场景 | 动作 |
|---|---|
| 新项目要跑泳道（用户说「装配泳道」「开 crew」） | 按 [bootstrap.md](bootstrap.md) 走装配流程（约 10 分钟） |
| 你是队长（CONTROLLER，工位 A 主 agent） | 读项目盘 `captain-runbook.md` 执行派单/收单/列车 |
| 你是泳道（任务书含 `Lane:` 行） | 读所在仓库根 `AGENTS.md` + 项目盘 `CREW.md`，按铁律干活 |
| 收到 READY 块要验证 | `bash <项目盘>/bin/validate-ready.sh <ready文件>` |

## 设计不变量（改任何文件前必读）

1. **纪律不靠散文**：规则住在 CREW.md 与仓库 AGENTS.md（自动加载）；验收走 validate-ready.sh（只信 git 事实）；散文汇报一律不算数
2. **泳道永不合并**：一切 BASE 合并由队长在列车工作区执行
3. **通用全局、参数本地**：本目录的模板带 `<占位符>`，项目参数只存在于各项目盘的 CREW.md；本目录永不出现具体项目名
4. **不进 gstack 目录**：gstack 是自动更新的托管 clone，本项目技能独立安装，避免被更新冲掉
5. **无远端适配**：READY = 分支 + 全长 SHA + 树哈希 + 本地检查证据；无 PR/CI/stamp（有远端的项目应回归 gstack 原版 captain 流程）

## 文件清单

- [bootstrap.md](bootstrap.md) —— 装配流程（新项目实例化）
- `templates/` —— CREW 契约、泳道纪律 AGENTS、队长手册、任务书、READY、报告、看板、日志、台账（通用占位版）
- `bin/validate-ready.sh` —— READY 机械验证器（参数从项目盘 CREW.md 读取）
