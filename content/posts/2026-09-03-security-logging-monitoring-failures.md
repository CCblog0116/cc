---
title: "Day 21 — Security Logging and Monitoring Failures: The Blind Spot That Costs Months"
date: 2026-09-03
tags:
  - daily
  - security
  - english
description: "In 2013, Target Corporation was breached through a third-party HVAC vendor. The attackers moved laterally across the network, exfiltrated 40 million c"
---

**Date:** 2026-09-03 | **Difficulty:** ★★☆☆☆ Conceptual | **Source:** OWASP Top 10:2021 A09 | **Link:** [OWASP A09:2021](https://owasp.org/Top10/A09_2021-Security_Logging_and_Monitoring_Failures/)

---

## Why This Matters

In 2013, Target Corporation was breached through a third-party HVAC vendor. The attackers moved laterally across the network, exfiltrated **40 million credit card records**, and walked out undetected. The security team had the alerts. The **SIEM** （安全信息和事件管理系统） had flagged the anomalous activity. But nobody was watching the dashboard during the critical window, and by the time someone reviewed the logs, the damage was already done.

OWASP ranks **security logging and monitoring failures** as the **#9 risk** in its 2021 Top 10. Unlike other categories on this list, this one is not about preventing an attack from succeeding — it is about **how quickly you realize you have been attacked**.

The industry benchmark is stark: according to **IBM's Cost of a Data Breach Report**, organizations without adequate **security monitoring** took an average of **277 days** to identify and contain a breach in 2023. Those with strong detection capabilities contained breaches **108 days faster** and saved an average of **$1.76 million** per incident.

> 日志不是"事后看证据"，而是"实时发现正在发生的事"。没有日志就没有检测，没有检测就没有响应。

---

## What Counts as a Logging Failure?

OWASP A09 covers situations where an application or infrastructure does not produce sufficient evidence of security-relevant events, or does not act on that evidence in time. You have a logging and monitoring failure if any of the following is true:

- Your application does not log **authentication events** （认证事件） such as logins, logouts, and failed login attempts.
- Logs capture only successful actions, not **failures and anomalies** （异常行为）.
- **Audit logs** （审计日志） are stored on the same server as the application, meaning an attacker who compromises the host can wipe their own tracks.
- Log entries lack the **timestamp, source IP, user identity, and event type** needed for investigation.
- Alerts are generated but nobody reviews them, or they are drowned in **alert fatigue** （告警疲劳） — thousands of low-value alerts per day with no triage.
- There is no centralized **log aggregation** （日志聚合） across servers, databases, and network devices.
- **Log retention** （日志保留） is too short: by the time a breach is discovered months later, the relevant logs have rotated out.
- There is no **incident response plan** （应急响应计划） defining who does what when an alert fires.

> 一句话判断标准：如果今早有人攻破了你的系统，你能在多久之内发现？如果答案是"不确定"，就是 A09 问题。

---

## The Three Layers: Logging, Monitoring, and Response

Understanding A09 requires grasping how these three layers connect. Each builds on the previous one:

```
Layer 1: LOGGING    → "Did we record what happened?"
Layer 2: MONITORING → "Did we notice it in time?"
Layer 3: RESPONSE   → "Did we act on it?"
```

### Layer 1 — Logging: The Foundation

**Logging** is the act of recording security-relevant events. Good logging is not "log everything" — it is "log the right things, with the right detail, in the right place."

Key events that must be logged:

| Event Category | What to Capture | Why |
|---------------|-----------------|-----|
| **Authentication** | Login success/failure, MFA challenge, password reset, account lockout | Detects brute force and credential stuffing |
| **Authorization** | Access denied events, privilege changes, role escalation | Detects privilege escalation |
| **Input validation failures** | SQL injection attempts, XSS payloads, unexpected parameter values | Reveals active exploitation attempts |
| **Data access** | Access to sensitive records, bulk export, unusual query volume | Detects data exfiltration |
| **Configuration changes** | Security setting changes, new admin accounts, firewall rule changes | Detects post-compromise persistence |
| **System errors** | Unhandled exceptions, crash dumps, unexpected process termination | May indicate exploitation of a vulnerability |

Each log entry must include at minimum: **timestamp** （时间戳，UTC with timezone), **severity level** （严重级别）, **source IP** （源 IP 地址）, **user identity** （用户标识）, **event type** （事件类型）, and a **correlation ID** （关联标识） that ties related events together.

