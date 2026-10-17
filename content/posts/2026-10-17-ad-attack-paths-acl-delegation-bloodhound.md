---
title: "2026-10-17 — AD Attack Paths: ACL Abuse, Delegation, and BloodHound"
date: 2026-10-17
tags:
  - daily
  - security
  - english
  - active-directory
  - bloodhound
  - attack-path
description: How attackers chain harmless AD permissions into Domain Admin paths via ACL abuse and Kerberos delegation, and how defenders cut those edges with BloodHound.
---

> [!abstract] TL;DR
> Attackers rarely need a 0-day to own a domain — they chain small, legitimate AD permissions (ACL edges and Kerberos delegation) into attack paths to Domain Admin; defenders must map the graph with BloodHound and cut the edges.

## Original Article

In an Active Directory environment, attackers rarely need a zero-day to compromise the domain. Instead, they chain small, legitimate permissions that were granted years ago and never audited. A local admin on one server, a helpdesk group that can reset passwords, a service account holding GenericAll over a security group — each grant looks harmless on its own, but chained together they form a graph from any compromised low-privileged user to Domain Admin. SpecterOps researchers famously found that in most environments, any domain user can reach Domain Admin through some combination of ACL and delegation edges, without exploiting a single vulnerability.

Every AD object carries a security descriptor containing an Access Control List. Certain permissions act as "keys": GenericAll grants full control (reset passwords, add yourself to groups, set an SPN for Kerberoasting); GenericWrite enables Shadow Credentials by writing to msDS-KeyCredentialLink; WriteDacl and WriteOwner let an attacker rewrite the ACL itself; and AllExtendedRights on the Domain object enables DCSync — dumping every hash in the domain, including krbtgt. If anyone other than your DCs and the AAD Connect account holds replication rights, that is an incident-grade finding.

Kerberos delegation is the classic attack-path amplifier. Unconstrained delegation caches user TGTs on a frontend host, enabling Pass-the-Ticket. Constrained delegation lets a compromised service impersonate any user toward listed SPNs. Resource-Based Constrained Delegation (RBCD) flips the trust direction: if you can write a computer object's attributes, you can write yourself into its delegation list and impersonate users to that machine.

BloodHound uses graph theory to reveal these hidden relationships. Its collector, SharpHound, ingests users, groups, ACLs, delegation settings, and sessions into a Neo4j graph database, then computes shortest attack paths to high-value targets. Blue teams should run it too — quarterly — and treat the "path to Domain Admin" list as a remediation backlog.

Defense is configuration hygiene, not another appliance: enforce a tiered admin model so Tier-0 credentials never touch lower-tier hosts; audit dangerous ACEs quarterly; inventory all three delegation modes; and alert on Event ID 5136 writes to delegation and key-credential attributes so new edges are detected as they are created.

Source: https://github.com/SpecterOps/BloodHound · https://learn.microsoft.com/en-us/windows-server/identity/ad-ds/delegation/kerberos-constrained-delegation-overview

## Key Vocabulary

| Word | Meaning | 中文 |
| ---- | ------- | ---- |
| Attack Path | Chain of permissions from low-privilege user to Domain Admin | 攻击路径 |
| ACL / ACE | Access Control List / Access Control Entry, per-object permission grants | 访问控制列表 / 访问控制项 |
| GenericAll | Full control over an AD object | 完全控制权限 |
| WriteDacl | Permission to modify the ACL itself | 写 ACL 权限 |
| ForceChangePassword | ACE allowing forced password reset on a user | 强制改密权限 |
| DCSync | Abusing replication rights to dump all domain hashes (T1003.006) | 目录复制同步攻击 |
| Shadow Credentials | Writing to msDS-KeyCredentialLink to authenticate as a target | 影子凭据 |
| Unconstrained Delegation | Delegation mode that caches user TGTs on the host | 非约束委派 |
| Constrained Delegation | Delegation restricted to an SPN allowlist | 约束委派 |
| RBCD | Resource-Based Constrained Delegation, target holds the allowlist | 基于资源的约束委派 |
| BloodHound / SharpHound | Graph-based AD analysis tool and its data collector | 血猎图分析工具 / 采集器 |
| Tiered Admin Model | Tier 0/1/2 credential isolation model | 分层管理模型 |

## Sentence Patterns

1. **"Individually, each is X. Chained together, they form Y."** — 单独看与组合危害的对比句型。
   *Individually, each grant looks harmless. Chained together, they form a graph to Domain Admin.*

2. **"If anyone other than X has these rights — that is an incident-grade finding."** — 划定红线并定性严重等级。
   *If anyone other than the DCs holds replication rights, that is an incident-grade finding.*

3. **"The defender's job is not A but B."** — 纠正认知、给出正确职责定位。
   *The defender's job is not "patch everything" but find and cut these edges.*

4. **"Treat the file as Tier-0 data."** — 对产物/数据定级并提出保护要求。
   *SharpHound output is a full AD map — treat the file as Tier-0 data and encrypt it.*

5. **"Run it quarterly, export the list, and burn those edges down one by one."** — 给出节奏化的整改动作。
   *Run BloodHound quarterly and burn the shortest paths down one by one.*

## 中文摘要

攻击者无需 0-day，仅靠串联 AD 中"看似无害"的 ACL 权限与 Kerberos 委派即可从低权限账户直达 Domain Admin。BloodHound 用图论揭示最短攻击路径；防守方应分层隔离 Tier-0 凭据、季度审计高危 ACE、清理委派配置，并用 5136 事件监控新边的产生。
