---
title: "Day 37 — Threat Intelligence Fundamentals"
date: 2026-07-30
tags:
  - daily
  - security
  - english
description: "1. What Is Threat Intelligence?"
---

**Date:** Tuesday, September 22, 2026  
**Difficulty:** ★★★☆☆ Technical  
**Source:** SANS Institute — *What is Cyber Threat Intelligence?*  
**Link:** https://www.sans.org/blog/what-is-cyber-threat-intelligence/

---

## 1. What Is Threat Intelligence?

**Threat intelligence** (威胁情报) is evidence-based knowledge about an existing or emerging threat to assets, including context, mechanisms, indicators, implications, and actionable advice. The goal is not to collect more data, but to turn data into **actionable insights** (可执行洞察) that help defenders prioritize resources and reduce risk.

A common misunderstanding treats threat intelligence as a long list of **IOC** (Indicator of Compromise, 失陷指标) feeds. IOCs are useful, but they are only the tip of the intelligence iceberg. True intelligence explains *who* is attacking, *why*, *how*, and *what to do about it*.

 threat intelligence 不是简单的 IOC 列表，而是把数据转化为可执行决策依据。

---

## 2. The Four Types of Threat Intelligence

Threat intelligence is usually grouped into four layers. Each layer serves a different audience and a different decision horizon.

| Type | Audience | Time Horizon | Focus |
|------|----------|--------------|-------|
| **Strategic** (战略层) | CISO, board, executives | Months to years | Trends, risk posture, budget planning |
| **Tactical** (战术层) | SOC managers, IR leads | Weeks to months | TTPs, threat actor profiles |
| **Operational** (作战层) | Incident responders | Days to weeks | Specific campaigns, attribution |
| **Technical** (技术层) | Analysts, engineers | Minutes to days | IOCs, signatures, detection rules |

**Strategic intelligence** helps leaders answer questions such as “Should we invest in cloud security or supply-chain security this year?” **Technical intelligence** helps analysts write a **YARA** (Yet Another Recursive Acronym, 一种恶意软件规则格式) rule or a **Sigma** (一种通用检测规则格式) signature today.

 四层情报对应四类读者：高管看战略，SOC 经理看战术，应急响应看作战，一线分析看技术。

---

## 3. IOCs, IOAs, and TTPs

Three acronyms dominate technical threat intelligence:

- **IOC** (Indicator of Compromise, 失陷指标): Artifacts left after an intrusion — malicious IPs, file hashes, domain names, registry keys. IOCs are backward-looking and easy to automate.
- **IOA** (Indicator of Attack, 攻击指标): Behaviors that suggest an attack is in progress — PowerShell spawning from Word, unusual LDAP queries, or a user authenticating from two continents in minutes. IOAs are forward-looking and harder to evade than IOCs.
- **TTP** (Tactics, Techniques, and Procedures, 战术、技术和程序): The *how* and *why* behind an adversary. TTPs change slowly, so detecting them is more durable than chasing IOCs.

The **Pyramid of Pain** (痛苦金字塔) illustrates this hierarchy. Blocking an IOC such as a single IP is easy for the attacker to bypass. Disrupting a TTP is much harder.

 IOC 是“痕迹”，IOA 是“行为”，TTP 是“习惯”；越往上，攻击者改变成本越高。

---

## 4. The Threat Intelligence Lifecycle

A mature intelligence program follows a lifecycle rather than a one-time feed purchase:

1. **Direction** (方向): Define intelligence requirements. What does the business need to know?
2. **Collection** (收集): Gather data from internal logs, open sources, commercial feeds, and sharing communities.
3. **Processing** (处理): Normalize, de-duplicate, and enrich raw data.
4. **Analysis** (分析): Turn data into judgments — attribution, impact, likelihood.
5. **Dissemination** (分发): Deliver the right intelligence to the right audience at the right level of detail.
6. **Feedback** (反馈): Measure whether the intelligence changed decisions and adjust the program.

If any step is skipped, the program becomes either a data hoard or an empty report. For example, collecting without direction produces **alert fatigue** (告警疲劳); analysis without dissemination produces unread PDFs.

 情报生命周期缺哪一步都会失败：无方向则堆砌数据，无反馈则无法改进。

---

## 5. TLP — Traffic Light Protocol

Not all intelligence should be shared with everyone. **TLP** (Traffic Light Protocol, 红绿灯协议) is a set of labels that define how far information may spread:

| Color | Meaning |
|-------|---------|
| **TLP:RED** | Restricted to named recipients only. |
| **TLP:AMBER** | Limited distribution within the organization. |
| **TLP:GREEN** | Community-wide sharing, not public. |
| **TLP:CLEAR** | Public disclosure allowed. |

Misusing TLP labels can damage trust. If a partner marks a report TLP:AMBER and you forward it to a public mailing list, future sharing may stop.

 TLP 是情报共享的“保密等级”，贴错标签会破坏合作信任。

---

## 6. STIX and TAXII — Sharing Standards

To share intelligence at scale, the industry uses two standards from **OASIS** (Organization for the Advancement of Structured Information Standards, 结构化信息标准促进组织):

