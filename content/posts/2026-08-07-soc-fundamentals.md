---
title: "Day 45 — Security Operations Center (SOC) Fundamentals"
date: 2026-08-07
tags:
  - daily
  - security
  - english
description: "A Security Operations Center SOC，安全运营中心 is not a room full of screens — it is the process by which an organization detects, triages 分诊, investigates 调"
---

**日期**: 2026-09-30 (Wednesday)
**难度**: ★★★☆☆ 技术 (Day 22–45 技术阶段收官)
**来源**: SANS SOC Survey + NIST SP 800-61 + MITRE ATT&CK + Splunk SOC Docs
**链接**: https://www.sans.org/blog/sans-2024-soc-survey/ · https://csrc.nist.gov/pubs/sp/800/61/r3/final

---

A **Security Operations Center** (SOC，安全运营中心) is not a room full of screens — it is the *process* by which an organization detects, triages (分诊), investigates (调查), and responds to security events, day and night. Everything we covered in Days 22–44 — SSRF logs, EDR telemetry (终端遥测), WAF alerts, DDoS alarms, threat intelligence (威胁情报) — eventually flows into one place: a queue of alerts that a human, or an increasingly capable machine, must decide what to do with. 前面学的所有检测手段，最终都要汇入 SOC 的告警队列，由人来做决定。

## The Tier Model: Who Does What

Most SOCs organize analysts in tiers (分级)， each with a distinct mission. The model matters because it defines **escalation paths** (升级路径) — knowing when to hand off is as much a skill as knowing how to investigate.

| Tier | Role | Focus | Typical Task | Time Horizon |
|---|---|---|---|---|
| **Tier 1 (Alert Triage)** | 告警分诊 | Speed | Review SIEM alerts, validate true/false positive (误报判定), enrich with basic context, escalate or close | Minutes |
| **Tier 2 (Investigation)** | 事件调查 | Depth | Correlate events across sources (关联分析), reconstruct attack timeline (还原时间线), contain confirmed incidents | Hours |
| **Tier 3 (Threat Hunting / Expert)** | 威胁狩猎 | Proactivity | Hunt for threats *not yet alerting* (主动狩猎), tune detection rules, deep malware/forensics analysis | Days |
| **Supporting roles** | 检测工程/情报 | Enablement | Detection engineering (检测工程), intel integration, purple-team exercises with red team | Continuous |

A common 甲方 failure mode is a SOC where everyone is Tier 1 by necessity: alerts pile up, nobody hunts, and the detection rules are never tuned. 把所有人钉死在分诊岗位上，等于永远在灭火、永远不修消防系统。

## Alert Triage: The Core Workflow

**Triage** (告警分诊) is the disciplined process of deciding: *is this real, and does it matter?* NIST SP 800-61 frames it as the front door of incident response (事件响应): analysis precedes containment (遏制), and a wrong triage call either wastes response capacity on noise or lets a real intrusion (入侵) burn quietly.

```
                 ALERT TRIAGE WORKFLOW
 ┌────────┐   ┌──────────────┐   ┌───────────────┐
 │ SIEM / │──▶│ 1. Validate  │──▶│ 2. Enrich     │
 │ SIP    │   │  real?       │   │  who/what/where│
 └────────┘   │  dedupe      │   │  IP rep, user, │
              └──────┬───────┘   │  asset crit.   │
                     │           └───────┬───────┘
              false positive              │
                     │                    ▼
                     ▼            ┌───────────────┐
              close + feedback    │ 3. Assess     │
              to detection rule   │  severity +   │
                                  │  scope        │
                                  └───────┬───────┘
                                          │
                        minor / isolated  │  confirmed / spreading
                                 ┌────────┴────────┐
                                 ▼                 ▼
                           close w/ notes   escalate to Tier 2
                                            → IR lifecycle
```

Three habits separate good triage from bad:

1. **Context before judgment** (先看上下文再下结论). An EDR alert on a PowerShell (PowerShell 脚本引擎) invocation is meaningless without knowing: which user, which host, what parent process (父进程)， scheduled task or human? A one-line enrichment (情报富化) — asset criticality, user role, recent change tickets — prevents most wrong calls.
2. **Severity is context, not just CVSS** (严重程度看场景). A medium-severity alert on a domain controller (域控制器) outranks a high-severity one on an isolated kiosk. Map alerts against **asset criticality** (资产重要性) and **MITRE ATT&CK** (ATT&CK 战术技术矩阵) tactics — an alert showing *Persistence* (持久化) or *Lateral Movement* (横向移动) is inherently more alarming than a one-shot probe (单次探测).
3. **Close the loop** (闭环反馈). Every false positive should feed back into detection engineering. Triage without feedback means the same noise forever. 每一次误报都是免费的检测规则调优机会，浪费掉就太可惜了。

## Metrics: MTTD and MTTR — and Their Traps

SOC performance is usually measured with two numbers:

