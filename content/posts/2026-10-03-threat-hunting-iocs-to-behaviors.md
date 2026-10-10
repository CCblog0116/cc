---
title: "Day 48 — Threat Hunting for APT Activity: From IOCs to Behaviors"
date: 2026-10-03
tags:
  - daily
  - security
  - english
description: "前两课我们学会了拆解 APT 入侵链路、认识主要威胁组织。今天解决最后一环：如何把公开报告里的情报，转化为自己环境里可执行的狩猎（hunting）动作 —— 从'等人报警'升级为'主动找敌人'。"
---

**Date:** 2026-10-03 | **Difficulty:** ★★★★☆ Deep（深度阶段）
**Sources:** MITRE ATT&CK (https://attack.mitre.org/) · CISA AA20-352A (SUNBURST) · Splunk Security ES / hunting guides · Sigma HQ (https://github.com/SigmaHQ/sigma) · SANS Threat Hunting summit materials

> 前两课我们学会了拆解 APT 入侵链路、认识主要威胁组织。今天解决最后一环：**如何把公开报告里的情报，转化为自己环境里可执行的狩猎（hunting）动作** —— 从"等人报警"升级为"主动找敌人"。

---

## 1. What Is Threat Hunting?（什么是威胁狩猎）

**Threat hunting（威胁狩猎）** is a **hypothesis-driven（假设驱动）**, proactive search for attackers who are **already inside** your environment but have not triggered any alert. Alert triage（告警分诊）is *reactive* — you respond to what your sensors caught. Hunting is *proactive* — you assume something was missed and go look for it.

The core insight comes from the **Pyramid of Pain（痛苦金字塔）** we met on Day 37: IOCs（失陷指标，如 hash/IP/domain）are trivial for an attacker to rotate; **TTPs（战术、技术与程序）** are expensive to change. Therefore:

- **IOC hunting（指标狩猎）**: fast, cheap, low value long-term — good for checking "were we hit by yesterday's headline campaign?"
- **Behavior hunting（行为狩猎）**: slower, harder, durable — "is *anything* in my estate doing what APT29 does when it forges tokens?"

A mature hunt answers a **detection hypothesis（检测假设）**: *"If an attacker used technique X in my environment, would I see artifact Y in data source Z?"*

简短中文讲解：狩猎不是漫无目的地翻日志，而是先有假设（"如果有人这样攻击，我应该在 X 数据源看到 Y 痕迹"），再用查询去证实或证伪。

## 2. The Hunting Loop（狩猎循环）

Most hunt methodologies (TaHiTI, PEAK, SQRRR) share the same loop:

```
        ┌─────────────────────────────────────────────┐
        │  1. PREPARE                                 │
        │     Trigger: new intel report / ATT&CK gap  │
        │     Scope:   which assets, which timeframe  │
        │     Data:    do I even HAVE that telemetry? │
        └──────────────────┬──────────────────────────┘
                           ▼
        ┌─────────────────────────────────────────────┐
        │  2. EXECUTE (investigate)                   │
        │     Run queries → pivot → enrich → repeat   │
        └──────────────────┬──────────────────────────┘
                           ▼
        ┌─────────────────────────────────────────────┐
        │  3. RESPOND                                 │
        │   True positive  → IR process (Day 7/46)    │
        │   False positive → tuning & allowlist       │
        │   Nothing found  → keep query as scheduled  │
        │                    detection rule           │
        └──────────────────┬──────────────────────────┘
                           ▼
        ┌─────────────────────────────────────────────┐
        │  4. DOCUMENT                                │
        │     Hypothesis, queries, findings, gaps     │
        │     → feeds the next hunt                   │
        └─────────────────────────────────────────────┘
```

**Key discipline:** every hunt must end in an artifact — a detection rule, a tuning change, or a documented **telemetry gap（遥测盲区）**. A hunt that produces only "nothing found" and no written record is wasted work.

简短中文讲解：狩猎四步循环——准备（定假设和数据源）、执行（查询与下钻）、响应（真警转应急/误警做调优/无发现则沉淀为常态化规则）、记录（假设与查询入库，喂给下一次狩猎）。

## 3. From Intel Report to Hunt Query（从情报报告到狩猎查询）

Let's walk the full pipeline using **SUNBURST / Golden SAML** (Day 46) as the worked example.

**Step 1 — Extract TTPs from the report.** Reading CISA AA20-352A, we extract:

| ATT&CK Technique | Behavior | Data Source Needed |
|---|---|---|
| T1552.004 Private Keys | ADFS certificate / signing-key export | Windows Security Event Log, EDR file/key-access |
| T1550.001 Golden SAML | Token signing without any interactive login | ADFS audit logs, Entra ID sign-in logs |
| T1070.006 Timestomp | Tampering with file timestamps | MFT / Sysmon file events |
| T1098 Account Manipulation | New federation trust / added credentials | Entra ID audit logs |

**Step 2 — Check coverage before writing queries.** The deadliest mistake is hunting in data you don't collect. Ask: *Do we forward ADFS audit logs (Event IDs 505/510/511) to SIP? Do EDR agents cover the ADFS servers at all?* If not, fixing the gap **is** the first hunt deliverable.

**Step 3 — Write the hunt query.** Example: hunting LSASS（本地安全机构子系统的进程内存，存有凭据）credential access with Sysmon Event ID 10:

```sql
-- Splunk SPL: suspicious handle access to lsass.exe
index=sysmon EventCode=10 TargetImage="*\\lsass.exe"
  NOT (SourceImage="*\\csrss.exe" OR SourceImage="*\\wmiprvse.exe"
       OR SourceImage="*\\svchost.exe")
| stats count values(SourceImage) as accessors by Computer, GrantedAccess
| where GrantedAccess IN ("0x1010", "0x143A", "0x147A", "0x1FFFFF")
```

Example: hunting **Golden SAML** behavioral signature — a token authenticated against cloud resources whose corresponding sign-in has **no interactive/logon precursor** on the ADFS side:

```sql
-- Token works, but no corresponding ADFS sign-in event in preceding window
index=azuread signin (result="success")
| join user [ search index=adfs EventCode IN (501,505,510) earliest=-15m ]
| where isnull(adfs_event)
| stats count by user, app, ip
```

**Step 4 — Automate survivors.** Any query that ran clean but *should* always stay clean gets scheduled (daily/weekly) and converted — ideally into a **Sigma rule（一种厂商中立的检测规则标准）** so it ports across SIEMs:

```yaml
title: Suspicious OpenProcess on LSASS
logsource:
    product: windows
    service: sysmon
detection:
    selection:
        EventID: 10
        TargetImage|endswith: '\lsass.exe'
        GrantedAccess|contains:
            - '0x1010'
            - '0x143A'
    filter_legitimate:
        SourceImage|startswith: 'C:\Windows\'
    condition: selection and not filter_legitimate
```

简短中文讲解：四步法——从报告提取 ATT&CK 技术项 → 先确认数据源是否在采（没有就先补采集）→ 写假设查询并下钻 → 干净且应长期干净的查询沉淀为 Sigma/计划任务规则。

## 4. High-Value Hunt Patterns for APT Activity（APT 狩猎的高价值模式）

| Hunt Pattern | Hypothesis | Sources |
|---|---|---|
| **Beaconing（周期性回连）** | Regular-interval outbound connections with low jitter to rare domains | NetFlow/Zeek, proxy logs (Day 36) |
| **LotL abuse（离地生存）** | `powershell -enc`, `certutil -urlcache`, `wmic process call create` on servers | Sysmon EID 1, EDR process tree |
| **Dormant-account login（休眠账号登录）** | Account with 60+ days of no activity suddenly authenticating from new ASN | VPN/SSO logs |
| **Impossible travel** | Same identity, two geographies in shorter time than physically possible | Entra ID / SSO logs |
| **Federation tampering（联邦认证篡改）** | New federation domain, cert update, or added MFA-exclusion on privileged accounts | Cloud audit logs |
| **Staging before exfil（外带前聚集）** | Unusual archive creation (`rar/7z/zip` with password) followed by large outbound upload | EDR file events + proxy/flow volume |

Note the pattern: most of these detect **behaviors and sequences**, not hashes. That is exactly why they survive attacker infrastructure rotation.

## 5. Common Pitfalls（常见陷阱）

- **Hunting on data you don't have.** Coverage check comes before query writing — always.
- **Vanity hunts.** Hunting the newest headline campaign instead of the technique your ATT&CK coverage matrix (Day 45) shows is weakest.
- **No documentation.** Undocumented hunts cannot be peer-reviewed, repeated, or promoted into detections.
- **Treating hunt queries as one-offs.** If clean today, it should be scheduled tomorrow — hunting is how detection engineering（检测工程）gets its backlog.
- **Ignoring false positives as "noise".** Every false positive is free tuning knowledge; allowlist it explicitly or the next analyst drowns.

---

## 甲方视角思考

- 先画覆盖率再写查询：用 Day 45 的 ATT&CK 覆盖矩阵挑缺口（建议首选 ADFS/SSO 日志采集和 Sysmon 覆盖），把"补采集"本身当作第一次狩猎的交付物。
- 把 Day 46 学的 Golden SAML 假设直接落地：在 SIP 上建"云端登录成功但 ADFS 侧无前兆登录"的关联规则，这正是你正在跟进的 SSO 接口场景的延伸。
- 每周固定一个"狩猎小时"：从 FreeBuf/Krebs/BleepingComputer 读完的 APT 报告里挑 1 个 TTP，转化为一条查询跑一遍，输出进检测规则 backlog。
- 狩猎产物统一进 Sigma 格式管理，方便日后 SIEM 更换时规则可迁移；误报必须显式 allowlist 并写明理由，而不是口头"这个不用管"。

---

**Key Terms**

| English | 中文 | 备注 |
|---|---|---|
| Threat hunting | 威胁狩猎 | 主动在环境中搜寻未被告警捕获的攻击者 |
| Hypothesis-driven | 假设驱动 | 先提出可证伪的检测假设，再用数据验证 |
| Alert triage | 告警分诊 | 被动响应已有告警，与狩猎互补 |
| IOC hunting | 指标狩猎 | 用 hash/IP/域名直接比对，快但易失效 |
| Behavior hunting | 行为狩猎 | 基于 TTP 序列搜索，更难但更持久 |
| Pyramid of Pain | 痛苦金字塔 | 指标易换、行为难改的层级模型 |
| Telemetry gap | 遥测盲区 | 应采集而未采集的数据源缺口 |
| Coverage check | 覆盖率检查 | 写查询前先确认数据是否存在 |
| Pivot | 下钻/转枢 | 从一个发现跳到关联数据继续追查 |
| Enrichment | 情报富化 | 给原始事件补充上下文（资产、身份、情报） |
| True positive | 真实告警 | 转入事件响应流程 |
| False positive | 误报 | 显式 allowlist 并记录原因 |
| Scheduled detection | 计划任务检测 | 把狩猎查询固化为周期执行的规则 |
| Sigma rule | Sigma 规则 | 厂商中立的检测规则格式，可跨 SIEM 移植 |
| Detection engineering | 检测工程 | 把假设持续转化为检测规则的工程化过程 |
| Beaconing | 周期性回连 | 恶意软件按固定间隔连回 C2 的行为 |
| Low jitter | 低抖动 | 回连间隔过于规律，是 C2 的典型特征 |
| Dormant account | 休眠账号 | 长期未使用突然登录的账号，高危信号 |
| Impossible travel | 不可能旅行 | 同一身份短时间异地登录 |
| Process tree | 进程树 | EDR 记录的父子进程链，识别 LotL 滥用的关键 |
| Hunt backlog | 狩猎待办 | 已登记待执行的假设清单 |
| ATT&CK coverage matrix | ATT&CK 覆盖矩阵 | 按技术项统计检测覆盖情况的矩阵 |

**Tomorrow's Preview (Day 49)**: 深度阶段第四课：**Detection Engineering: Writing Sigma Rules That Survive**（检测工程：写出经得起时间考验的 Sigma 规则）——学习检测规则的字段选择、误报控制、测试（ Atomic Red Team 验证）与版本化管理，把狩猎成果工程化沉淀。