> 日志质量比数量重要。一千条"登录成功"不如一条"同一个账号在 3 分钟内从两个不同国家的 IP 登录"。

### Layer 2 — Monitoring: Detection in Real Time

**Monitoring** is the continuous analysis of logs and system state to identify suspicious activity. Raw logs are useless if nobody reads them. This is where **SIEM** （Security Information and Event Management） platforms come in.

A SIEM collects logs from servers, databases, firewalls, EDR agents, and cloud services into a central repository. It applies **detection rules** （检测规则） and **correlation logic** （关联逻辑） to identify patterns that indicate an attack.

For example, a single failed login is noise. But "the same account fails login 50 times in 5 minutes, then succeeds, then accesses a database it has never touched before" is a **correlated pattern** that signals a likely **brute force followed by lateral movement** （暴力破解后的横向移动）.

Key monitoring concepts:

- **Detection engineering** （检测工程） — the discipline of designing, testing, and maintaining detection rules so they catch real attacks without drowning analysts in false positives.
- **Alert triage** （告警分诊） — the process of reviewing each alert, deciding if it is a true positive, and escalating if needed. This is the core daily job of a **SOC analyst** （安全运营中心分析师）.
- **Threat hunting** （威胁狩猎） — proactively searching for indicators of compromise that your automated rules might have missed.

> 监控的核心矛盾是信噪比：规则太松则告警淹没分析师，太严则漏掉真正的攻击。

### Layer 3 — Response: Acting on What You Detect

**Incident response** （应急响应） is what happens after a real threat is identified. Without a defined **incident response plan**, even perfect detection is wasted — the alert fires, but nobody knows who to call, what to contain, or how to preserve evidence.

A standard incident response framework (based on **NIST SP 800-61** and **SANS PICERL**) includes:

| Phase | Name | Key Action |
|-------|------|------------|
| 1 | **Preparation** （准备） | Build playbooks, train teams, pre-deploy forensic tooling |
| 2 | **Identification** （识别） | Confirm the alert is a real incident, determine scope |
| 3 | **Containment** （遏制） | Isolate affected systems to stop the spread |
| 4 | **Eradication** （根除） | Remove malware, close the vulnerability, revoke stolen credentials |
| 5 | **Recovery** （恢复） | Restore systems from clean backups, verify they are clean |
| 6 | **Lessons Learned** （经验总结） | Post-mortem, update detection rules and playbooks |

> 应急响应的核心不是"修好"，而是"遏制—根除—恢复"形成闭环，最后通过复盘把每一次事件转化为防御能力的增量。

---

## Common Failure Patterns in the Real World

### 1. The "Alert Graveyard"

Many organizations deploy a SIEM, ingest millions of logs, and configure hundreds of rules. Then the **SOC team** is understaffed — one or two analysts facing 5,000 alerts per day. They cannot triage them all, so they start ignoring everything below "Critical." Attackers who operate slowly and quietly — below the severity threshold — go unnoticed for months.

This is **alert fatigue**: when everything is an alert, nothing is an alert.

> 告警疲劳的本质是规则与人力不匹配。再好的 SIEM，后面没有足够的分析师，就只是一个昂贵的告警垃圾桶。

### 2. Log Wiping by the Attacker

If application logs are stored locally on the compromised server, the first thing a skilled attacker does after gaining access is **clear the logs** — delete the file, truncate the syslog, or modify audit records. When the incident response team arrives, there is nothing to investigate.

The defense is **forward logging** （日志外发）: send logs to a separate, hardened log server or cloud service that the application server cannot write to or delete.

> 本地存储的日志对攻击者来说只是一个需要清理的文件。日志必须外发到攻击者无法触及的位置才有取证价值。

### 3. Insufficient Retention

Some organizations keep logs for only 7 or 14 days due to storage costs. But **dwell time** （驻留时间） — the time an attacker remains undetected in a network — averaged **24 days** in 2023 according to **Mandiant M-Trends**. If your retention is shorter than the dwell time, by the time you discover the breach, the initial access logs are gone.

> 日志保留期的下限应该是"平均驻留时间 + 调查时间"，而不是"磁盘还能装多少"。

### 4. No Baseline = No Anomaly Detection

If you have never profiled what "normal" looks like in your environment, you cannot detect anomalies. **Baselining** （基线建立） involves recording typical patterns of user behavior, network traffic, data access, and system changes over a representative period. Without a baseline, every rule is a static threshold that may or may not match your actual environment.

> 没有基线就没有异常检测。你不知道什么是"正常"，就无法判断什么是"不正常"。

