---
title: "Day 50 — Purple Teaming: Continuously Validating Your Detections"
date: 2026-08-12
tags:
  - daily
  - security
  - english
description: "Yesterday you wrote Sigma rules and validated them with Atomic Red Team tests — one technique at a time, one rule at a time. Today we zoom out: purple"
---

**日期**: 2026-10-05
**难度**: ★★★★☆ 深度
**来源**: MITRE ATT&CK Evaluations (https://attackevals.mitre-engenuity.org) · Atomic Red Team (https://github.com/redcanaryco/atomic-red-team) · SCYTHE 紫队实践指南 · CISA Adversary Emulation Plans
**链接**: https://attackevals.mitre-engenuity.org · https://github.com/redcanaryco/atomic-red-team

> Yesterday you wrote Sigma rules and validated them with Atomic Red Team tests — one technique at a time, one rule at a time. Today we zoom out: **purple teaming (紫队协作)** is the operating model that turns one-off validation into a continuous loop between attackers and defenders. The purple team is not a third team — it is red and blue working **in the same room, in real time**.

*昨天你用 Atomic Red Team 逐条验证 Sigma 规则；今天把一次性验证升级为持续循环。紫队不是第三支队伍，而是红队与蓝队"同处一室、实时协作"的工作模式。*

---

## 1. Red, Blue, Purple — and Why "Purple" Is a Process, Not a Team

| Model | Goal | Output | Weakness |
|---|---|---|---|
| **Red team** (红队) | Emulate a real adversary, achieve objectives covertly | Attack narrative, findings | Blue learns weeks later, from a report |
| **Penetration test** (渗透测试) | Find and prove vulnerabilities within scope | Findings list | Point-in-time (一次性), breadth over depth |
| **Purple team** (紫队协作) | Maximize **detection improvement per attack technique** | Tuned rules, updated playbooks, coverage deltas | Requires tooling + a feedback cadence |

The core insight: a red team engagement where the blue team never learns *how* each step was caught (or missed) is entertainment, not capability building. Purple teaming inverts the traditional model — **the detection outcome is the deliverable**, not the intrusion report.

*红队突袭如果蓝队事后才知道每一步是否被检出，那只是表演。紫队模式把"每项技术的检出/漏检改进"当作交付物。*

## 2. The Purple Loop

```
   ┌────────────────┐     ┌──────────────────┐     ┌────────────────┐
   │ 1. Select      │ →   │ 2. Emulate       │ →   │ 3. Observe     │
   │ technique      │     │ technique safely │     │ Did it alert?  │
   │ (ATT&CK T-code)│     │ (ART/Caldera)    │     │  ├─ yes ─┐     │
   └────────────────┘     └──────────────────┘     │  └─ no ◄─┼──┐  │
                                                   └──────────┼──┘  │
        ┌────────────────┐    ┌──────────────────┐           ▼     │
        │ 5. Re-run &    │ ←  │ 4. Tune: rule,   │   ┌──────────┐  │
        │   confirm      │    │ log source, or   │   │ Fix gap  │──┘
        └────────────────┘    │ playbook         │   └──────────┘
               │
               ▼
   ┌────────────────────┐
   │ 6. Record: matrix  │
   │ + metric + next T  │
   └────────────────────┘
```

Six steps, and the loop closes only when step 6 is written down. Key disciplines:

- **Safety first (安全隔离)**: emulation runs on lab or closely-supervised production hosts. An ART atomic for T1003.001 (LSASS dump) can trip EDR into *responding* — agree on blast radius before running.
- **One technique at a time**: purple sessions are surgical. "Today: T1059.001 PowerShell encoding" — not "today: APT29."
- **Blue drives the tuning**: red shows the traffic; blue decides whether the fix is a rule, a log source (missing Sysmon Event ID 7?), or a documented play for the analyst.

*紫队六步循环：选技术 → 安全模拟 → 观察是否告警 → 调优（规则/日志源/处置手册）→ 复测确认 → 记录入覆盖矩阵。一次只做一个技术点，复测通过才算闭环。*

## 3. Automation: BAS and Continuous Validation

Manual purple sessions are high-value but don't scale. **BAS (Breach and Attack Simulation, 入侵与攻击模拟)** platforms and open-source orchestrators — MITRE **Caldera**, Security Onion testing harnesses — run technique checks on a schedule:

| Cadence | Mechanism | Best for |
|---|---|---|
| Weekly (manual) | 1–2 technique purple sessions with red/blue on a call | New rules from Day 49 hunt output |
| Monthly (semi-auto) | Caldera/ART batch run against a lab agent, report diff | Regression: did a rule update break coverage? |
| Continuous (BAS) | Scheduled emulation of 20–50 core techniques; alert on *silent misses* | Catching log-source drift and sensor outages |

The killer feature of continuous validation is the **silent-miss alarm (静默漏报告警)**: when a previously-detected technique stops producing alerts — because an agent was uninstalled, a log forwarder broke, or a rule was retired — you find out in hours, not in the next real incident.

*BAS 把紫队循环自动化：手动每周做 1-2 个技术点，月度批量回归，持续模式专门盯"以前能检出现在检不出"的静默漏报——传感器掉线、转发器故障几小时内就能发现。*

## 4. What You Measure

Purple teaming without metrics degenerates into red-team theater. Track:

- **Detection rate per technique** (技术检出率): alerts fired / techniques emulated, per tactic. "Credential Access: 3 of 7" is an actionable number.
- **Time-to-tune (调优耗时)**: from gap observed → rule/filter updated → re-test passed. Target: same session or same week.
- **Coverage delta (覆盖率增量)**: ATT&CK matrix cells moved from *no detection* → *detection*, per month. This is the number that justifies the SOC budget.
- **False-positive regression (误报回归)**: each tuned rule re-validated against a week of baseline data, so fixing gaps doesn't re-open the noise you closed on Day 49.

*度量四件套：技术检出率、调优耗时、覆盖率月度增量（预算依据）、误报回归——补漏的同时别把 Day 49 关掉的噪声又放回来。*

## 5. Common Pitfalls (紫队常见坑)

| Pitfall | Consequence | Fix |
|---|---|---|
| Running attacks on production unannounced | EDR isolation of a real server; incident declared | Emulation registry + change ticket + SOC heads-up |
| Red tunes its own rules | Blue learns nothing; "purple" is red doing blue's job | Blue writes the rule, red only re-runs the test |
| Testing only what you already detect | Coverage matrix looks great, real gaps untouched | Pick techniques from intel (Day 47 actors), not comfort |
| No artifact from the session | Same gap re-discovered next quarter | Mandatory output: updated rule, playbook line, or matrix note |
| Emulating with live malware | Uncontrolled risk, legal exposure | Use ART/Caldera simulated techniques, never real payloads |

*五个坑：生产环境裸奔、红队代写规则（蓝队学不到东西）、只测已能检出的"舒适区"、会无产出、用真实恶意样本。*

---

## 甲方视角思考

- 你的 SIP/EDR 都在建设期，正是做紫队的最佳时机：每月挑 2 个 ATT&CK 技术点，照六步循环走一遍，覆盖矩阵按月长出来，比"买多少规则包"更实在。
- 把 Day 49 的 ART 验证升级为月度批量回归：Caldera 或脚本化 ART 对 lab 端点跑 20-30 个核心技术，检出缺口自动进调优 backlog。
- 连续验证最值钱的是"以前检出现在检不出"的告警——你的流量探针、EDR agent 掉线这类故障，靠它能在几小时内发现。
- 蓝队自己写规则、红队只负责复测：这个纪律保证每次紫队演练的能力沉淀在你们团队，而不是外部服务商手里。

---

**Key Terms**

| English | 中文 | 备注 |
|---|---|---|
| Purple teaming | 紫队协作 | 红蓝同场实时协作的验证工作模式 |
| Red team | 红队 | 模拟真实对手、隐蔽达成目标的攻击方 |
| Blue team | 蓝队 | 负责检测、响应与加固的防守方 |
| Adversary emulation | 对手模拟 | 按 APT TTP 剧本复现攻击链 |
| Breach and Attack Simulation (BAS) | 入侵与攻击模拟 | 持续自动化攻击验证的平台能力 |
| MITRE Caldera | — | 开源对手模拟编排框架 |
| ATT&CK technique coverage | ATT&CK 技术覆盖 | 按技术项统计的检测能力地图 |
| Silent miss | 静默漏报 | 曾能检出、现已失效的检测缺口 |
| Detection rate | 检出率 | 模拟技术中触发告警的比例 |
| Time-to-tune | 调优耗时 | 从发现缺口到复测通过的时长 |
| Coverage delta | 覆盖率增量 | 月度新增的"无检测→有检测"单元格数 |
| False-positive regression | 误报回归 | 调优后需复核基线数据防噪声回潮 |
| Safety isolation | 安全隔离 | 模拟活动在受控环境/受控主机执行 |
| Blast radius | 爆炸半径 | 一次模拟动作可能影响的范围 |
| Playbook | 处置手册 | 分析师面对某类告警的标准动作序列 |
| Emulation registry | 模拟登记表 | 演练时间、范围、负责人的事前登记 |
| Purple session | 紫队演练会 | 一次聚焦单技术的攻防协作会议 |
| Red-team theater | 红队表演 | 攻防各自为战、无可度量产出的形式主义 |
| Log-source drift | 日志源漂移 | 采集配置变更导致的字段/事件缺失 |
| Detection gap | 检测缺口 | ATT&CK 矩阵上无对应规则的单元格 |

**Tomorrow's Preview (Day 51)**: 深度阶段第六课：**Ransomware Incident Response: From First Alert to Recovery**（勒索软件应急响应：从第一声告警到恢复业务）——把 Day 7 的 IR 基础、Day 38 的取证与 Day 50 的检测验证串成一条完整的勒索事件处置链：遏制决策、取证保全、谈判与恢复的取舍。