- **MTTD** (Mean Time to Detect，平均检测时间): how long between compromise (失陷) and detection. Industry benchmarks have improved from months to days, but **dwell time** (攻击驻留时间) for well-run intrusions is still measured in weeks — attackers who matter are patient.
- **MTTR** (Mean Time to Respond/Remediate，平均响应/处置时间): how long from detection to full containment and recovery. Faster is better, but beware sub-optimization (局部最优)： closing alerts fast without closing them *right* just moves cost to the next incident.

The trap: both metrics can be gamed (被刷数字). Auto-closing low-value alerts improves MTTR on paper while hiding real breaches. Mature SOCs therefore track a third thing — **alert quality** (告警质量)： what percentage of escalated alerts turned out to be true positives (真报率). If it is trending down, your detection rules are drifting (检测规则漂移)， not your analysts.

## How the Pieces Connect

| Capability | Feeds the SOC | SOC Feeds Back |
|---|---|---|
| **SIEM / SIP** (态势感知平台) | Normalized logs (归一化日志)， correlation alerts | Tuning rules, new use cases, whitelist decisions |
| **EDR** | Process lineage (进程链)， isolation actions | Isolation requests, custom IOC pushes |
| **Threat Intelligence** | IOC matches, TTP context, campaign tracking (活动追踪) | Sighted TTPs, local IOC sets, IR-derived intel |
| **Vulnerability Mgmt** | Exploit-in-the-wild flags (在野利用标记) | "This CVE is being probed in our logs" prioritization |
| **Pentest / Red Team** | Planned test windows | Detection gaps found, purple-team findings |

Note the arrows point both ways. A SOC that only *consumes* alerts is a help desk; a SOC that *feeds back* — tuned rules, hunted TTPs, IR intel — becomes the immune system (免疫系统) of the organization. 只收告警不反哺规则，SOC 就只是个高级网管值班室。

## 甲方视角思考

- 甲方 SOC 的第一件事不是招人，是把"告警分诊 SOP"写出来：验证 → 富化 → 定级 → 升级/闭环，四步固化，新人照做不变形。
- SIP/NGFW 产生的每条告警都标注资产重要性，分诊时"域控上的中危 > 隔离区里的高危"这条规则能省一半无效升级。
- 每月统计真报率和误报 Top 10，交给检测工程调规则；MTTD/MTTR 只向管理层汇报，不作为分析师考核指标——否则会催生"快速关单"文化。
- 用 MITRE ATT&CK 覆盖矩阵盘点检测能力：NIST SP 800-61 的响应流程 + ATT&CK 的缺口清单，就是明年的检测建设路线图。

---

**Key Terms**

| English | 中文 | 备注 |
|---|---|---|
| SOC (Security Operations Center) | 安全运营中心 | 人+流程+平台，不只是监控室 |
| Alert triage | 告警分诊 | 判断"真假"与"轻重"的第一道关 |
| Tier 1 / 2 / 3 | 三级分析员模型 | 分诊 / 调查 / 狩猎 |
| Escalation path | 升级路径 | 何时上交也是核心技能 |
| False positive (FP) | 误报 | 噪声的来源，需反馈调优 |
| True positive (TP) | 真报 | 升级后确认属实 |
| True positive rate | 真报率 | 衡量检测规则质量的指标 |
| Enrichment | 情报富化 | 给告警补充资产/身份/情报上下文 |
| Correlation | 关联分析 | 跨源事件拼出完整攻击链 |
| Asset criticality | 资产重要性 | 定级要看资产，不只看告警等级 |
| Parent process | 父进程 | 判断进程行为是否异常的关键线索 |
| Threat hunting | 威胁狩猎 | 主动找还没触发告警的威胁 |
| Detection engineering | 检测工程 | 把情报和误报教训变成规则 |
| Purple team | 紫队 | 攻防协同验证检测有效性 |
| MTTD | 平均检测时间 | 失陷到发现的时长 |
| MTTR | 平均响应时间 | 发现到处置完成的时长 |
| Dwell time | 攻击驻留时间 | 高水平入侵者的存活期以周计 |
| Sub-optimization | 局部最优陷阱 | 刷响应指标反而掩盖真实风险 |
| Detection drift | 检测规则漂移 | 规则老化导致真报率下滑 |
| MITRE ATT&CK | 攻击战术技术知识库 | 用战术矩阵映射检测覆盖 |
| Persistence | 持久化 | ATT&CK 战术之一，出现即高危 |
| Lateral movement | 横向移动 | 攻击扩散的标志性行为 |
| Containment | 遏制 | IR 中止血优先于根治 |
| SIEM / SIP | 安全信息事件管理/态势感知 | 日志汇聚与关联的核心平台 |
| Process lineage | 进程链 | EDR 遥测的核心字段 |

**Tomorrow's Preview (Day 46)**: 技术阶段结束，明天进入 **★★★★☆ 深度阶段**。第一课：**Anatomy of a Modern APT Intrusion**（现代 APT 入侵剖析）——以公开披露的真实攻击事件为样本，串起 Initial Access → Persistence → Lateral Movement → Exfiltration 的完整链条，看攻击者如何把前面学过的每个漏洞利用步骤编织成一场数月的渗透。