---

## Defense: The A09 Checklist

| Control | What to Do | Why It Helps |
|---------|-----------|--------------|
| **Centralized logging** | Forward all security-relevant logs to a SIEM or centralized log platform | Prevents on-host log wiping; enables cross-system correlation |
| **Log immutability** | Store logs in write-once or append-only storage that the source server cannot modify | Ensures forensic integrity even after compromise |
| **Adequate retention** | Retain logs for at least 90 days hot + 1 year cold (adjust to compliance requirements) | Ensures initial-access evidence survives long dwell times |
| **Structured logging** | Use JSON or CEF format with consistent fields (timestamp, severity, user, IP, event) | Enables automated parsing, correlation, and searching |
| **Detection rules** | Build rules for known attack patterns: brute force, credential stuffing, lateral movement, data exfiltration | Turns raw logs into actionable alerts |
| **Alert triage process** | Define severity tiers, escalation paths, and on-call rotation | Ensures no critical alert goes unreviewed |
| **Incident response plan** | Document playbooks for common scenarios; conduct tabletop exercises quarterly | Reduces response time from hours to minutes |
| **Log quality review** | Periodically audit whether logs contain the required fields and capture the right events | Catches silent gaps before an incident reveals them |
| **Compliance alignment** | Align logging with regulatory requirements (PCI-DSS, GDPR, SOX, 等保三级) | Avoids both security gaps and compliance penalties |

> 对甲方而言，态势感知平台和 SIEM 不是买完就结束，而是持续运营。工具只是起点，规则运营和人员排班才是决定检测能力的核心。

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| Security Logging and Monitoring Failures | 安全日志与监控失效 | OWASP Top 10 A09:2021 |
| Logging | 日志记录 | 记录安全相关事件的动作 |
| Monitoring | 监控 | 对日志和系统状态的持续分析 |
| SIEM (Security Information and Event Management) | 安全信息与事件管理 | 集中收集、关联、分析日志的平台 |
| SOC (Security Operations Center) | 安全运营中心 | 负责持续监控、告警分诊和事件响应的团队 |
| Detection Engineering | 检测工程 | 设计、测试和维护检测规则的学科 |
| Alert Triage | 告警分诊 | 对告警进行初步研判和优先级排序的过程 |
| Alert Fatigue | 告警疲劳 | 告警过多导致分析师忽视或延误处理 |
| Threat Hunting | 威胁狩猎 | 主动搜索自动化规则未发现的入侵痕迹 |
| Incident Response (IR) | 应急响应 | 对安全事件进行识别、遏制、根除和恢复的流程 |
| Dwell Time | 驻留时间 | 攻击者在网络中未被发现的持续时间 |
| Baseline / Baselining | 基线 / 基线建立 | 记录正常行为模式以供异常检测参照 |
| Audit Log | 审计日志 | 用于合规和取证的安全事件记录 |
| Log Retention | 日志保留 | 日志保存的时长策略 |
| Forward Logging | 日志外发 | 将日志实时发送到独立存储以防止被篡改 |
| Correlation ID | 关联标识 | 将多个相关日志事件串联在一起的唯一标识 |
| Lateral Movement | 横向移动 | 攻击者在网络内部从一个系统扩散到另一个系统 |
| Data Exfiltration | 数据外泄 | 攻击者将数据从受害网络中传出 |

---

## 甲方视角思考

1. **日志外发是底线** — 所有关键系统的安全日志必须实时转发到独立平台（SIEM/态势感知），不依赖本地文件留存，防止被攻陷后清理痕迹。
2. **保留期不能小于驻留时间** — 热数据至少 90 天、冷数据至少 1 年，等保三级和行业监管还有更高要求，先满足合规下限再优化。
3. **规则运营比平台选型更重要** — 态势感知/SIEM 的检测能力取决于规则质量和更新频率，需要专人持续维护，而不是部署完就当摆设。
4. **建立应急闭环** — 不光要有应急预案，还要定期做桌面演练；每次真实事件后必须复盘并更新检测规则，把教训固化为能力。

---

## Tomorrow — Day 22 Preview

**Server-Side Request Forgery (SSRF)** — as we transition from the conceptual phase (★★☆☆☆) to the technical phase (★★★☆☆), we will dive into SSRF: how an attacker tricks your server into making requests on their behalf, why cloud environments make SSRF far more dangerous, and what defense controls actually work. The difficulty curve begins to steepen from here.
