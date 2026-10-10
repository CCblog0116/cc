---
title: "Day 42 — Penetration Testing Fundamentals"
date: 2026-08-04
tags:
  - daily
  - security
  - english
description: "A vulnerability scan 漏洞扫描 asks: What known weaknesses exist on these assets? A penetration test 渗透测试, pentest asks a harder question: Can a real attac"
---

**Date:** Sunday, September 27, 2026
**Difficulty:** ★★★☆☆ Technical
**Source:** PTES — *Penetration Testing Execution Standard* + OWASP — *Web Security Testing Guide* + SANS — *Penetration Testing Articles*
**Link:** http://www.pentest-standard.org/index.php/Main_Page / https://owasp.org/www-project-web-security-testing-guide/ / https://www.sans.org/blog/?focus-area=penetration-testing

---

## 1. A Pentest Is Not a Scan

A **vulnerability scan** (漏洞扫描) asks: *What known weaknesses exist on these assets?* A **penetration test** (渗透测试, pentest) asks a harder question: *Can a real attacker turn those weaknesses into actual business impact?*

Scanners produce lists; pentesters produce proof. A scan might report a **missing patch** (缺失补丁); a pentest will chain that patch with a weak service account, escalate to a **domain admin** (域管理员), and demonstrate access to sensitive files. 扫描是"找洞"，渗透测试是"证明洞能被利用并造成什么后果"。

---

## 2. Rules of Engagement: The Contract Before the Keyboard

Before any testing starts, the **scope** (测试范围) and **rules of engagement** (测试规则, RoE) must be written down. These documents protect both sides and keep the test legal.

| Document element | What it defines |
|------------------|-----------------|
| **Scope** (范围) | Which IP ranges, domains, applications, and APIs are in or out |
| **Test type** (测试类型) | Black-box, grey-box, or white-box; external or internal |
| **Testing window** (测试窗口) | Approved dates and hours to avoid production surprises |
| **Exclusions** (排除项) | Critical systems that must not be disrupted, databases that must stay online |
| **Escalation path** (升级路径) | Who to call immediately if something breaks |
| **Evidence handling** (证据处理) | How screenshots, credentials, and data will be stored and destroyed |

没有书面的 RoE，渗透测试就是"未授权攻击"——即使是内部团队执行也可能触发法律或合规问题。

---

## 3. The Five-Phase Lifecycle

PTES and OWASP both describe pentesting as a cycle. The names vary slightly, but the flow is consistent:

```
[1] Pre-engagement (前期准备)
        |
[2] Reconnaissance (信息收集 / recon) → OSINT, footprinting, asset discovery
        |
[3] Scanning & Enumeration (扫描与枚举) → port scans, service versions, directory brute-force
        |
[4] Exploitation (漏洞利用) → gaining initial access through validated vulnerabilities
        |
[5] Post-exploitation (后利用) → privilege escalation, lateral movement, persistence, data access
        |
[6] Reporting (报告) → evidence, risk rating, remediation, retest plan
```

**Reconnaissance** is usually the longest phase. A good pentester spends more time understanding the target than attacking it. Tools like Shodan, theHarvester, and LinkedIn are common here. 信息收集的质量直接决定后续利用的成功率。

**Scanning** turns broad knowledge into specific targets. Nmap finds open ports; Nikto or Burp Suite identifies web flaws; BloodHound maps Active Directory attack paths. 扫描阶段输出的是"可能的入口清单"。

**Exploitation** proves the vulnerability is real. A responsible tester stops at the point where impact is demonstrated — they do not exfiltrate real customer data or destroy systems. 利用不是搞破坏，而是证明风险真实存在。

**Post-exploitation** answers: *Now that I am in, how far can I go?* This is where **pivoting** (跳板转发) and **lateral movement** (横向移动) happen. If the tester reaches a domain controller, the report will say so — with evidence.

**Reporting** is the deliverable. The best technical exploit is worthless if the client cannot understand the risk and fix it. 报告才是甲方真正花钱买的东西。

---

## 4. Black, Grey, and White Box

| Test style | What the tester knows | Simulates | Cost | Depth |
|------------|----------------------|-----------|------|-------|
| **Black-box** (黑盒) | Nothing except public target names | External attacker with no inside knowledge | Lower setup, longer recon | Surface-level |
| **Grey-box** (灰盒) | Limited credentials or architecture docs | Compromised user or insider | Balanced | Most common for enterprise |
| **White-box** (白盒) | Full source code, design docs, admin access | Malicious insider or thorough audit | Higher setup, shorter test | Deepest coverage |

