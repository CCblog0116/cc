---
title: "Day 33 — CI/CD and DevSecOps Pipeline Security"
date: 2026-09-18
tags:
  - daily
  - security
  - english
description: "⭐ Difficulty: ★★★☆☆ Technical"
---

📅 **Date:** September 18, 2026  
⭐ **Difficulty:** ★★★☆☆ Technical  
📰 **Source:** OWASP DevSecOps Guideline + NIST SP 800-218 + SANS SEC540  
🔗 **Reference:** [https://owasp.org/www-project-devsecops-guideline/latest/](https://owasp.org/www-project-devsecops-guideline/latest/)

---

## 1. What Is a CI/CD Pipeline?

A **CI/CD pipeline**（持续集成/持续交付流水线） automates the steps between writing code and running it in production. **Continuous Integration (CI)**（持续集成） merges code changes frequently and runs automated tests. **Continuous Delivery/Deployment (CD)**（持续交付/持续部署） pushes validated code closer to production, sometimes automatically.

Because the pipeline touches source code, build tools, artifacts, and deployment credentials, it has become a high-value target. If an attacker compromises the pipeline, they can inject malicious code into every application the pipeline builds. 简短中文提醒：流水线被攻陷相当于“从源代码端污染生产环境”，其影响范围远大于单个应用漏洞。

---

## 2. Version Control Risks

**Version control systems (VCS)**（版本控制系统） like Git host the source of truth for modern software. Common risks include:

- **Hardcoded secrets**（硬编码密钥） committed directly into repositories — API keys, database passwords, and cloud credentials
- **Weak branch protection**（弱分支保护） allowing anyone to push to the main branch without review
- **Forgotten forks and mirrors**（被遗忘的分支与镜像） that still contain old, vulnerable code or exposed credentials
- **Overprivileged integrations**（过度授权的集成） such as CI apps with full repository access

Defense starts with **branch protection rules**（分支保护规则） requiring pull-request reviews, signed commits, and status checks before merging. Secrets should never live in Git; they should be injected at runtime from a **secrets manager**（密钥管理器） or vault.

---

## 3. Secrets Management in Pipelines

CI/CD jobs often need credentials to deploy to cloud platforms, sign artifacts, or push container images. These credentials are attractive because they usually have broad permissions and are long-lived.

Best practices include:

| Practice | Why It Helps |
|----------|--------------|
| Use short-lived tokens | Reduces the window of exposure if a credential leaks |
| Scope tokens to the minimum required permissions | Follows the principle of **least privilege**（最小权限原则） |
| Rotate credentials automatically | Limits the lifetime of any single secret |
| Never print secrets in logs | Prevents accidental exposure in build output |
| Store secrets in a dedicated vault | Centralizes audit, rotation, and access control |

Modern platforms support **OpenID Connect (OIDC)**（OpenID Connect，一种身份联合协议） federation, allowing CI runners to authenticate to cloud providers without storing long-term access keys at all.

---

## 4. Static and Dynamic Application Security Testing

**SAST**（静态应用安全测试，Static Application Security Testing） analyzes source code for vulnerabilities without running the program. It catches issues like **SQL injection**（SQL 注入） patterns, hardcoded credentials, and unsafe deserialization early.

**DAST**（动态应用安全测试，Dynamic Application Security Testing） tests a running application from the outside, simulating real attacker behavior. It finds runtime issues such as exposed endpoints, misconfigured headers, and authentication weaknesses.

A mature pipeline runs SAST on every pull request, DAST against staging or production-like environments, and fails the build only on high-confidence findings to avoid **alert fatigue**（告警疲劳）.

---

## 5. Dependency and Supply-Chain Scanning

Modern projects import hundreds of third-party libraries. A single compromised dependency can introduce a **backdoor**（后门） into every build. **Software Composition Analysis (SCA)**（软件成分分析） tools scan dependencies for known CVEs, license risks, and malicious packages.

Key controls include:

- Lock files (`package-lock.json`, `Pipfile.lock`, `go.sum`) to ensure reproducible builds
- Private registry proxies to reduce **dependency confusion**（依赖混淆） and **typosquatting**（域名/包名抢注仿冒） attacks
- **SBOM**（软件物料清单，Software Bill of Materials） generation for every release
- Vulnerability notifications and automated patch workflows

Supply-chain attacks such as the **SolarWinds**（SolarWinds 供应链攻击事件） and **Codecov**（Codecov 供应链攻击事件） incidents showed that build and test tools themselves can be the entry point, not just application dependencies.

---

## 6. Infrastructure as Code Security

**Infrastructure as Code (IaC)**（基础设施即代码） defines cloud resources in files rather than clicking through consoles. It enables version control and repeatability, but it can also propagate misconfigurations at scale.

Common IaC risks include:

- Storage buckets opened to the public
- Security groups allowing `0.0.0.0/0` on sensitive ports
- Hardcoded credentials in Terraform variables or CloudFormation templates
- Missing encryption settings for databases and disks

**IaC scanning**（IaC 扫描） tools check templates before deployment, flagging violations of security baselines. Like SAST, IaC scanning belongs early in the pipeline to catch expensive cloud mistakes before resources are provisioned.

---

## 7. Build Agent Hardening

A **build agent**（构建代理） or runner is the machine that executes CI/CD jobs. If it is compromised, every artifact it produces is suspect. Hardening guidelines include:

- Run each job in an isolated, ephemeral environment
- Do not share build agents between trusted and untrusted projects
- Keep runner software and base images patched
- Disable **privileged containers**（特权容器） unless absolutely necessary
- Monitor build logs for suspicious network connections or unexpected package downloads

Many organizations now use **container-based runners**（基于容器的运行器） that start fresh for every job, reducing the risk of leftover secrets or malware from a previous build.

---

## 8. A Minimal DevSecOps Pipeline

A practical pipeline might look like this:

```
Developer commits code
      ↓
Git hook / PR scan (secrets, SAST)
      ↓
Code review and merge to main
      ↓
Build + unit tests
      ↓
SAST + SCA + IaC scan
      ↓
Build container image and sign it
      ↓
DAST against staging
      ↓
Deploy to production with signed artifacts
      ↓
Runtime monitoring and rollback
```

The goal of **DevSecOps**（开发安全运营一体化） is not to add more tickets but to make security checks fast, automated, and embedded into the developer workflow. 简短中文提醒：安全左移（shift-left）的核心不是把责任推给开发，而是在最早、修复成本最低的阶段发现问题。

---

## 甲方视角思考

- **把 CI/CD 纳入资产台账**：Runner、镜像仓库、构建缓存都是攻击面，资产盘点不应只统计生产主机。
- **强制分支保护与合并评审**：这是成本最低、效果最明显的代码防篡改措施。
- **推进 SBOM 与制品签名**：一旦发生供应链事件，可快速定位受影响的应用版本。
- **联动态势感知平台**：将构建日志、镜像扫描结果接入 SIP，便于发现异常外联或敏感信息泄露。

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| CI/CD pipeline | 持续集成/持续交付流水线 | 自动化构建、测试、部署流程 |
| Continuous Integration (CI) | 持续集成 | 频繁合并代码并自动测试 |
| Continuous Delivery/Deployment (CD) | 持续交付/持续部署 | 自动将通过验证的代码发布 |
| Version Control System (VCS) | 版本控制系统 | 如 Git，代码的唯一可信源 |
| Hardcoded secrets | 硬编码密钥 | 直接写入代码的敏感凭证 |
| Branch protection | 分支保护 | 防止未经评审直接推送主分支 |
| Least privilege | 最小权限原则 | 仅授予完成任务所需的最小权限 |
| Secrets manager / vault | 密钥管理器/保险库 | 集中存储和管理敏感凭证 |
| OpenID Connect (OIDC) | OpenID Connect | 身份联合协议，可实现无长期密钥的云认证 |
| SAST | 静态应用安全测试 | 不运行程序，直接分析源码 |
| DAST | 动态应用安全测试 | 在应用运行时进行外部测试 |
| Alert fatigue | 告警疲劳 | 过多低价值告警导致真实问题被忽略 |
| SCA | 软件成分分析 | 扫描依赖库的安全与合规风险 |
| Backdoor | 后门 | 绕过正常认证的隐蔽入口 |
| Dependency confusion | 依赖混淆 | 利用同名公共包替换私有包 |
| Typosquatting | 域名/包名抢注仿冒 | 通过近似名称诱导安装恶意包 |
| SBOM | 软件物料清单 | 记录软件组件及其依赖关系 |
| SolarWinds / Codecov | SolarWinds / Codecov 事件 | 著名供应链攻击案例 |
| Infrastructure as Code (IaC) | 基础设施即代码 | 用代码定义和管理云资源 |
| Build agent / runner | 构建代理/运行器 | 执行 CI/CD 任务的机器或容器 |
| Privileged container | 特权容器 | 拥有接近宿主机权限的容器 |
| DevSecOps | 开发安全运营一体化 | 将安全嵌入 DevOps 流程 |
| Shift-left | 安全左移 | 在软件生命周期早期引入安全 |

---

## 🌅 Tomorrow’s Preview — Day 34

**Topic:** Secrets Management and Credential Hygiene in Enterprise Environments  
**Focus:** Vault architecture, secret rotation, service-account best practices, detecting leaked credentials, and integrating credential hygiene with SOC workflows.
