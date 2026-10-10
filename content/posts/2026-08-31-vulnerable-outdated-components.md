---
title: "Day 18 — Vulnerable and Outdated Components: The Supply Chain You Forgot to Patch"
date: 2026-08-31
tags:
  - daily
  - security
  - english
description: "Modern applications are not written from scratch — they are assembled. A typical web service pulls in hundreds of third-party components （第三方组件）: open"
---

**Date:** 2026-08-31 | **Difficulty:** ★★☆☆☆ Conceptual | **Source:** OWASP Top 10:2021 A06 + CISA Alert AA24-038A | **Link:** [OWASP A06:2021](https://owasp.org/Top10/A06_2021-Vulnerable_and_Outdated_Components/)

---

## Why This Matters

Modern applications are not written from scratch — they are assembled. A typical web service pulls in hundreds of **third-party components** （第三方组件）: open-source libraries, frameworks, plugins, and **container images** （容器镜像）. Each one is someone else's code, someone else's bug tracker, and someone else's patch schedule.

OWASP ranks **vulnerable and outdated components** as the **#6 risk** in its 2021 Top 10, but the real cost is often higher. When a single dependency is compromised, the blast radius can include every application that uses it. The 2020 **SolarWinds Orion** breach, the 2021 **Log4j** crisis, and the 2023 **MOVEit Transfer** attacks all share the same pattern: attackers did not break the front door; they walked in through a trusted component.

> 简而言之，供应链攻击的入口往往不是你自己写的代码，而是你信任地引入的组件。

---

## What Counts as a Vulnerable Component?

OWASP defines this category broadly. You are exposed if your application uses:

- Software components that are **out of support** or have **unpatched CVEs** （通用漏洞与暴露）.
- Libraries or frameworks with **known vulnerabilities** in the specific version you deploy.
- **Unsigned** or **unverified** updates that could be tampered with in transit.
- **Operating systems** （操作系统）, web servers, application servers, database systems, APIs, or runtime environments that are not regularly patched.

A common mistake is assuming that "we do not use that feature." In the Log4j case, many teams did not realize that **JNDI lookup** （Java命名与目录接口查询） was enabled by default in a logging library. They never called it directly — the library did it for them.

> 不要以"我们没有用到那个功能"为由忽略依赖漏洞；默认启用的特性同样会在攻击链中被触发。

---

## How Attackers Exploit Dependency Risk

The attack surface is not just the code you write. It is the entire **software supply chain** （软件供应链）:

1. **Public exploit for a known CVE.** Attackers scan the internet for apps running outdated versions of Apache Struts, Spring Framework, or WordPress plugins. Once a **proof-of-concept** （概念验证） is published on GitHub or Exploit-DB, exploitation becomes a commodity.

2. **Compromised upstream package.** A maintainer account is hijacked, a build pipeline is poisoned, or a malicious package is uploaded with a **typosquatting** （名称仿冒） name like `reqeusts` instead of `requests`. Developers install it without checking.

3. **Nested transitive dependencies.** Your direct dependency may be clean, but it pulls in ten sub-dependencies, and one of those is years out of date. This is why a simple `package.json` can hide a dangerous **dependency tree** （依赖树）.

4. **Container base image rot.** A `python:3.9` image built two years ago may contain dozens of OS-level vulnerabilities. If your build pipeline does not rebuild and republish images regularly, stale layers become stale risk.

> 攻击者不关心漏洞在哪一层代码，只关心能否利用它到达你的数据和权限。

---

## Defense: Visibility, Then Control

You cannot patch what you do not know you have. The first step is a **Software Bill of Materials** （软件物料清单，SBOM）: a machine-readable inventory of every component, version, license, and supplier.

OWASP and CISA recommend a four-layer approach:

| Layer | Action | Example Tools |
|-------|--------|---------------|
| **Inventory** | Generate and maintain SBOMs | `syft`, `cyclonedx-cli`, GitHub Dependency Graph |
| **Scan** | Check components against CVE databases | Snyk, Mend, OWASP Dependency-Check, Trivy |
| **Policy** | Block builds that introduce high/critical CVEs | SonarQube, Semgrep Supply Chain, Snyk Gate |
| **Patch** | Automate updates and rebuild container images | Renovate, Dependabot, CI/CD rebuild pipelines |

A useful internal policy is the **"CVE SLA"** （漏洞服务等级协议）: critical patches within 24–72 hours, high-severity within one week, and medium-severity within 30 days. Without an SLA, prioritization becomes political instead of risk-driven.

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| Vulnerable and Outdated Components | 易受攻击和过时的组件 | OWASP Top 10 A06:2021 |
| Third-party Component | 第三方组件 | 外部库、框架、插件、容器镜像等 |
| CVE (Common Vulnerabilities and Exposures) | 通用漏洞与暴露 | 公开漏洞编号体系 |
| Software Supply Chain | 软件供应链 | 从上游依赖到最终部署的全链路 |
| SBOM (Software Bill of Materials) | 软件物料清单 | 组件清单，类似软件的"配料表" |
| Transitive Dependency | 传递依赖 | 间接引入的子依赖 |
| Typosquatting | 名称仿冒 / 拼写仿冒 | 通过相似包名诱导安装恶意包 |
| Proof-of-Concept (PoC) | 概念验证 | 证明漏洞可利用的最小代码 |
| JNDI Lookup | JNDI 查询 | Log4j 漏洞的核心触发机制 |
| Container Image | 容器镜像 | 包含应用运行所需环境的打包文件 |
| CVE SLA | 漏洞修复服务等级协议 | 按严重程度规定修复时限 |

---

## 甲方视角思考

1. **SBOM 是供应链安全的基础** — 没有组件清单，漏洞响应就是盲人摸象；建议要求所有自研和采购系统提供标准化 SBOM。
2. **把依赖扫描嵌入 CI/CD** — 在代码合入前阻断新增高危 CVE，比生产环境救火便宜百倍。
3. **建立 CVE SLA 并纳入考核** — 用明确时限替代"尽快修复"，让修复进度可度量、可追责。
4. **容器镜像也要纳入生命周期管理** — 定期重建基础镜像，不能只关注应用代码而忽视底层 OS 漏洞。

---

## Tomorrow — Day 19 Preview

**Identification and Authentication Failures (OWASP A07)** — why "password123" is still a problem, how **credential stuffing** （凭证填充） and **session hijacking** （会话劫持） work, and what modern access control looks like from both attacker and defender angles.
