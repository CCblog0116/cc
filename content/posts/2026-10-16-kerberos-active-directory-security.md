---
title: "2026-10-16 — Kerberos and Active Directory Security: Tickets, Trust, and Domain Compromise"
date: 2026-10-16
tags:
  - daily
  - security
  - english
  - kerberos
  - active-directory
  - detection
description: Kerberos replaces reusable passwords with short-lived encrypted tickets — but once the krbtgt hash falls, the whole domain falls with it.
---

> [!abstract] TL;DR
> Kerberos powers enterprise SSO by issuing short-lived, cryptographically sealed tickets instead of sending passwords over the wire — but steal the `krbtgt` hash and an attacker can forge tickets for the entire domain, so defense means gMSA, NTLM deprecation, tiered administration, and ticket-aware detection.

## Original Article

Kerberos was built at MIT around one central insight: never send a password over the network, and never leave a reusable credential on a client. Instead, a mutually trusted third party — the Key Distribution Center (KDC), implemented in Active Directory as the Domain Controller — issues short-lived, cryptographically sealed tickets. The KDC is really two services in one: the Authentication Service (AS) verifies who you are and hands you a Ticket Granting Ticket (TGT), while the Ticket Granting Service (TGS) exchanges that TGT for a service ticket scoped to one specific resource, such as a file share or database.

The exchange runs in three steps. In AS-REQ/AS-REP, the client proves knowledge of its password by encrypting a timestamp, and receives a TGT sealed with the `krbtgt` account's key — the client can present it but never open it. In TGS-REQ/TGS-REP, the TGT is traded for a service ticket sealed with the target service's account hash. Finally, in AP-REQ, the client presents that ticket plus an authenticator; the service decrypts it with its own key, with no callback to the DC needed — offline authentication by design. Mutual authentication ensures the client is not talking to an impostor.

This design creates a well-mapped attack surface. Kerberoasting (T1558.003) exploits the fact that any user can request a service ticket for any SPN and crack the service account's password offline. AS-REP Roasting (T1558.004) targets accounts with preauthentication disabled. A Golden Ticket (T1558.001) forges any TGT after dumping the `krbtgt` hash via DCSync, granting domain-wide access for up to ten years; a Silver Ticket (T1558.002) forges service tickets while bypassing the KDC entirely, leaving no DC log entries. Pass-the-Ticket reuses harvested tickets, and legacy NTLM remains vulnerable to relay attacks.

Defense assumes tickets are already stolen. Rotate the `krbtgt` password twice after any DC compromise to kill Golden Tickets. Migrate service accounts to Group Managed Service Accounts (gMSA) — 240-character, auto-rotated, machine-only passwords that make Kerberoasting a dead end. Audit and phase out NTLM, enforce a tiered administration model so Tier 0 credentials never touch lower-tier machines, and pair it with LAPS. For detection, alert on Event 4769 with RC4 encryption and burst TGS requests, Event 4662 replication access by non-DC accounts, and Event 4768 without preauthentication.

Source: [Microsoft Learn — Kerberos Authentication Overview](https://learn.microsoft.com/en-us/windows-server/security/kerberos/kerberos-authentication-overview) · RFC 4120 · MITRE ATT&CK T1558

## Key Vocabulary

| Word | Meaning | 中文 |
| ---- | ------- | ---- |
| Kerberos | Ticket-based authentication protocol built at MIT, default in AD | 克贝罗斯认证协议 |
| Key Distribution Center (KDC) | Trusted third party issuing tickets; runs on the Domain Controller | 密钥分发中心 |
| Ticket Granting Ticket (TGT) | Sealed "passport wallet" obtained from the AS, encrypted with krbtgt's key | 票据授予票据 |
| Service Ticket | Credential scoped to one specific service, sealed with its account hash | 服务票据 |
| krbtgt | Special AD account whose hash seals all TGTs; forging it means owning the domain | Kerberos 域内核心账户 |
| Kerberoasting | Requesting service tickets for SPNs and cracking them offline (T1558.003) | 服务票据离线破解攻击 |
| Golden Ticket | Forged TGT granting domain-wide access after krbtgt hash theft (T1558.001) | 黄金票据 |
| Silver Ticket | Forged service ticket that bypasses the KDC entirely (T1558.002) | 白银票据 |
| DCSync | Abusing replication rights to pull all password hashes from a DC (T1003.006) | 目录复制同步攻击 |
| gMSA | Group Managed Service Account with auto-rotated 240-character password | 组托管服务账户 |
| NTLM Relay | Forwarding legacy NTLM authentication to another host | NTLM 中继攻击 |
| LAPS | Local Administrator Password Solution — unique, rotated local admin passwords | 本地管理员密码轮换方案 |

## Sentence Patterns

1. **"X was built around one central insight: ..."** — 用于引出某技术的设计初衷。
   *Kerberos was built around one central insight: never send a password over the network.*
2. **"Whoever can X owns Y."** — 强调某个能力意味着完全控制。
   *Whoever can forge TGTs owns the domain.*
3. **"You cannot detect your way out — you must rotate your way out."** — "不能只靠 A，必须靠 B"的对比句式。
   *Once a DC is compromised, you cannot detect your way out — you must rotate your way out.*
4. **"X is a dead end."** — 表示某条攻击路径被彻底封死。
   *Kerberoasting against a gMSA is a dead end.*
5. **"Ship these to your SIEM on day one."** — 建议立即落地某项检测/措施。
   *Ship these detection rules to your SIEM on day one.*

## 中文摘要

Kerberos 用短时效加密票据取代网络传输密码，KDC（域控）通过 AS/TGS 两步发放 TGT 与服务票据。攻击面包括 Kerberoasting、黄金/白银票据、票据传递与 NTLM 中继。防御核心：krbtgt 两次轮换、gMSA 托管服务账户、禁用 NTLM、分层管理与 LAPS，并对 4768/4662/4769 事件建立检测基线。
