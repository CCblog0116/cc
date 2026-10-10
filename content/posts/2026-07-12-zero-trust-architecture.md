---
title: "Day 5 — Zero Trust Architecture"
date: 2026-07-12
tags:
  - daily
  - security
  - english
description: "The Problem With the Castle-and-Moat Model"
---

**Date: 2026-07-12**
**Difficulty: ★★☆☆☆ Conceptual**
**Source: CISA — Zero Trust Maturity Model; NIST SP 800-207 — Zero Trust Architecture**
**Link: https://www.cisa.gov/topics/cybersecurity-best-practices/zero-trust**

---

## 📖 Article

### The Problem With the Castle-and-Moat Model

For decades, enterprise security was built like a **castle** (城堡): a strong wall (the **perimeter** / 边界) around the network, with **firewalls** (防火墙) and **VPNs** (虚拟专用网络) guarding the gates. Once you crossed the drawbridge, you were considered trusted and could move freely inside.

That model worked when employees worked in offices, apps lived in on-premises data centers, and the internet was "outside." But today, **workforces are distributed**, **data lives in the cloud**, and **attackers no longer knock at the front door**. They steal credentials, phish employees, or exploit a single exposed service — then move quietly inside the "trusted" zone.

> "The castle-and-moat model assumes that the perimeter is the only thing that needs defending. Modern attacks prove that assumption wrong every single day." 传统边界安全假设内网可信，但现代攻击常从窃取合法凭证进入后横向移动。

---

### What Is Zero Trust?

**Zero Trust** (ZT / 零信任) is a security model built on a simple idea: **never trust, always verify** (永不信任，始终验证). It means no user, device, or application is trusted by default — even if it is already inside the corporate network.

Instead of "trust because of location," Zero Trust says **verify because of identity, context, and behavior**. Every access request must be authenticated, authorized, and continuously evaluated before it reaches a resource.

**Zero Trust Architecture (ZTA)** (零信任架构) is the practical implementation of these principles. The authoritative definition comes from **NIST SP 800-207** (美国 NIST 标准 800-207), published in 2020.

> **Remember:** Zero Trust is not a single product, not a vendor appliance, and not a one-time project. It is a **security strategy** and an **architectural mindset** (架构思维). 零信任是安全策略，不是某个产品或项目。

---

### The Seven Tenets of NIST SP 800-207

NIST SP 800-207 lists seven core principles that define a true Zero Trust Architecture:

1. **All data sources and computing services are considered resources.**
   Everything — a laptop, a database, a printer, an API — is a resource that needs protection.

2. **All communication is secured regardless of network location.**
   Whether the request comes from the internet or from the next cubicle, it is treated the same way.

3. **Access is granted on a per-session basis.**
   Getting access once does not mean keeping access forever. Each session is evaluated independently.

4. **Access decisions are determined by dynamic policy.**
   Decisions consider identity, device health, location, behavior, time, and risk signals.

5. **The enterprise monitors and measures the integrity and security posture of all assets.**
   You cannot protect what you cannot see. Continuous **asset inventory** (资产清单) and **posture assessment** (态势评估) are required.

6. **Dynamic resource authentication and authorization are strictly enforced.**
   Identity verification happens at the point of access, not just at the network edge.

7. **The enterprise collects as much information as possible to improve security posture.**
   Logs, telemetry, and analytics feed back into policy decisions.

> **Key takeaway:** The perimeter is dead; the resource is the new perimeter. 资源本身成为新的边界。

---

### CISA's Zero Trust Maturity Model: Five Pillars

CISA organizes Zero Trust into five pillars and three cross-cutting capabilities. The five pillars are:

| Pillar | Focus Area | What It Means |
|---|---|---|
| **Identity** | Users, accounts, credentials | Strong **MFA** (多因素认证), **FIDO2** (快速身份在线认证), risk-based conditional access |
| **Devices** | Endpoints, laptops, phones, IoT | **Device inventory** (设备清单), **device posture** (设备态势) checks, EDR coverage |
| **Network** | Communication paths | **Micro-segmentation** (微分段), encrypted traffic, **software-defined perimeters** (软件定义边界) |
| **Applications & Workloads** | Apps, SaaS, APIs | **ZTNA** (零信任网络访问), least-privilege access, secure application integration |
| **Data** | Information assets | **Data classification** (数据分类), **DLP** (数据防泄漏), access based on data sensitivity |

Three cross-cutting capabilities support all five pillars:

- **Visibility and Analytics** (可见性与分析): See everything, log everything, analyze behavior.
- **Automation and Orchestration** (自动化与编排): Respond to risk signals in real time without manual tickets.
- **Governance** (治理): Policies, standards, and ownership across security, IT, and business teams.

---