Most mature 甲方 programs use **grey-box internal + external** tests once a year, plus focused white-box tests for major releases. 灰盒测试性价比最高，能同时模拟外部突破和内部扩散。

---

## 5. Purple Teaming: Pentest Meets Detection

A **red team** (红队) attacks; a **blue team** (蓝队) defends. A **purple team** (紫队) puts them in the same room. The goal is not just to find holes, but to measure whether your **SOC** (安全运营中心) and **EDR** (端点检测与响应) actually notice and respond.

Purple team exercises usually follow a simple loop:

1. Red executes a known **TTP** (战术/技术/流程, Tactics Techniques and Procedures) from MITRE ATT&CK.
2. Blue checks whether the alert fired, whether the analyst understood it, and how fast the response was.
3. Both sides update detection rules, playbooks, or controls.
4. Repeat with a new technique.

紫队不是为了找出更多漏洞，而是为了验证"检测-响应"闭环是否有效。

---

## 6. Reading a Pentest Report Like a Buyer

A good report should have three things: **evidence** (evidence), **risk** (risk), and **action** (action).

Look for these sections:

- **Executive summary** (执行摘要) — business impact in plain language for leadership.
- **Technical findings** (技术发现) — each issue with severity, location, proof, and reproduction steps.
- **Risk rating** (风险评级) — ideally context-aware, not just CVSS copy-paste.
- **Remediation** (修复建议) — specific, prioritized fixes with owners.
- **Retest scope** (复测范围) — what will be verified after fixes are applied.

If a report only lists CVEs without screenshots or reproduction steps, ask for more detail. If every finding is "critical" with no prioritization, the test lacked risk context. 甲方看报告时重点不是"有多少高危"，而是"哪些会真的影响业务、谁负责修、怎么验证"。

---

## 甲方视角思考

- 采购渗透测试前先把 RoE 和范围写清楚，避免测试团队误碰生产系统或越界测试。
- 灰盒内部+外部组合性价比最高，重点验证"从外网到域控"的完整攻击链。
- 把紫队演练结果接入 SIP/EDR 调优：发现漏洞不如发现"检测盲区"有价值。
-  pentest 报告必须含复测计划，否则修复效果无法闭环验证。

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| Penetration test (pentest) | 渗透测试 | Authorized simulated attack to prove business impact |
| Vulnerability scan | 漏洞扫描 | Automated check for known weaknesses |
| Scope | 测试范围 | Approved targets and boundaries for the test |
| Rules of engagement (RoE) | 测试规则 | Legal and operational agreements before testing |
| Black-box testing | 黑盒测试 | Tester has no internal knowledge |
| Grey-box testing | 灰盒测试 | Tester has limited internal access or information |
| White-box testing | 白盒测试 | Tester has full access to code, docs, and credentials |
| External test | 外部测试 | Attacker perspective from outside the network |
| Internal test | 内部测试 | Attacker perspective from inside the network |
| Reconnaissance (recon) | 信息收集 | Gathering intelligence about the target |
| OSINT | 开源情报 | Open-source intelligence from public sources |
| Enumeration | 枚举 | Detailed listing of users, services, shares, etc. |
| Exploitation | 漏洞利用 | Taking advantage of a vulnerability to gain access |
| Post-exploitation | 后利用 | Actions taken after initial access is achieved |
| Privilege escalation | 权限提升 | Gaining higher-level permissions on a system |
| Lateral movement | 横向移动 | Moving between systems inside the network |
| Pivoting | 跳板转发 | Using a compromised host to reach other networks |
| Persistence | 持久化 | Maintaining access across reboots or detection |
| Red team | 红队 | Offensive simulation team |
| Blue team | 蓝队 | Defensive security team |
| Purple team | 紫队 | Collaborative red/blue exercise |
| TTP | 战术/技术/流程 | Tactics, Techniques, and Procedures (MITRE ATT&CK) |
| Executive summary | 执行摘要 | High-level business impact section of a report |
| Remediation | 修复建议 | Recommended fix for a finding |
| Retest | 复测 | Re-verification after fixes are applied |

---

## Tomorrow's Preview

**Day 43 — Web Application Firewall (WAF) Fundamentals (Web 应用防火墙基础):** how WAFs inspect HTTP traffic, common rule sets (OWASP CRS), bypass techniques attackers use, and how to tune WAF alerts without drowning the SOC in false positives.
