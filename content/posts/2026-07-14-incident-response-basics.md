---
title: "Day 7 — Incident Response Basics"
date: 2026-07-14
tags:
  - daily
  - security
  - english
description: "🔗 https://mycybersecuritypath.com/cybersecurity/incident-response"
---

**Date:** July 14, 2026 | **Difficulty:** ★☆☆☆☆ (通识) | **Source:** NIST SP 800-61 / MyCyberSecurityPath / Vectra AI

🔗 https://mycybersecuritypath.com/cybersecurity/incident-response

---

## What Is Incident Response?

**Incident response (IR)** is the structured process organisations use to detect, contain, eradicate, and recover from security incidents — everything from malware infections to full-blown data breaches. Think of it as your organisation's emergency room protocol: when something goes wrong, IR defines who does what, in what order, and with what tools.

根据 NIST SP 800-61（美国国家标准与技术研究院《计算机安全事件处理指南》），事件响应是一个循环的生命周期，而非一次性的消防演习。每一次事件的经验教训都会反馈到下一轮的准备中。

> 💡 A **security event** (安全事件) is any observable occurrence — a login attempt, a firewall block. A **security incident** (安全事件/事故) is an event that actually violates or threatens to violate security policy. Not every event is an incident — that's what triage (分流/分诊) is for.

---

## The NIST Incident Response Lifecycle (4 Phases)

NIST SP 800-61 defines four phases that loop continuously:

### Phase 1: Preparation (准备阶段)

This is the only phase that happens *before* an attack — and it's the most important one. Organisations with formal IR teams and tested plans save an average of **$473,706** in breach costs (IBM 2025).

What you build here:
- **Playbooks** (剧本/响应手册) for common incident types: phishing, ransomware, data exfiltration
- **An IR toolkit**: forensic tools, log aggregation platforms, secure communication channels
- **A trained team**: tabletop exercises (桌面演练) that walk through hypothetical scenarios before real incidents expose gaps
- **A communication plan**: who gets notified at each severity level — legal, PR, executives, regulators
- **An up-to-date asset inventory**: you can't protect what you don't know you have

准备阶段是事件响应的"地基"——地基不牢，后面四个阶段全是空谈。对于甲方安全团队，这包括剧本编写、工具部署、桌面演练和资产清单的持续维护。

### Phase 2: Detection & Analysis (检测与分析)

This is where most entry-level SOC work happens. An alert fires — now you figure out what's real and what's noise.

Key activities:
1. **Monitor alert sources**: SIEM, EDR, email gateways, user reports
2. **Triage & classify** (分流与分类): false positive, low-priority event, or genuine intrusion?
3. **Collect initial indicators** (收集初始指标): IP addresses, domains, file hashes, usernames, timestamps
4. **Determine scope** (确定范围): how many systems? Is the attacker still active? Has data been exfiltrated?
5. **Document everything**: build a timeline from the very first alert — every action, decision, and piece of evidence

这一阶段的工作决定了"这到底是误报还是真实入侵"——而误判的代价可能是数百万美元。初级 SOC 分析师（Tier 1-2）的大部分日常工作就在这里。

### Phase 3: Containment, Eradication & Recovery (遏制、根除与恢复)

Once you've confirmed an incident, your goal shifts to stopping the bleeding and returning to normal.

| Sub-phase | What it means | Example |
|-----------|--------------|---------|
| **Containment** (遏制) | Stop the damage from spreading | Isolate affected systems from the network; disable compromised accounts; block malicious IPs at the firewall |
| **Eradication** (根除) | Remove the root cause entirely | Delete malware, close backdoors, patch the vulnerability that allowed entry |
| **Recovery** (恢复) | Restore normal operations safely | Restore from known-good backups; rebuild systems; monitor closely for re-infection |

> ⚠️ **Critical rule**: Containment comes BEFORE eradication. You must stop the bleeding before you treat the wound. Skipping containment to jump straight to "delete the malware" lets the attacker pivot to other systems while you're busy cleaning one machine.

遏制优先于根除——这是面试和认证考试（如 Security+、GCIH）中最常见的考点。先止血，再清创。

### Phase 4: Post-Incident Activity (事件后活动/经验教训)

This is where organisations either get better or repeat the same failures.

1. **Lessons learned meeting** (复盘会议): within 1-2 weeks of incident closure — what worked, what was slow, what was missing?
2. **Update playbooks and procedures**: if the incident exposed a gap, close it
3. **Preserve evidence**: forensic images, logs, and documentation for legal, regulatory, or insurance purposes
4. **Calculate impact**: downtime, data loss, financial cost, regulatory exposure
5. **Share sanitised findings**: de-identified incident reports help other teams strengthen their defences

跳过这一阶段的组织，往往会在同一个坑里摔倒两次。复盘不是走过场——它是对剧本、工具和人三方面的系统性修补。

---

## NIST vs. SANS: Two Frameworks, Same Goal

| Dimension | NIST SP 800-61 | SANS PICERL |
|-----------|----------------|-------------|
| **Phases** | 4 | 6 |
| **Granularity** | Merged — containment, eradication, recovery are one phase | Separated — each is its own distinct step |
| **Best for** | Policy, compliance, strategic planning | Operational execution, hands-on responders |
| **Memory aid** | Prep → Detect → Contain/Eradicate/Recover → Post-Incident | **PICERL**: Preparation, Identification, Containment, Eradication, Recovery, Lessons Learned |

