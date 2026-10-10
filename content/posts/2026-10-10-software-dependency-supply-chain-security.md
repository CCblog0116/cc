---
title: "Day 55 — Supply Chain Security for Software Dependencies: SBOM, SCA, and Vendor Trust"
date: 2026-10-10
tags:
  - daily
  - security
  - english
description: "- NIST SP 800-161 Rev. 1 — C-SCRM: https://csrc.nist.gov/publications/detail/sp/800-161/rev-1/final"
---

**Date:** 2026-10-10 (Saturday)  
**Difficulty:** ★★★★☆ Deep (Day 46+ 深度阶段第十课)  
**Source:** NIST SP 800-161 Rev. 1 (Cybersecurity Supply Chain Risk Management) · NTIA SBOM Minimum Elements · CISA SBOM Resources · OWASP Software Component Verification Standard (SCVS)  
**Reference links:**
- NIST SP 800-161 Rev. 1 — C-SCRM: https://csrc.nist.gov/publications/detail/sp/800-161/rev-1/final
- CISA — Software Bill of Materials (SBOM): https://www.cisa.gov/sbom
- OWASP SCVS: https://owasp.org/www-project-software-component-verification-standard/
- GitHub Advisory Database: https://github.com/advisories

---

## 1. Your Code Is Not Just Your Code

A modern application is rarely built from scratch. It is assembled from **open-source components** (开源组件), third-party libraries, frameworks, and container base images — often 70–90% of the final codebase. This is efficient, but it means every dependency is an extension of your **attack surface** (攻击面) that you did not write and probably cannot fully audit.

Attackers know this. Instead of attacking a hardened application directly, they attack the **software supply chain** (软件供应链): the ecosystem of code, build tools, and distribution channels that delivers software into your environment. One compromised dependency can silently propagate to thousands of downstream victims.

This is the logic behind SolarWinds (2020), the `event-stream` npm hijack (2018), and the `xz-utils` backdoor attempt (2024). In each case, the victims were breached through code they chose to trust.

> 简注：你的应用 70%–90% 的代码来自别人写的依赖，供应链攻击正是冲着这份"信任"来的。

---

## 2. The Attack Families: How Dependencies Get Weaponized

Not all supply chain attacks look the same. Knowing the distinct families helps you map defenses to each one.

| Attack Family | How It Works | Real Example | Primary Defense |
|---------------|--------------|--------------|-----------------|
| **Compromised build/distribution** (构建环境被入侵) | Attacker injects malicious code into vendor's build pipeline or update server | SolarWinds SUNBURST (2020) | Vendor SBOM + signed updates + behavioral monitoring |
| **Account takeover of maintainer** (维护者账号接管) | Phished or hijacked maintainer publishes a malicious version | `event-stream` npm (2018) | Version pinning + lockfile review + staged upgrades |
| **Typosquatting** (包名抢注) | Malicious package named to look like a popular one (`reqests` vs `requests`) | Many npm/PyPI campaigns | Private registry allowlist + SCA scanning |
| **Dependency confusion** (依赖混淆) | Attacker publishes a package with your internal name to a public registry; default resolvers fetch the public one | `discord` token theft (2021) | Namespace reservation + resolver pinning to private registry |
| **Protestware / maintainer sabotage** (维护者投毒) | Legitimate maintainer deliberately breaks or weaponizes their own package | `node-ipc` (2022) | Pin versions + test before upgrade + vendor trust review |
| **Social engineering of trust** (信任链社工) | Attacker spends months contributing to a project to earn maintainer access | `xz-utils` (2024) | Behavioral anomaly detection + staged rollout + SBOM |

> 简注：六种攻击路径各有侧重，防御不能只靠一种工具——版本锁定、扫描、签名、行为监控要组合使用。

---

## 3. SBOM: Knowing What You Actually Run

A **Software Bill of Materials** (软件物料清单，SBOM) is a formal, machine-readable inventory of every component in a piece of software — including nested dependencies (dependencies of dependencies). Think of it as an ingredients list for software.

When the next Log4Shell drops, the difference between a 2-hour response and a 2-month scramble is a single question: *do you know where the vulnerable library is?* An SBOM turns "I don't know" into a database query.

### 3.1 The NTIA Minimum Elements

The U.S. **NTIA** (国家电信和信息管理局) defined the minimum fields a usable SBOM must contain:

| Field | Meaning |
|-------|---------|
| **Supplier** (供应商) | Who created the component |
| **Component name** (组件名) | Canonical package name |
| **Version** (版本) | Exact version string |
| **Unique identifier** (唯一标识) | PURL, CPE, or SWHID |
| **Dependency relationship** (依赖关系) | What depends on what |
| **SBOM author** (SBOM 生成方) | Who produced the document |
| **Timestamp** (时间戳) | When it was generated |

