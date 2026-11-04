# READY 块（本地版）

泳道干完活向 CONTROLLER 交的唯一有效完工凭证。CONTROLLER 用 `bin/validate-ready.sh` 逐字段机械验证；缺字段/字段对不上 git 事实 = 打回泳道，永不进列车。

## 格式（泳道原样照抄结构，替换尖括号）

```text
READY <branch> <sha40>
pin: <sha40>                      # 全长头 SHA，必须与上一行一致
base: master@<master当前sha12>
tree: <该头的树哈希sha40>          # git rev-parse <branch>^{tree}
checks: pytest-pure=green shell-test=green   # 两项都是在该头实测：命令+退出码，红就写红
test-count: <通过数> passed / <失败数> failed
flaky: <none | 用例名, 两次run标识, 已登记handoffs/flaky-ledger.md@日期>
review passes: <n>（搁置项: <无 或 列表>）
Head frozen from now on; a push drops this READY and I will READY again.
```

## 字段规则

- `<branch>`：泳道自己的分支（`BASE` 以外的名，任务书指定）
- `<sha40>`：**全长 40 位**，短 SHA 打回
- `checks:` 两项必须都写；任何一项非 green = 不叫 READY，别交
- `flaky:` 有重跑必须先登记台账再交块
- 最后一行冻结声明必须有——它是「之后 push 作废」的合同线

## 队长打回条件（validate-ready.sh 覆盖）

- SHA 不足 40 位 / 分支尖端 ≠ 声明头 / 树哈希对不上
- `pin:` 缺失或与头不一致
- `checks:` 缺项或非全绿
- `base:` 与 CREW.md 的 BASE 不符
- 冻结声明行缺失
- `flaky:` 提到用例但台账里没有登记

## 示例

```text
READY feature/mb-incread 3f9c1a7b2e8d4f6a9b0c1d2e3f4a5b6c7d8e9f0a
pin: 3f9c1a7b2e8d4f6a9b0c1d2e3f4a5b6c7d8e9f0a
base: master@dc21e54a9b01
tree: 8c2f…（40位）
checks: pytest-pure=green shell-test=green
test-count: 34 passed / 0 failed
flaky: none
review passes: 1（搁置项: 无）
Head frozen from now on; a push drops this READY and I will READY again.
```