- **STIX** (Structured Threat Information Expression, 结构化威胁信息表达): A language for describing threat intelligence objects — IOCs, TTPs, campaigns, threat actors, relationships.
- **TAXII** (Trusted Automated Exchange of Intelligence Information, 可信自动化情报交换): A transport protocol that moves STIX objects between organizations, tools, and repositories.

Think of STIX as the *content* and TAXII as the *postal service*. A SIEM can subscribe to a TAXII server and automatically ingest STIX objects as detection rules.

 STIX 是情报“格式”，TAXII 是情报“快递”；二者一起实现自动化共享。

---

## 7. Intelligence Requirements and Sources

Good intelligence starts with a requirement, not a feed. Example requirements:

- “Which ransomware groups are currently targeting healthcare in Asia?”
- “What **C2** (Command and Control, 命令与控制) infrastructure does APT29 use for phishing?”
- “Are our third-party vendors mentioned in any breach disclosures?”

Common sources include:

- **OSINT** (Open Source Intelligence, 开源情报): Public blogs, social media, malware repositories, CVE databases.
- **Commercial feeds**: Subscriptions from vendors with dedicated research teams.
- **ISACs** (Information Sharing and Analysis Centers, 信息共享与分析中心): Sector-specific groups such as Health-ISAC or FS-ISAC.
- **Internal telemetry**: Your own SIEM, EDR, email gateway, and incident reports.

Internal telemetry is often the highest-fidelity source because it describes what is actually happening in your environment.

 情报需求决定收集什么；内部遥测往往是最真实、优先级最高的来源。

---

## 8. From Intelligence to Detection

Intelligence becomes valuable only when it changes action. A practical workflow looks like this:

1. An analyst receives a STIX bundle describing a new phishing campaign.
2. The analyst extracts IOCs (domains, file hashes, sender addresses).
3. IOCs are pushed to the **DNS** (Domain Name System, 域名系统) sinkhole, email gateway, and proxy blocklist.
4. TTPs are translated into detection rules: “If `winword.exe` spawns `powershell.exe` with a base64-encoded command, alert.”
5. A week later, the analyst checks whether the rules fired and updates the **MITRE ATT&CK** (Adversarial Tactics, Techniques, and Common Knowledge, 对抗战术、技术与通用知识) coverage map.

This closed loop — intelligence → detection → validation → update — is what separates mature SOCs from alert factories.

 情报闭环：情报 → 检测规则 → 验证 → 更新覆盖图。

---

## 甲方视角思考

- **情报需求要贴合业务风险**：医疗行业应优先关注勒索软件团伙、供应链泄露和患者数据在黑市的流向，而不是泛泛地订阅所有 IOC 源。  
- **TLP 标签必须嵌入共享流程**：在与集团其他片区或外部 ISAC 交换情报时，在 STIX 对象中显式标注 TLP，并在 DLP/邮件网关侧做敏感词校验。  
- **优先把 TTP 转成检测规则**：IOCs 变化快，适合自动阻断；TTPs 变化慢，适合 SIEM/SIP 行为检测。建议每月对照 MITRE ATT&CK 评估一次覆盖缺口。  
- **内部遥测是最宝贵的情报源**：把 SIP、EDR、邮件网关、DNS 日志统一归一化，自己的告警历史往往比商业 feed 更能发现定向攻击。

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| Threat Intelligence | 威胁情报 | Evidence-based knowledge about threats |
| IOC (Indicator of Compromise) | 失陷指标 | Artifacts of an intrusion, e.g., hashes, IPs |
| IOA (Indicator of Attack) | 攻击指标 | Behaviors suggesting an ongoing attack |
| TTP (Tactics, Techniques, and Procedures) | 战术、技术和程序 | The adversary’s operational methods |
| Strategic/Tactical/Operational/Technical intelligence | 战略/战术/作战/技术情报 | Four layers of threat intel |
| Pyramid of Pain | 痛苦金字塔 | Shows difficulty for attackers to change indicators |
| TLP (Traffic Light Protocol) | 红绿灯协议 | Sharing restriction labels: RED/AMBER/GREEN/CLEAR |
| STIX | 结构化威胁信息表达 | Structured Threat Information Expression |
| TAXII | 可信自动化情报交换 | Trusted Automated Exchange of Intelligence Information |
| OSINT | 开源情报 | Open Source Intelligence |
| ISAC | 信息共享与分析中心 | Information Sharing and Analysis Center |
| MITRE ATT&CK | 对抗战术、技术与通用知识 | Globally used knowledge base of adversary behavior |
| C2 (Command and Control) | 命令与控制 | Attacker infrastructure managing compromised hosts |
| YARA | 恶意软件规则格式 | Pattern-matching for malware classification |
| Sigma | 通用检测规则格式 | Generic signature format for SIEMs |
| SIEM | 安全信息与事件管理 | Security Information and Event Management |
| EDR | 终端检测与响应 | Endpoint Detection and Response |
| DNS sinkhole | DNS 沉洞 | Redirects malicious domains to a controlled address |
| Alert fatigue | 告警疲劳 | Desensitization caused by excessive alerts |
| Closed loop | 闭环 | Intelligence → detection → validation → update cycle |

---

## 明日预告

**Day 38 — Digital Forensics Fundamentals**  
We will cover the forensic process, evidence acquisition, chain of custody, disk/memory/image forensics basics, timeline analysis, and how forensic findings feed back into threat intelligence and incident response.
