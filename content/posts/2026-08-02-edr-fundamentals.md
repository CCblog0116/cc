---
title: "Day 40 — Edr Fundamentals"
date: 2026-08-02
tags:
  - daily
  - security
  - english
description: "An EDR 终端检测与响应 platform continuously collects telemetry 遥测数据 from endpoints — processes, file changes, network connections, registry edits, and user l"
---

**Date:** Friday, September 25, 2026
**Difficulty:** ★★★☆☆ Technical
**Source:** MITRE ATT&CK — *Defending Against Malicious Cyber Activity* + Microsoft Security — *What is EDR?* + CISA — *EDR Capacity Enhancement Guide*
**Link:** https://attack.mitre.org/ / https://www.microsoft.com/en-us/security/business/security-101/what-is-edr-endpoint-detection-and-response / https://www.cisa.gov/resources-tools/resources/endpoint-detection-and-response-edr-capacity-enhancement-guide

---

## 1. What EDR Actually Is

An **EDR** (终端检测与响应) platform continuously collects **telemetry** (遥测数据) from endpoints — processes, file changes, network connections, registry edits, and user logons — stores it centrally, and applies analytics to find malicious behavior that antivirus signatures miss.

The key word is *response*: a classical **antivirus (AV, 杀毒软件)** can only quarantine a file, while an EDR can **isolate a host** (主机隔离), **kill a process** (终止进程), and **remediate artifacts** (清除痕迹) remotely from a single console. EDR 的本质是把"事后查日志"变成"实时看行为、一键做处置"。

---

## 2. Telemetry: What the Agent Collects

The EDR **agent** (代理程序) runs on every endpoint and streams events to the cloud or on-prem backend:

| Telemetry Source | What It Reveals | ATT&CK Relevance |
|------------------|-----------------|------------------|
| **Process creation** (进程创建) | Parent-child chains, command lines | T1059 Command and Scripting Interpreter |
| **File operations** (文件操作) | Dropped payloads, ransomware mass-encryption | T1486 Data Encrypted for Impact |
| **Registry changes** (注册表变更) | Persistence via Run keys, service installs | T1547 Boot or Logon Autostart |
| **Network connections** (网络连接) | C2 beaconing, lateral movement | T1071 Application Layer Protocol |
| **Logon events** (登录事件) | Credential theft, pass-the-hash, RDP abuse | T1550 Use of Alternate Authentication Material |

Individually, each event is benign noise. Detection comes from **correlating** (关联分析) chains: `office.exe → cmd.exe → powers.exe -enc ... → outbound HTTPS` is a textbook **phishing payload** (钓鱼载荷) execution chain.

---

## 3. Signature vs Behavioral Detection

| Dimension | Signature-based (基于签名) | Behavioral / Analytics-based (基于行为) |
|-----------|---------------------------|----------------------------------------|
| Logic | Hash / static pattern match | Rules, ML models, and attack-chain correlation |
| Known malware | Fast and accurate | Also catches it, but heavier |
| Novel threats | Blind until signature update | Can catch **zero-day** (零日) and **fileless** (无文件攻击) attacks |
| False positives | Low | Higher — requires tuning |

Behavioral rules are often mapped directly to **MITRE ATT&CK** (攻击战术技术知识库) techniques. For example, a rule for "process access to LSASS memory" maps to **T1003 Credential Dumping** (凭证转储). 行为检测的优势是不依赖文件哈希——攻击者换一个壳也逃不掉。

---

## 4. The Response Toolkit

When detection fires, EDR gives the SOC several response actions:

1. **Host isolation** (主机隔离): cut the machine from the network but keep the management channel alive — the default first move on a confirmed compromise.
2. **Process termination** (进程终止): kill the malicious process tree.
3. **Quarantine and delete** (隔离与删除): remove the malicious file and any dropped artifacts.
4. **Live response / remote shell** (远程实时响应): an interactive shell on the endpoint for triage — check persistence, collect evidence, pull memory.
5. **Blocklist push** (黑名单下发): push a hash or certificate blocklist across the whole fleet in minutes.

⚠️ Isolation is powerful but disruptive — a misfire on a **domain controller** (域控制器) or a file server can take down business services. 高危处置动作必须分级审批，先隔离普通终端，服务器类资产要人工确认。

---

## 5. Tuning Without Drowning the SOC

The classic failure mode: EDR deployed in **block mode** (阻断模式) on day one, hundreds of alerts per day, analysts ignore everything. A sane rollout:

1. **Detect-only first** (先只告警不阻断): run in detection mode for 2–4 weeks to baseline your environment.
2. **Triage the noise** (排查误报): custom dev tools, admin scripts, and legacy software generate most false positives.
3. **Add exclusions carefully** (谨慎加白名单): exclusions weaken detection — scope them to specific paths, hashes, or processes, and review quarterly.
4. **Escalate to block mode** (逐步启用阻断): only for high-confidence, high-impact detections (e.g., ransomware behaviors).
5. **Feed the rules** (持续优化): real incidents should convert into new custom detection rules.

---

## 6. 甲方视角思考

- EDR 覆盖率优先于功能：先盘点终端资产，确保 Agent 装满（服务器、办公网、DMZ 一个不漏），未装 EDR 的机器等于裸奔。
- 隔离动作要分级授权：普通终端可自动隔离，服务器和关键业务主机必须人工确认，防止"防护动作打瘫业务"。
- 告警要对接 SIP/SIEM：EDR 告警不能只躺在自己控制台，要汇入态势感知平台做关联。
- 排除项每季度复审：加白名单一时爽，攻击者最爱利用合法路径，排除项就是新的攻击面。

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| EDR (Endpoint Detection and Response) | 终端检测与响应 | Continuous endpoint monitoring with detection and response capability |
| Telemetry | 遥测数据 | Raw events collected from endpoints |
| Agent | 代理程序 | Software component installed on each endpoint |
| Antivirus (AV) | 杀毒软件 | Signature-based, file-oriented protection |
| Host isolation | 主机隔离 | Cutting an endpoint from the network while retaining control |
| Behavioral detection | 行为检测 | Detecting attacks by action patterns, not file signatures |
| Signature-based detection | 基于签名的检测 | Matching known hashes or byte patterns |
| Zero-day | 零日漏洞 | Vulnerability exploited before a patch or signature exists |
| Fileless attack | 无文件攻击 | Attack running purely in memory / legitimate interpreters |
| MITRE ATT&CK | 攻击战术技术知识库 | Matrix of adversary tactics and techniques |
| Credential dumping | 凭证转储 | Extracting credentials from memory (e.g., LSASS) |
| Persistence | 持久化 | Maintaining access across reboots |
| Lateral movement | 横向移动 | Moving from one compromised host to others |
| Detect-only mode | 仅告警模式 | Detection without automatic blocking, used for baselining |
| Exclusion / allowlisting | 排除项/白名单 | Scoped rules that suppress EDR detection for trusted items |
| Live response | 远程实时响应 | Interactive remote shell for endpoint triage |

---

## Tomorrow's Preview

**Day 41 — Vulnerability Management and Scanning Fundamentals (漏洞管理与扫描基础):** how enterprise vulnerability management programs work — asset inventory, scanner types, CVSS scoring, patch prioritization, and SLA design — directly relevant to batch asset scanning and CVE response workflows.
