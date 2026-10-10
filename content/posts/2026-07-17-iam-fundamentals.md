---
title: "Day 10 — Identity and Access Management (IAM): The Four Pillars"
date: 2026-07-17
tags:
  - daily
  - security
  - english
description: "Identity and Access Management IAM is the cybersecurity discipline that ensures the right people access the right resources for the right reasons at t"
---

**Date:** 2026-07-17 | **Difficulty:** ★★☆☆☆ (概念级) | **Category:** Identity Security
**Primary Source:** IBM Think — [What is Identity and Access Management?](https://www.ibm.com/think/topics/identity-access-management)
**Supplementary:** NIST — [Identity and Access Management Resource Center](https://www.nist.gov/identity-and-access-management)

---

## The Core Idea

Identity and Access Management (IAM) is the cybersecurity discipline that ensures **the right people access the right resources for the right reasons at the right time.** Think of it as the digital bouncer — it checks your ID (authentication / 身份认证), decides where you can go (authorization / 授权), and keeps a log of everything you do (auditing / 审计). According to the IBM X-Force Threat Intelligence Index, **30% of cyberattacks involve the theft and abuse of valid accounts** — that's why IAM sits at the center of modern security architecture.

---

## The Four Pillars of IAM

IBM breaks IAM into four interdependent pillars. They form a pipeline — each step depends on the one before it.

### 1. Administration (身份管理 / Identity Lifecycle Management)

Before anyone can log in, they need a **digital identity** (数字身份) — a collection of attributes (name, credentials, job title, access rights) tied to a specific entity. These identities are stored in a central directory (目录服务) that acts as the single source of truth.

Administration covers the full lifecycle:

- **Provisioning** — creating accounts and assigning initial permissions when someone joins
- **Maintenance** — updating roles and access as people change jobs or projects
- **Deprovisioning** — disabling or deleting accounts when someone leaves

The biggest risk here is the **orphaned account** (孤儿账户) — a former employee's credentials that still work because nobody remembered to revoke them. Orphaned accounts are a favorite attack vector; they give attackers valid, unmonitored access.

> 简言之：身份管理管的是"谁在系统里、他们是谁"，从入职到离职的完整生命周期。

---

### 2. Authentication (身份认证 / AuthN)

Authentication answers one question: **"Are you who you claim to be?"**

Users prove their identity by presenting **authentication factors** (认证因素), which fall into three categories:

| Factor Type | English | Examples |
|-------------|---------|----------|
| Something you know | Knowledge factor | Password, PIN, security question |
| Something you have | Possession factor | Security token, mobile device, smart card |
| Something you are | Inherence factor | Fingerprint, facial recognition, iris scan |

**Multi-Factor Authentication (MFA / 多因素认证)** requires at least two different factor types. Microsoft research shows that MFA stops **over 99.9% of account compromise attempts**. Even if an attacker steals your password (via phishing / 网络钓鱼 or a data breach / 数据泄露), they still can't log in without your second factor.

The IAM system checks submitted credentials against the central identity database. Match → access. No match → denied. Simple in theory, endlessly nuanced in practice.

> 简言之：认证回答"你是你吗"，最弱的是纯密码，加 MFA 后安全性飞跃式提升。

---

### 3. Authorization (授权 / AuthZ)

Once authenticated, the system asks: **"What are you allowed to do?"**

Authorization is where access control models come in. The four most common ones:

| Model | Full Name | How It Works |
|-------|-----------|-------------|
| **RBAC** | Role-Based Access Control / 基于角色的访问控制 | Permissions are tied to job roles. A sales rep gets sales-tool access; a DBA gets database access. Most widely used. |
| **ABAC** | Attribute-Based Access Control / 基于属性的访问控制 | Decisions use dynamic attributes — user department, resource sensitivity, time of day, device posture. More granular than RBAC. |
| **MAC** | Mandatory Access Control / 强制访问控制 | A central authority assigns classification labels (Top Secret, Confidential, etc.). Users cannot override — common in military/government. |
| **DAC** | Discretionary Access Control / 自主访问控制 | Resource owners set their own rules. Flexible but risky — owners may not understand security implications. |

All of these are governed by the **Principle of Least Privilege (PoLP / 最小权限原则)**: users should have the minimum access needed to do their job — and no more. When the task is done, elevated privileges should be revoked. This is a cornerstone of **Zero Trust Architecture** (NIST SP 800-207).

> 简言之：授权决定"你认证通过之后能碰什么"，最小权限是铁律 —— 只给刚好够用的权限。

---

### 4. Auditing (审计 / Identity Governance)

Auditing closes the loop: **"Is the system actually working as intended?"**

Key functions:

- **Activity logging** — who accessed what, when, from where
- **Access certification** — periodic reviews where managers confirm that their team members still need their assigned permissions (quarterly for high-risk access is standard)
- **Segregation of Duties (SoD / 职责分离)** — preventing conflicts like the same person approving and executing a financial transaction
- **Compliance mapping** — proving to regulators (GDPR, SOX, PCI DSS, HIPAA) that access controls exist and are enforced

According to IBM's Cost of a Data Breach report, organizations with mature IAM and auditing capabilities reduce the average breach cost by approximately **USD 189,838**, and credential-based breaches take an average of **246 days** to detect and contain — auditing shortens that window.

> 简言之：审计管"事后可追溯、可证明合规"，是应对监管审查和事故事后复盘的基础。

---

## Beyond the Four Pillars: Key Adjacent Concepts

- **Privileged Access Management (PAM / 特权访问管理)** — a specialized subset of IAM focused on high-risk accounts (domain admins, root users, database owners). Uses credential vaulting, just-in-time access, and session recording.
- **Single Sign-On (SSO / 单点登录)** — users authenticate once and access multiple applications. Uses protocols like SAML and OpenID Connect (OIDC). Reduces password fatigue but creates a single point of failure — if the SSO provider is compromised, everything is.
- **Identity Federation (身份联合)** — sharing identity information across organizational boundaries. A classic example is "Log in with Google/Facebook."
- **Identity Threat Detection & Response (ITDR / 身份威胁检测与响应)** — an emerging category that continuously monitors identity systems for privilege escalation, misconfigurations, and credential abuse.

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| Identity and Access Management (IAM) | 身份与访问管理 | The overarching discipline |
| Digital Identity | 数字身份 | A set of attributes tied to an entity in a system |
| Authentication (AuthN) | 身份认证 | Verifying who you are |
| Authorization (AuthZ) | 授权 | Determining what you can do |
| Multi-Factor Authentication (MFA) | 多因素认证 | 2+ factors from different categories |
| Role-Based Access Control (RBAC) | 基于角色的访问控制 | Permissions tied to job roles |
| Principle of Least Privilege (PoLP) | 最小权限原则 | Minimum access to do the job |
| Orphaned Account | 孤儿账户 | Active account with no legitimate owner |
| Privileged Access Management (PAM) | 特权访问管理 | Securing high-risk admin accounts |
| Single Sign-On (SSO) | 单点登录 | One login, many applications |
| Segregation of Duties (SoD) | 职责分离 | No single person controls an entire critical process |
| Identity Federation | 身份联合 | Sharing identity across organizations |
| Deprovisioning | 注销/停用 | Revoking access when someone leaves |

---

## 甲方视角思考

1. **先解决 orphaned accounts** — 这是 IAM 的最低垂果实：确保 HR 系统与 AD/Entra ID 联动，离职即自动停用，消除最容易被忽视的攻击面。
2. **MFA 全覆盖优先于追求 RBAC 完美** — 与其花半年时间重新设计角色矩阵，不如先把所有用户（尤其是 VPN/邮箱/管理员）的 MFA 推到位，MS 数据说 99.9% 的账户入侵就此封死。
3. **SSO 是把双刃剑** — 方便是真方便，但 IdP 一挂全挂。务必对 IdP 本身施加最严格的 MFA + PAM 控制，并对 IdP 登录做实时异常监控（impossible travel、陌生 IP）。
4. **每季度做一次特权账号审计** — 权限只增不减是人性，定期 Access Certification 是唯一解药。从最高风险的管理员账号开始做，不用一上来就全覆盖。

---

## Tomorrow's Preview

> **Day 11 — The OWASP Top 10: A Developer's Guide to Web Application Risks.** We'll walk through the 2021 OWASP Top 10 list with concrete examples, starting the transition from concept-level to technical content.