### 3.2 Formats and Tooling

| Format | Ecosystem | Notes |
|--------|-----------|-------|
| **SPDX** (SPDX 格式) | Linux Foundation standard | ISO/IEC 5962; strong license-compliance support |
| **CycloneDX** (CycloneDX 格式) | OWASP | Security-focused; integrates well with CI/CD |
| **SWID** (SWID 标签) | ISO 19770-2 | Common in enterprise asset management |

Common generators: **Syft** (images/filesystems), **CycloneDX Maven/Gradle/npm plugins**, **Trivy** (also scans vulnerabilities).

> 简注：SBOM 的价值不在于"有一份文件"，而在于漏洞爆发时能在几分钟内定位所有受影响系统。

---

## 4. SCA: Continuous Vulnerability Analysis of Dependencies

**Software Composition Analysis** (软件成分分析，SCA) is the practice of automatically identifying open-source components in your code and matching them against vulnerability databases, license risks, and maintenance health signals.

### 4.1 What a Good SCA Process Covers

1. **Inventory** (组件清单): Detect direct and **transitive dependencies** (传递依赖) from lockfiles, manifests, and built artifacts.
2. **Vulnerability matching** (漏洞匹配): Cross-reference with NVD, GitHub Advisories, OSV.
3. **Reachability analysis** (可达性分析): Is the vulnerable function actually called by your code? This cuts noise dramatically.
4. **License risk** (许可证风险): GPL/AGPL contamination can create legal exposure.
5. **Maintenance health** (维护健康度): Last release date, maintainer count, open issue backlog — the early-warning signs of future `xz`-style abandonment.

### 4.2 Prioritization: Not Every CVE Deserves a Fire Drill

Mature teams layer prioritization signals on top of raw **CVSS** (通用漏洞评分系统) scores:

| Signal | Question It Answers | Tooling |
|--------|--------------------|---------|
| **CVSS** | How severe is the flaw in theory? | NVD base score |
| **EPSS** (漏洞利用预测评分) | How likely is it actually exploited in the wild? | FIRST EPSS |
| **CISA KEV** (已知被利用漏洞目录) | Is it confirmed exploited? | CISA KEV catalog |
| **Reachability** | Does *my* code path touch the vulnerable function? | SCA reachability, e.g., `osv-scanner` call analysis |

A CVE with CVSS 9.8 that is unreachable and unexploited can often wait behind a CVSS 7.5 that is on the KEV list and reachable in your code.

> 简注：优先级排序 = CVSS × 实际利用概率 × 代码可达性，三者叠加才是真实的修复顺序。

---

## 5. Hardening the Dependency Lifecycle

Defense is a set of gates along the dependency lifecycle, not a single scanner.

### 5.1 Ingestion Controls (Before Code Enters)

- **Private registry proxy** (私有仓库代理): Route all package downloads (npm, PyPI, Maven, Go) through an internal proxy such as Artifactory or Nexus. Only allowlisted, scanned versions are served.
- **Namespace reservation** (命名空间预留): Register your internal package names on public registries to kill dependency confusion.
- **Version pinning** (版本锁定): Commit lockfiles; use exact versions for direct dependencies. No bare `^` or `latest` in CI.

### 5.2 In-Pipeline Controls (When Code Builds)

```yaml
# Example: GitHub Actions gate for a Node.js project
- name: Install exact versions from lockfile
  run: npm ci                      # never: npm install
- name: SCA scan (fail on KEV / high)
  run: osv-scanner --lockfile=package-lock.json || exit 1
- name: Generate SBOM
  run: syft dir:. -o cyclonedx-json > sbom.json
- name: Sign artifact + SBOM
  run: cosign sign-blob --key cosign.key sbom.json
```

### 5.3 Runtime Controls (When Code Ships)

- **Signature verification** (签名校验): Verify images with Sigstore/cosign at admission time.
- **Vendor trust review** (供应商信任审查): For commercial software, require SBOMs contractually, ask how updates are signed, and monitor vendor security channels.
- **Behavioral monitoring** (行为监控): A trojanized update behaves differently — unexpected child processes, new outbound C2, credential access. Feed EDR/SIP with baselines for legitimate build and update processes.

> 简注：入口收紧、构建门禁、运行时监控——三道闸门缺一不可，单一扫描器挡不住 `xz` 式的长期潜伏。

---

