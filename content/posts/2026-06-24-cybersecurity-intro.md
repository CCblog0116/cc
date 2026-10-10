---
title: "Day 1 — Cybersecurity Intro"
date: 2026-06-24
tags:
  - daily
  - security
  - english
description: "- Protects sensitive data using encryption 加密, authentication 身份认证 and access control 访问控制."
---

**日期：2026-06-24**
**难度：★☆☆☆☆ 入门通识（Fundamentals）**
**来源：GeeksforGeeks — Introduction to Cyber Security**
**原文链接：https://www.geeksforgeeks.org/cybersecurity/what-is-cyber-security/**

---

## 📖 文章正文

### What is Cybersecurity?

**Cybersecurity** (网络安全) is the process of protecting networks, systems, applications and digital assets from unauthorized access (未授权访问), cyberattacks (网络攻击), malware (恶意软件) and data breaches (数据泄露). It ensures the **confidentiality, integrity and availability** (CIA — 机密性、完整性、可用性) of information while supporting secure and sustainable digital infrastructure.

**Why it matters:**
- Protects sensitive data using **encryption** (加密), **authentication** (身份认证) and **access control** (访问控制).
- Secures networks and systems against malware, ransomware and cyber threats.
- Supports safe digital transformation through secure cloud and IT infrastructure.
- Reduces downtime, resource misuse and operational risks caused by attacks.
- Enhances the reliability and **resilience** (韧性/弹性) of modern digital technologies.

---

### The CIA Triad (CIA 三元组)

Cybersecurity is based on three core principles that help protect information and systems:

- **Confidentiality (机密性):** Ensures that sensitive information is accessible only to authorized users.
- **Integrity (完整性):** Protects data from unauthorized modification and maintains its accuracy.
- **Availability (可用性):** Ensures systems, services and data remain accessible whenever needed.

> 💡 **记忆点：** CIA 在安全领域不是"中央情报局"，而是评估任何安全控制有效性的**最基础三角模型**。以后看到一个安全方案，先问它保护了 CIA 中的哪一个。

---

### Types of Cybersecurity

There are seven major types of cybersecurity:

| 类型 | 英文 | 保护对象 | 常用工具/手段 |
|------|------|----------|---------------|
| 网络安全 | **Network Security** | 局域网/广域网 | Firewall (防火墙), VPN (虚拟专用网络), IDS/IPS (入侵检测/防御系统) |
| 应用安全 | **Application Security** | 软件 & App | Secure coding (安全编码), SAST/DAST (静态/动态应用测试) |
| 数据安全 | **Information / Data Security** | 敏感数据 | Encryption, DLP (数据防泄漏), backup (备份) |
| 云安全 | **Cloud Security** | 云上资源 | IAM (身份与访问管理), CASB (云访问安全代理) |
| 端点安全 | **Endpoint Security** | PC/手机/服务器 | EDR (端点检测与响应), antivirus (杀毒软件) |
| 运营安全 | **Operational Security** | 流程 & 人员 | Risk assessment (风险评估), incident response (事件响应) |
| 物联网安全 | **IoT Security** | 智能设备 | Firmware update (固件更新), device authentication |

---

### Major Cyber Threats (主要威胁类型)

| 威胁 | 英文 | 一句话解释 |
|------|------|------------|
| 恶意软件 | **Malware** | 包含 virus (病毒)、trojan (木马)、spyware (间谍软件) 等有害程序 |
| 勒索软件 | **Ransomware** | 加密文件索要赎金，常针对企业 |
| 钓鱼攻击 | **Phishing** | 假邮件/网站骗取凭证；定向版叫 **Spear Phishing** (鱼叉钓鱼) |
| 分布式拒绝服务 | **DDoS (Distributed Denial-of-Service)** | 用海量流量打瘫服务器 |

---

### Emerging Trends (新兴趋势)

- **AI & Machine Learning (人工智能与机器学习):** AI-powered tools help detect, analyze and respond to cyber threats more quickly.
- **Rising Ransomware:** 勒索软件攻击持续增长，**regular backups** (定期备份) 与强安全控制是关键。
- **Cloud Security:** 随着云采用率提升，云上数据与应用的保护成为重点。
- **IoT Security Challenges:** 智能家居、可穿戴设备带来新风险。
- **Zero Trust Security (零信任):** 验证每个用户和设备才放行 — "never trust, always verify" (永不信任，始终验证).

---

### Challenges (行业挑战)

- **Evolving Threats (不断演化的威胁):** 攻击者持续创新，防御必须持续更新。
- **Limited Budgets (预算有限):** 安全工具昂贵，需要按资产优先级排兵布阵。
- **Insider Threats (内部威胁):** 滥用合法权限 — 落实最小权限原则 (Principle of Least Privilege)。
- **Complex Technology (技术栈复杂):** 云、IoT、混合架构提升复杂度。

---

## 🧠 今日关键词速查表

| 英文 | 中文 | 备注 |
|------|------|------|
| Cybersecurity | 网络安全 | = InfoSec 的子集，专注数字空间 |
| CIA Triad | 机密性-完整性-可用性 | 安全界的"第一性原理" |
| Malware | 恶意软件 | Virus / Trojan / Worm / Spyware 的统称 |
| Ransomware | 勒索软件 | 加密数据 → 索要赎金 |
| Phishing | 钓鱼攻击 | 骗取凭证/诱导点击 |
| DDoS | 分布式拒绝服务 | 流量洪水攻击 |
| Firewall | 防火墙 | 网络层第一道关卡 |
| EDR | 端点检测与响应 | 取代传统 AV 的新一代端点防护 |
| Zero Trust | 零信任 | 默认不信任何人/设备 |
| Vulnerability | 漏洞 | 系统中的可被利用弱点 |
| Encryption | 加密 | 把明文变密文 |
| Authentication | 身份认证 | 证明"你是谁" |
| Authorization | 授权 | 决定"你能做什么" |
| Incident Response | 事件响应 | 发现 → 遏制 → 根除 → 恢复 |

---

## 📌 安全工程师视角的小思考

作为甲方安全工程师，今天的内容虽然基础，但请记住：

1. **CIA 三角** 是写任何安全方案文档时最常引用的模型 — 任何控制措施都要能映射到 CIA 至少一项。
2. **Zero Trust** 不再是新概念，但很多企业仍停留在"内网可信"的旧范式。推进零信任落地是接下来几年的主旋律。
3. **Ransomware** 是甲方最怕的事故类型，**3-2-1 备份策略** (3 份副本、2 种介质、1 份离线) 仍是性价比最高的兜底手段。

---

## 🎯 明日预告

Day 2 会进入**威胁类别深度阅读**，主题：**Phishing 钓鱼攻击 — Anatomy of a Modern Phishing Campaign**（现代钓鱼攻击解剖），难度 ★★☆☆☆。
