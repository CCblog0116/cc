---
title: "Day 49 — Detection Engineering: Writing Sigma Rules That Survive"
date: 2026-08-11
tags:
  - daily
  - security
  - english
description: "Yesterday you learned to hunt threats from IOCs to behaviors. Today we turn those hunting wins into detections that survive — rules that keep firing t"
---

**日期**: 2026-10-04
**难度**: ★★★★☆ 深度
**来源**: Sigma HQ (https://github.com/SigmaHQ/sigma) · The Detections Repository / sigmahq docs · Atomic Red Team (https://github.com/redcanaryco/atomic-red-team) · Elastic Detection Rules 项目实践
**链接**: https://github.com/SigmaHQ/sigma · https://github.com/redcanaryco/atomic-red-team

> Yesterday you learned to hunt threats from IOCs to behaviors. Today we turn those hunting wins into **detections that survive** — rules that keep firing true positives months later, without drowning you in false positives (误报) or breaking when the SIEM changes. This is **detection engineering (检测工程)**: the craft of writing, testing, and maintaining detection rules as software.

*昨天你学会了从 IOC 到行为的威胁狩猎，今天把狩猎成果工程化：写出"活得久"的检测规则——不误报泛滥、不怕 SIEM 更换。*

---

## 1. Why Rules Die — and Why Sigma

Most detection rules written in a vendor's proprietary query language die within a year for three reasons: they were **overfit to one sample** (针对单个样本过拟合), they fired so many false positives that analysts muted them, or they broke silently when log schemas changed.

**Sigma** solves the portability problem. It is a vendor-neutral, YAML-based rule format (厂商中立的检测规则格式). One Sigma rule can be compiled to Splunk SPL, Microsoft Sentinel KQL, Elastic Lucene/EQL, or Qradar AQL via **PySigma** pipelines. If you change SIEM platforms, your rules travel with you — exactly why yesterday's hunt output should be stored in Sigma format.

*多数检测规则一年内就"死"：过拟合、误报太多、或日志字段变更后静默失效。Sigma 用厂商中立的 YAML 格式解决了可移植性问题——一份规则可编译到 Splunk、Sentinel、Elastic 等任意 SIEM。*

## 2. Anatomy of a Rule That Survives

```
title: AdFind Active Directory Recon          ← 1 line, what it detects
id: 4561d9e8-...                              ← stable UUID, never reuse
status: test                                  ← lifecycle: stable / test / deprecated
description: >
  Detects the use of AdFind.exe, a common tool
  abused by APT actors for AD reconnaissance.
references:
  - https://attack.mitre.org/techniques/T1087/002
tags:
  - attack.discovery                          ← ATT&CK tactic
  - attack.t1087.002                          ← ATT&CK technique (enables coverage tracking)
logsource:
  category: process_creation                  ← semantic, not vendor-specific
  product: windows
detection:
  selection_img:
    Image|endswith: '\adfind.exe'             ← stable field, fuzzy match
  selection_cmd:
    CommandLine|contains:
      - ' -f '
      - ' -gcb '
      - '(objectcategory='
  condition: 1 of selection_*                 ← OR across selections
falsepositives:
  - Legitimate AD administration (documented admin hosts)
level: high
```

Every field here has a survival purpose:

| Field | Why it matters for rule survival |
|---|---|
| `id` (UUID) | Deduplication, tuning history, cross-repo references — never regenerate it |
| `status` | `test` → `stable` → `deprecated` lifecycle makes retirement explicit |
| `tags` (ATT&CK) | Lets you measure coverage per technique, not per rule |
| `logsource` (semantic) | `category: process_creation` maps to any EDR/Sysmon source, not one vendor field |
| `falsepositives` | Forces the author to think about noise **before** deployment |
| `level` | Communicates urgency to the Tier 1 analyst who gets the alert at 3 a.m. |

*每个字段都是为了"活下来"：UUID 用于去重与调优历史，status 表达生命周期，ATT&CK 标签支撑覆盖率度量，语义化 logsource 保证跨平台可移植，falsepositives 强制作者先想清楚噪声。*

## 3. Field Selection: The Hidden Half of Rule Quality

A rule is only as portable as its fields. Three principles:

1. **Prefer semantic fields (语义化字段)** — `process_creation`, `network_connection` — over raw vendor fields. In the backend, a PySigma pipeline maps them to `EventID 4688` or Sysmon Event ID 1 or your EDR's equivalent.
2. **Prefer behavior-bearing fields (承载行为的字段)** — `CommandLine`, `ParentImage`, `DestinationHostname` — over volatile ones like hashes or process GUIDs. A hash dies when the attacker recompiles; the *behavior* stays.
3. **Normalize before you match (先归一化再匹配)** — use modifiers like `|endswith`, `|contains|all`, `|re` deliberately. Case sensitivity and path variations (`C:\Users\`, `\\Device\HarddiskVolume...`) are the top source of silent misses.

*字段决定规则的可移植性：优先语义化字段和行为承载字段，少用易变字段；路径大小写与设备路径差异是"静默漏报"的头号来源，用修饰符显式处理。*

## 4. False Positive Control: Filters, Not Mutes

The worst failure mode is a rule so noisy that analysts tune it out mentally. Sigma handles false positives with **filter selections (过滤选择器)** — explicit, auditable exclusions inside the rule:

```yaml
detection:
  selection:
    Image|endswith: '\powershell.exe'
    CommandLine|contains: '-enc'
  filter_admin_host:
    ParentImage|startswith: 'C:\Program Files\YourConfigTool\'   # documented admin tool
  filter_service_account:
    User|endswith: '$'                                            # machine accounts
  condition: selection and not 1 of filter_*
```

Three disciplines:

- **Every filter needs a written justification** in `falsepositives`. "这个不用管" is not a filter reason.
- **Narrow first, widen later**: start with `1 of selection_*` style tight logic, and only loosen it after a week of clean data.
- **Count the suppression**: if a filter excludes 500 events/day, the filter itself is a risk — an attacker could masquerade as the excluded pattern (e.g., naming their implant `YourConfigTool.exe`).

*误报控制靠显式 filter 而不是默默静音：每条 filter 必须写明理由；排除量过大时，filter 本身就成了攻击者可伪装的盲区。*

## 5. Testing: Prove the Rule Fires Before You Trust It

A rule that has never fired is a hypothesis, not a detection. The standard validation loop uses **Atomic Red Team (ART, 原子红队)** — an open-source library of small, controllable tests mapped to ATT&CK techniques:

```
  ┌──────────────┐    ┌──────────────┐    ┌──────────────┐
  │ Draft rule   │ →  │ Run ART test │ →  │ Rule fires?  │
  │ (status:test)│    │ T1087.002    │    │  ├─ yes ─┐   │
  └──────────────┘    └──────────────┘    │  │        │   │
                                          │  └─ no ◄──┤   │
                                          └───────────┼────┘
                                                      ▼
     ┌────────────┐   ┌──────────────┐   ┌─────────────────┐
     │ Stable in  │ ← │ Tune + add   │ ← │ Stage 1 week    │
     │ production │   │ filter_ blocks│  │ detection-only  │
     └────────────┘   └──────────────┘   └─────────────────┘
```

Practical sequence for one rule:

1. **Draft** the Sigma rule, `status: test`.
2. **Execute the matching ART atomic** on a lab endpoint (e.g., run AdFind against a test domain).
3. **Confirm end-to-end**: the alert lands in your SIEM/SIP with the right severity and fields. A rule that fires in the SIEM UI but never reaches the analyst's queue is broken — check the routing logic.
4. **Stage in detection-only mode for ~1 week**, count alerts, write filters for the false positives you actually see (not ones you imagine).
5. **Promote to `stable`** with a date and tester in the rule's change history.

*用 Atomic Red Team 验证规则"真的会响"：起草 → 跑 ART 用例 → 确认端到端告警入队 → 侦查模式跑一周补 filter → 才能转 stable。从未触发过的规则只是假设，不是检测。*

## 6. Version Management: Rules Are Code

Treat your rule repository like source code:

| Practice | Implementation |
|---|---|
| Git repository | Every rule change is a commit; review before merge, like code review |
| Rule repo upstream | Track [Sigma HQ](https://github.com/SigmaHQ/sigma) updates; do **not** blindly fork vendor rules without reading `falsepositives` |
| Lifecycle states | `test` (staging) → `stable` (deployed) → `deprecated` (retired but kept for reference) |
| Change history | Record tuning decisions in commits: *why* the filter exists, who approved it |
| Retirement review | Quarterly review: rules with zero fires **and** zero ART validation get flagged, then deprecated |
| Rule-to-technique matrix | Maintain an ATT&CK coverage matrix (Day 45/48) driven by rule `tags`, so "do we detect T1087.002?" is answerable in seconds |

The retirement step is the most neglected. A rule library with dead rules is worse than no library — it inflates the coverage matrix with false confidence (虚假的覆盖率).

*把规则库当代码管理：Git 版本化、生命周期状态、变更理由入 commit、季度退役评审。死规则会让覆盖率矩阵产生虚假信心，退役评审是被忽视最严重的一环。*

## 7. Common Pitfalls (误报控制常见坑)

| Pitfall | Why it kills the rule | Fix |
|---|---|---|
| Writing from one sample | Matches only that binary's hash/name; attacker recompiles → silent miss | Anchor on behavior (CommandLine patterns, parent-child relationships) |
| `contains` on overly generic strings | e.g. `CommandLine\|contains: 'net '` fires on legitimate admin work constantly | Require multi-token patterns (`net group`, `(objectcategory=`) |
| No `falsepositives` field | Analyst discovers noise in production, tunes rule out of the queue | Force FP thinking at authoring time |
| Hardcoded vendor fields | Rule breaks on SIEM migration or log source change | Use semantic `logsource` + PySigma pipeline mapping |
| Fire-and-forget deployment | Log schema drift silently empties the rule | Monthly "rule health" check: event volume per rule |
| No retirement | Dead rules fake coverage in the ATT&CK matrix | Quarterly deprecation review |

---

## 甲方视角思考

- 把规则库当代码：Git 管理 + 生命周期状态 + ATT&CK 标签，换 SIEM 时规则可整体迁移——你正处在 SIP 建设期，现在定格式最划算。
- 每条 filter 必须写理由并记录排除量：排除量异常大本身就是风险信号，攻击者最爱藏在"合法例外"里。
- 用 Atomic Red Team 每月抽 2-3 条 stable 规则做验证，连续两次未触发的规则进入退役评审——别让死规则污染覆盖率矩阵。
- 你的 SSO 场景直接受益：把 Day 48 的 Golden SAML 狩猎查询写成 Sigma（`status: test` 起步），ART 没有对应用例就用 lab 环境手工触发一次。

---

**Key Terms**

| English | 中文 | 备注 |
|---|---|---|
| Detection engineering | 检测工程 | 把检测假设工程化为规则并持续维护 |
| Sigma rule | Sigma 规则 | 厂商中立的 YAML 检测规则格式 |
| PySigma | — | 将 Sigma 编译为各 SIEM 查询语言的工具链 |
| Pipeline (conversion) | 转换管道 | Sigma 后端到目标 SIEM 语法的映射配置 |
| Semantic logsource | 语义化日志源 | 用 category/product 描述而非厂商专属字段 |
| Field normalization | 字段归一化 | 匹配前统一路径、大小写、格式差异 |
| Modifier | 修饰符 | Sigma 匹配操作符，如 endswith / contains / re |
| Filter selection | 过滤选择器 | 规则内显式的误报排除逻辑 |
| False positive (FP) | 误报 | 合法行为触发的告警 |
| False negative (FN) | 漏报 | 攻击发生但规则未触发，更危险 |
| Overfitting | 过拟合 | 规则只匹配单个样本，攻击者一变即失效 |
| Behavior anchoring | 行为锚定 | 基于 TTP/命令模式而非哈希写规则 |
| Atomic Red Team (ART) | 原子红队 | 开源 ATT&CK 技术验证用例库 |
| Detection-only staging | 侦查模式上线 | 先只告警不处置，观察误报一周 |
| Rule promotion | 规则晋级 | test → stable 的评审升级过程 |
| Rule retirement | 规则退役 | 显式标记废弃，避免虚假覆盖率 |
| Rule health check | 规则健康检查 | 周期核查每条规则的事件量与触发量 |
| ATT&CK coverage matrix | ATT&CK 覆盖矩阵 | 按技术项统计检测覆盖情况 |
| Silent miss | 静默漏报 | 字段变更导致规则永远不匹配 |
| Alert queue | 告警队列 | 分析师实际处理告警的入口，端到端验证的终点 |
| Change history | 变更历史 | 记录每次调优的理由与审批人 |
| Dwell time | 驻留时间 | 攻击者在环境中未被发现的时长，规则质量的最终指标 |

**Tomorrow's Preview (Day 50)**: 深度阶段第五课：**Purple Teaming: Continuously Validating Your Detections**（紫队作战：持续验证你的检测体系）——学习紫队协作模式、攻击模拟的节奏安排、以及如何用验证结果驱动检测规则与 SOC 流程的持续改进，把 Day 40/49 的检测能力闭环。