Both frameworks are complementary. Many organisations use NIST at the policy level ("we *will* do IR") and SANS at the operational level ("here's *how* we do IR, step by step"). For beginners, start with NIST — fewer moving parts, cleaner mental model.

NIST 适合"定义我们要做 IR"；SANS 适合"这是逐步操作手册"。入门从 NIST 四个阶段开始，上手实操再补 SANS 的六步法。

---

## Quick IR Commands You Can Practise in a Home Lab

```bash
# Check suspicious network connections (Linux)
netstat -tulnp | grep ESTABLISHED
ss -tunap | grep ESTAB

# Search for failed authentication attempts
grep -r "failed password" /var/log/auth.log | tail -20

# Check SSH activity in the last 2 hours
journalctl -u sshd --since "2 hours ago"

# Look for recently modified files in sensitive temp directories
find /tmp /var/tmp /dev/shm -type f -mmin -60 2>/dev/null

# Check scheduled tasks for persistence mechanisms
crontab -l
ls -la /etc/cron.d/
```

```powershell
# Check established connections with remote addresses (Windows)
Get-NetTCPConnection | Where-Object {$_.State -eq "Established"} | Select-Object LocalPort,RemoteAddress,OwningProcess

# Search Windows Security log for failed logins (Event ID 4625)
Get-WinEvent -FilterHashtable @{LogName='Security'; Id=4625} -MaxEvents 20 | Format-Table TimeCreated, Message -Wrap
```

These commands are a first responder's bread and butter. Practise them in a VM-based home lab with tools like Wireshark, Splunk Free, and SIFT Workstation — all available at no cost.

这些命令是事件响应的"肌肉记忆"。在家搭建虚拟机环境，用 Splunk Free + Wireshark + SIFT Workstation 反复练习。

---

## Key IR Metrics You Should Know

| Metric | Definition | 2025 Benchmark |
|--------|-----------|---------------|
| **MTTD** (Mean Time to Detect) | Average time from threat entry to discovery | 181 days (161 with AI) |
| **MTTR** (Mean Time to Respond) | Average time from detection to containment | 60 days |
| **Dwell Time** (驻留时间) | Time attacker remains undetected | 7 days median |
| **Cost per Incident** | Total cost: response + recovery + business impact | $4.44M global average |

AI-enabled organisations identify and contain incidents **98 days faster** than those using manual approaches, saving an average of **$2.2 million** per breach.

---

## 🛡️ 甲方视角思考

- **桌面演练是性价比最高的 IR 投入**：成本几乎为零，但能在真实事件前暴露剧本漏洞和沟通断层——比事故后写复盘报告便宜得多。
- **MTTD 181 天意味着攻击者平均在你的网络里潜伏半年**：如果只靠告警被动响应，你发现入侵时数据早就被搬空了，威胁狩猎（threat hunting）必须作为主动补充。
- **先搞定前三个剧本**：钓鱼响应、勒索软件响应、数据泄露响应——这三个覆盖了 80% 以上的真实场景，其他的可以逐步补。
- **文档不是可选的**：从第一个告警开始记录时间线和每一步操作，这不仅是为了复盘——监管通报、保险理赔、甚至法律诉讼都依赖这条完整的证据链。

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| Incident Response (IR) | 事件响应 | 检测、遏制、根除、恢复安全事件的系统化方法 |
| Security Event | 安全事件（可观测行为） | 如一次登录、一次防火墙拦截 |
| Security Incident | 安全事件/事故（违规行为） | 实际违反或威胁违反安全策略的事件 |
| Triage | 分流/分诊 | 判断告警是误报还是真实入侵的过程 |
| Playbook | 剧本/响应手册 | 针对特定事件类型的逐步操作指南 |
| Tabletop Exercise | 桌面演练 | 团队走查假设场景以发现计划的漏洞 |
| Containment | 遏制 | 阻止事件扩散（如隔离系统、禁用账户） |
| Eradication | 根除 | 彻底移除威胁的根本原因 |
| Dwell Time | 驻留时间 | 攻击者被发现前在环境中的未检测时间 |
| MTTD / MTTR | 平均检测/响应时间 | IR 的核心效能指标 |
| DFIR | 数字取证与事件响应 | IR + 证据收集、保存和分析 |
| SIEM | 安全信息与事件管理 | 集中收集和分析日志的平台（如 Splunk、Elastic） |
| EDR | 终端检测与响应 | 主机级别的威胁检测与调查工具 |
| Threat Hunting | 威胁狩猎 | 主动搜索环境中已绕过防御的威胁 |
| NIST SP 800-61 | NIST 事件处理指南 | 行业标准 IR 框架（2025 年已发布 Revision 3） |

---

## Tomorrow's Preview

Day 8 将进入 **★★☆☆☆ 概念级** 阶段。话题预告：**Social Engineering Beyond Phishing（钓鱼之外的社会工程学）**——pretexting（借口伪造）、baiting（诱饵攻击）、tailgating（尾随）、quid pro quo（利益交换），以及为什么"人"永远是安全链条中最薄弱的一环。
