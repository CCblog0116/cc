---
title: "2026-10-13 — GitLab Warns of Max-Severity RCE in CI/CD Regex Compiler (CVE-2026-97229)"
date: 2026-10-13
tags:
  - daily
  - security
  - english
  - rce
  - gitlab
  - patch-management
description: GitLab urges admins to patch CVE-2026-97229, a CVSS 10.0 unauthenticated remote code execution flaw in its CI/CD Regular Expression Compiler caused by an integer overflow.
---

> [!abstract] TL;DR
> GitLab patched CVE-2026-97229, a maximum-severity (CVSS 10.0) integer overflow in its CI/CD Regular Expression Compiler that lets an unauthenticated attacker execute arbitrary code on self-managed servers — upgrade to 19.4.2 / 19.3.4 / 19.2.8 immediately.

## Original Article

GitLab warned users to immediately patch a maximum-severity vulnerability in the CI/CD Regular Expression Compiler that could let remote attackers run arbitrary code on targeted instances. Tracked as CVE-2026-97229 and scored CVSS 10.0, the critical flaw was discovered by a security researcher using the handle "joaxcar" and reported through GitLab's HackerOne bug bounty program.

The vulnerability stems from an integer overflow weakness in the CI/CD Regular Expression Compiler, the component that parses, compiles, and evaluates regular expressions in projects' pipeline configuration files. In its advisory, GitLab explained that "under certain conditions, [the flaw] could have allowed an unauthenticated user to execute arbitrary code on the GitLab server via a specially crafted regular expression in a CI/CD configuration, due to insufficient regular expression validation." The CVSS vector reflects the worst case: network-accessible, low attack complexity, no privileges required, and no user interaction.

The affected releases are GitLab Community Edition (CE) and Enterprise Edition (EE) versions from 19.2 before 19.2.8, from 19.3 before 19.3.4, and from 19.4 before 19.4.2. GitLab urged all self-managed installations to upgrade immediately, noting that GitLab.com already runs the patched version and GitLab Dedicated customers need take no action. No exploitation in the wild and no public proof-of-concept have been reported so far, and the flaw is not yet listed in CISA's Known Exploited Vulnerabilities catalog.

The risk is amplified by what a GitLab server holds: source code, CI/CD pipeline definitions, deploy keys, registry credentials, and cloud tokens. An unauthenticated RCE on that host is effectively a software supply chain breach — an attacker could read every repository, poison build artifacts, and pivot into every environment the runners can reach.

CVE-2026-97229 is the latest in a string of serious GitLab flaws. Three weeks earlier, GitLab fixed CVE-2026-93577 — also an integer overflow in the same regex compiler, scored 9.9 but requiring authentication. Last month, it patched another maximum-severity flaw (CVE-2026-85706) that let unauthenticated attackers read sensitive data; CISA added it to its exploited-vulnerabilities catalog one day later and ordered federal agencies to patch within three days. CISA has flagged five GitLab flaws abused in attacks since November 2021, including one exploited by ransomware gangs. GitLab reports over 30 million registered users and more than half of the Fortune 100 on its DevSecOps platform, making self-managed instances a high-value, frequently internet-facing target.

Source: https://www.bleepingcomputer.com/news/security/gitlab-warns-of-max-severity-rce-flaw-in-regex-compiler-engine/

## Key Vocabulary

| Word | Meaning | 中文 |
| ---- | ------- | ---- |
| integer overflow | A bug where a numeric value exceeds its storage range and wraps around, corrupting memory | 整数溢出 |
| unauthenticated | Requiring no login or credentials to perform the attack | 未认证的 |
| arbitrary code execution | Running any attacker-chosen code on the target system | 任意代码执行 |
| specially crafted | Deliberately constructed input designed to trigger a flaw | 精心构造的 |
| pipeline configuration | CI/CD settings file (e.g. .gitlab-ci.yml) defining build steps | 流水线配置 |
| self-managed | Hosted and maintained by the customer, not the vendor | 自托管的 |
| proof-of-concept (PoC) | Demonstration code proving a vulnerability is exploitable | 概念验证 |
| in the wild | Observed being exploited in real-world attacks | 在野（被利用） |
| bug bounty program | A reward scheme paying researchers for reporting flaws | 漏洞赏金计划 |
| attack complexity | How difficult an exploit is to execute reliably | 攻击复杂度 |
| pivot | Using a compromised system as a foothold to attack others | 横向移动/跳板 |
| supply chain breach | Compromise delivered through trusted software or build infrastructure | 供应链攻击 |

## Sentence Patterns

1. **"The vulnerability stems from [root cause] in [component]."**
   *The vulnerability stems from an integer overflow weakness in the CI/CD Regular Expression Compiler.*

2. **"Under certain conditions, [flaw] could have allowed [attacker type] to [impact]."**
   *Under certain conditions, the flaw could have allowed an unauthenticated user to execute arbitrary code on the server.*

3. **"[Vendor] urged users to [action] immediately, noting that [scope clarification]."**
   *GitLab urged users to upgrade immediately, noting that GitLab.com is already running the patched version.*

4. **"[CVE] is the latest in a string of [problem type] that [organization] has addressed in recent months."**
   *CVE-2026-97229 is the latest in a string of vulnerabilities that GitLab has addressed in recent months.*

5. **"The risk is amplified by [asset/exposure factor]."**
   *The risk is amplified by the fact that GitLab servers hold source code, deploy keys, and cloud tokens.*

## 中文摘要

GitLab 紧急修复最高危漏洞 CVE-2026-97229（CVSS 10.0）：CI/CD 正则表达式编译器存在整数溢出，未认证攻击者可借特制正则表达式在服务器上执行任意代码。影响 19.2/19.3/19.4 多个自托管版本，须立即升级至 19.2.8/19.3.4/19.4.2。暂未见在野利用，但鉴于服务器存有源码与凭据，风险极高。