### From Perimeter to Identity-Centric Security

Zero Trust shifts the control point from the **network edge** (网络边界) to the **identity** (身份) of the user or device. Identity travels with the user wherever they are — in the office, at home, on a plane, or in a coffee shop.

But identity is not just human users. **Machine identities** — service accounts, **API keys** (API 密钥), certificates, and bots — also need continuous verification. In fact, machine identities often outnumber human identities in large enterprises.

> **Context matters.** A user logging in from a known laptop in Guangzhou at 9 AM is different from the same user logging in at 3 AM from an unknown device in another country. Zero Trust uses these signals to make risk-based decisions. 零信任根据上下文动态决策，而非一次性登录即放行。

---

### Micro-Segmentation: Shrinking the Blast Radius

**Micro-segmentation** (微分段) divides the network into small, isolated zones. Instead of one big "trusted" internal network, each application, database, or workload lives in its own protected zone.

The benefit is simple: if one machine is compromised, the attacker cannot move freely to every other system. This limits the **blast radius** (爆炸半径) of a breach and slows down **lateral movement** (横向移动).

| Model | Trust Zone | Risk If One Host Is Compromised |
|---|---|---|
| Traditional perimeter | Entire internal network | High — attacker can move freely |
| Zero Trust + micro-segmentation | One small segment | Low — each segment requires separate access |

---

### Zero Trust Is a Journey, Not a Destination

No organization becomes "zero trust compliant" overnight. CISA's maturity model describes three stages:

- **Traditional**: Static, perimeter-based, implicit trust.
- **Initial / Advanced**: Starting to implement identity verification, device checks, and segmentation for critical assets.
- **Optimal**: Fully automated, dynamic, **data-centric** (以数据为中心) policies with continuous monitoring and response.

Most enterprises are somewhere between **Initial** and **Advanced**. The goal is to make steady progress, starting with the highest-risk assets.

> **Practical starting point:** Pick one high-value application (for example, a finance system or a developer tool) and protect it with **ZTNA** + **MFA** + device posture checks. Then expand. 从高风险资产试点，再逐步扩展。

---

## 📌 甲方安全工程师视角 (Security Engineer's Perspective)

1. **零信任不是把防火墙换成零信任产品**，而是重新设计访问逻辑：身份、设备、上下文、最小权限、持续验证缺一不可。
2. **MFA 只是起点**，不是终点；高价值系统应上 FIDO2/硬件密钥，抵御实时钓鱼代理攻击。
3. **微分段是控制勒索软件横向移动的关键控制**，但国内很多内网仍是"大二层"，这是需要逐步推动的硬骨头。
4. **日志和遥测是零信任的燃料**；没有统一可见性，PDP/PEP 只能做盲决策。

---

## 🧠 Key Terms

| English | 中文 | Note |
|---|---|---|
| Zero Trust (ZT) | 零信任 | Never trust, always verify |
| Zero Trust Architecture (ZTA) | 零信任架构 | Implementation of ZT principles |
| Perimeter-based security | 基于边界的安全 | Traditional castle-and-moat model |
| Implicit trust | 隐式信任 | Trust based on network location |
| Assume breach | 假设已失陷 | Design as if attackers are already inside |
| Least privilege | 最小权限 | Only the access needed, no more |
| Continuous verification | 持续验证 | Re-evaluate trust throughout the session |
| Micro-segmentation | 微分段 | Small, isolated network zones |
| Identity-centric | 以身份为中心 | Identity, not network, is the control point |
| Policy Decision Point (PDP) | 策略决策点 | The "brain" that decides access |
| Policy Enforcement Point (PEP) | 策略执行点 | The "gatekeeper" near the resource |
| Device posture | 设备态势 | Security health of a device |
| Telemetry | 遥测 | Logs, metrics, and behavioral data |
| ZTNA | 零信任网络访问 | Zero Trust Network Access |
| MFA | 多因素认证 | Multi-Factor Authentication |
| FIDO2 | 快速身份在线认证 | Phishing-resistant authentication standard |
| Data-centric | 以数据为中心 | Protect data regardless of where it lives |
| Blast radius | 爆炸半径 | Scope of damage from one compromise |
| Lateral movement | 横向移动 | Moving between systems inside a network |
| NIST SP 800-207 | 美国 NIST 零信任架构标准 | Authoritative ZTA definition |
| CISA ZTMM | CISA 零信任成熟度模型 | Five-pillar maturity roadmap |

---

## 🎯 Tomorrow's Preview

**Day 6 — Multi-Factor Authentication (MFA): Why It Fails and How to Make It Stronger** (★★☆☆☆)

> OTP, push fatigue, SIM swap, and why phishing-resistant MFA (FIDO2/WebAuthn) is becoming the new baseline.