## 6. A Practical Vendor Trust Checklist

For third-party software and SaaS vendors, a lightweight but effective questionnaire:

| # | Question | Why It Matters |
|---|----------|----------------|
| 1 | Can you provide an SBOM for each release? | Enables rapid impact analysis |
| 2 | How are builds and updates signed? How do we verify? | Anti-SolarWinds / anti-tamper |
| 3 | Do you run SCA + SAST in your CI/CD? Show the policy. | Their hygiene becomes your risk |
| 4 | What is your disclosed-vulnerability SLA (e.g., 90-day fix)? | Sets patch expectations |
| 5 | Do you have a coordinated disclosure program (security.txt)? | Signals maturity |
| 6 | Who are *your* critical sub-suppliers? | Third-party risk is recursive |
| 7 | Have you had a recent third-party audit (SOC 2 / ISO 27001)? | Independent assurance |

> 简注：供应商审查不必追求完美问卷，这 7 个问题能筛掉绝大多数高风险供应商。

---

## 甲方视角思考 (Enterprise Defender Lens)

- **先做依赖资产盘点**：对内部核心系统（病理系统对接服务、内部 Web 平台）跑一次 Syft/Trivy 生成 SBOM，把"未知依赖"变成可查询清单，为下次 Log4Shell 类事件争取分钟级响应。
- **SCA 接入 CI 门禁**：新项目和重点项目先行，规则先设为"KEV 或 High 且可达才阻断"，避免一上来就淹没开发团队。
- **NPM/PyPI 走私有代理**：哪怕只覆盖新项目，也能同时解决 typosquatting 与依赖混淆两大入口。
- **把 SBOM 要求写进供应商合同**：与态势感知、DLP、EDR 厂商续保谈判时加入 SBOM 交付与签名更新条款，把信任变成可验证的义务。

---

## Key Terms

| English Term | 中文 | Notes |
|--------------|------|-------|
| Software supply chain | 软件供应链 | 代码从编写、构建到分发的全链路 |
| SBOM | 软件物料清单 | Software Bill of Materials，组件及其依赖的机器可读清单 |
| SCA | 软件成分分析 | Software Composition Analysis，识别并分析开源组件风险 |
| Transitive dependency | 传递依赖 | 依赖的依赖，常是盲区所在 |
| Typosquatting | 包名抢注 | 仿冒热门包名诱导开发者安装恶意包 |
| Dependency confusion | 依赖混淆 | 利用包管理器默认解析行为注入同名恶意包 |
| Version pinning | 版本锁定 | 固定依赖版本，禁止自动升级 |
| Lockfile | 锁定文件 | 如 package-lock.json，精确记录依赖树 |
| Private registry proxy | 私有仓库代理 | 统一管控第三方包下载的内部代理 |
| Namespace reservation | 命名空间预留 | 在公共仓库提前注册内部包名防止混淆 |
| Reachability analysis | 可达性分析 | 判断漏洞代码是否真的被业务代码调用 |
| EPSS | 漏洞利用预测评分 | Exploit Prediction Scoring System，预测野外利用概率 |
| CISA KEV | 已知被利用漏洞目录 | Known Exploited Vulnerabilities，确认在野利用 |
| CVSS | 通用漏洞评分系统 | Common Vulnerability Scoring System，理论严重度评分 |
| SPDX | SPDX 格式 | Linux Foundation 的 SBOM 标准，ISO/IEC 5962 |
| CycloneDX | CycloneDX 格式 | OWASP 主导的安全导向 SBOM 标准 |
| PURL | 包 URL 标识符 | package URL，组件的唯一标识格式 |
| Cosign | 容器签名工具 | Sigstore 出品的制品签名与校验工具 |
| Vendor trust review | 供应商信任审查 | 对第三方软件供应商的安全尽职调查 |
| Protestware | 抗议式投毒 | 维护者主动破坏或武器化自己的包 |
| Coordinated disclosure | 协同披露 | 漏洞报告者与厂商协调后统一公开的流程 |
| Staged rollout | 分阶段发布 | 先灰度后全量，限制恶意更新爆炸半径 |

---

## 明日预告

**Day 56 — Securing AI and LLM Applications: Prompt Injection, Data Leakage, and Model Supply Chain**

明天进入 AI 安全专题：理解 **prompt injection**（提示词注入）的直接与间接攻击面、LLM 应用的**数据泄漏**风险（训练数据、上下文记忆、日志外泄）、以及 **model supply chain**（模型供应链）——Hugging Face 投毒与模型文件反序列化风险。这也呼应甲方视角下 AI 安全能力建设的落地路径。
