# ai-rules

团队 AI 编程规则、复盘结论与模板的公共仓库。`main` 每次合入后，`.github/workflows/distribute.yml` 以固定 Commit 向各业务仓库分发，业务仓库通过 `git subtree` 同步到 `docs/common/`。

- `scripts/trigger-downstreams.sh`：向下游发送 `repository_dispatch`
- `scripts/sync-subtree.sh`：由下游按固定 Commit 拉取并执行的同步脚本
- `scripts/verify-distribution.sh`：源端巡检，以下游 `main` 的 `docs/common/.ai-rules-sync.json` 为准判定成功
