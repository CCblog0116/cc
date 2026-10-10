---
title: "Day 20 — Software and Data Integrity Failures: Trust, But Verify"
date: 2026-09-02
tags:
  - daily
  - security
  - english
description: "Every modern organization relies on automation: automated builds, automated updates, automated data feeds, automated backups. That automation only wor"
---

**Date:** 2026-09-02 | **Difficulty:** ★★☆☆☆ Conceptual | **Source:** OWASP Top 10:2021 A08 | **Link:** [OWASP A08:2021](https://owasp.org/Top10/A08_2021-Software_and_Data_Integrity_Failures/)

---

## Why This Matters

Every modern organization relies on **automation**: automated builds, automated updates, automated data feeds, automated backups. That automation only works if the code and data flowing through it are exactly what you expect them to be. When an attacker can alter software or data in transit, they do not need to steal passwords or exploit a web vulnerability — they simply replace what you trust.

OWASP ranks **software and data integrity failures** as the **#8 risk** in its 2021 Top 10. This category covers two related problems: applications that make security decisions based on untrusted data without verification, and applications that receive untrusted updates, packages, or payloads without checking their origin and integrity.

The headline example is **SolarWinds Orion** in 2020: attackers compromised the build environment and inserted a backdoor into a legitimate software update. Roughly 18,000 customers, including US government agencies, downloaded and installed a signed update that contained malicious code. The update mechanism itself was the attack vector.

> 供应链攻击最可怕的不是漏洞，而是“信任”本身被武器化：你主动去下载、安装、执行被篡改的代码。

---

## What Counts as an Integrity Failure?

OWASP A08 groups together weaknesses where the application trusts data or code that should have been verified. You have an integrity problem if your application does any of the following:

- Installs **software updates** or **plugins** without **code signing** （代码签名） verification.
- Uses **deserialization** （反序列化） on data from untrusted sources, such as user input or external APIs.
- Relies on **unencrypted or unsigned integrity checks** like plain MD5/SHA-1 hashes that can be recalculated by an attacker.
- Pulls dependencies from repositories without **checksum** （校验和） or signature validation.
- Accepts **plugins**, **extensions**, or **modules** from untrusted marketplaces.
- Executes **CI/CD pipeline** （持续集成/持续部署流水线） scripts without pinning exact dependency versions or verifying build artifacts.
- Fails to validate **digital signatures** on configuration, firmware, or data imports.

A useful way to think about it: integrity is the question, *"Has this been tampered with since it was created?"* If you cannot answer that question with strong cryptography, you have a failure.

> 完整性问题的核心就是一句话：你凭什么相信这份代码或数据没有被中途改动过？

---

## Common Attack Patterns

### 1. Compromised Software Updates

Attackers target the **software supply chain** （软件供应链） by injecting malicious code into legitimate update channels. Because the update is signed or delivered over HTTPS, victims trust it. The attack succeeds not because users are careless, but because the vendor's build or signing process was breached.

Notable cases include **SolarWinds Orion**, **Codecov**, and **3CX**. In each case, the malicious payload reached end users through the same trusted path used for normal updates.

> 被篡改的软件更新最难防御，因为它走的是你最信任的通道。

### 2. Dependency Confusion and Typosquatting

Developers often install packages from public repositories like **PyPI**, **npm**, or **Maven Central**. Attackers publish malicious packages with names that look legitimate — either a **typosquatting** （名称仿冒） name like `reqeusts` instead of `requests`, or a private package name that takes advantage of **dependency confusion** （依赖混淆） when a public package has the same name as an internal one.

If the build tool checks for public packages before private ones, it downloads and executes the attacker's code during the build.

> 依赖混淆攻击利用的是包管理器“先公后私”的查询顺序，而不是代码本身的漏洞。

### 3. Insecure Deserialization

Many applications serialize objects into a binary or text format for storage or transmission, then **deserialize** （反序列化） them later. If an attacker can modify the serialized object and the application does not validate it, they can often execute arbitrary code, escalate privileges, or bypass authentication.

This is especially dangerous in Java, .NET, PHP, and Python applications that use native serialization formats. The vulnerability is not in the library itself; it is in treating untrusted input as trusted objects.

> 不安全的反序列化本质上是把外部数据当作内部对象直接执行，信任边界被完全跳过。

### 4. Weak or Missing Integrity Verification

Some applications check integrity using weak **hash functions** （哈希函数） like MD5 or SHA-1, or they store the hash next to the file without protecting it. An attacker who can replace the file can usually replace the hash too, defeating the check.

Strong integrity requires **digital signatures** using asymmetric cryptography: the vendor signs with a private key, and the verifier checks with a public key that is stored separately and protected from tampering.

> 真正的完整性校验必须分离密钥和待校验内容，否则只是“把锁和钥匙放在一起”。

---

## Defense: Verify at Every Handoff

OWASP recommends treating every external input, update, and dependency as potentially untrusted until proven otherwise:

| Control | What to Do | Why It Helps |
|---------|-----------|--------------|
| **Code signing** | Verify digital signatures on software, updates, and plugins before execution | Confirms the payload came from the expected publisher and was not modified |
| **Dependency pinning + checksums** | Pin exact versions in lock files and verify hashes during install | Prevents silent substitution of packages |
| **Private registry + namespace** | Host approved packages internally and configure tools to prefer them | Blocks dependency confusion and typosquatting |
| **SBOM** | Maintain a **Software Bill of Materials** （软件物料清单） for every release | Gives visibility into what components are actually deployed |
| **CI/CD hardening** | Isolate build environments, require **multi-person review** for pipeline changes, sign artifacts, and store signing keys in a **Hardware Security Module (HSM)** （硬件安全模块） or KMS | Prevents build-pipeline compromise from poisoning every downstream customer |
| **Avoid native deserialization** | Use safe data formats like JSON with strict schemas; avoid native object serialization | Removes a common remote-code-execution path |
| **Signature on serialized data** | If serialization is unavoidable, sign payloads and reject anything that fails verification | Ensures attackers cannot craft malicious objects |
| **Immutable build artifacts** | Treat build outputs as read-only once produced; detect unexpected changes | Makes tampering visible rather than silent |

> 对甲方而言，CI/CD 和制品库的安全级别应该等同于生产环境，因为被攻破一次就会影响所有发布产物。

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| Software and Data Integrity Failures | 软件与数据完整性失效 | OWASP Top 10 A08:2021 |
| Code Signing | 代码签名 | 用私钥对软件或更新包签名，验证来源和完整性 |
| Digital Signature | 数字签名 | 基于非对称密码学的身份和完整性证明 |
| Checksum | 校验和 | 用于检测文件是否被改动的哈希值 |
| Hash Function | 哈希函数 | 把任意长度输入映射为固定长度摘要的算法 |
| Software Bill of Materials (SBOM) | 软件物料清单 | 列出软件所有组成成分及其版本的清单 |
| Software Supply Chain | 软件供应链 | 从源代码到最终交付物所经过的所有环节 |
| CI/CD Pipeline | 持续集成/持续部署流水线 | 自动化构建、测试、发布的流程 |
| Deserialization | 反序列化 | 把存储/传输格式还原为内存对象的过程 |
| Insecure Deserialization | 不安全的反序列化 | 对不可信数据执行反序列化导致的严重漏洞 |
| Dependency Confusion | 依赖混淆 | 利用公私仓库同名包导致下载恶意依赖 |
| Typosquatting | 名称仿冒 | 注册与流行包名拼写相近的恶意包名 |
| Hardware Security Module (HSM) | 硬件安全模块 | 用于安全生成、存储和管理密钥的物理设备 |
| Immutable Artifact | 不可变制品 | 构建完成后禁止修改，确保可审计和可复现 |

---

## 甲方视角思考

1. **把构建和发布环境纳入等保和基线管理** — CI/CD 服务器、制品库、签名密钥的权限和审计，应该与生产服务器同等对待。
2. **优先落地 SBOM 和依赖清单** — 先知道用了什么，才能谈得上补什么；配合 SCA 工具形成闭环。
3. **关键系统强制校验更新签名** — 终端安全、EDR、VPN 客户端、远程工具等必须在安装前验证发布者签名，防止供应链投毒。
4. **反序列化接口纳入 SDL 必审点** — 对历史系统做专项排查，优先把 Java/.NET/Python 原生反序列化点收敛到 JSON 等安全格式。

---

## Tomorrow — Day 21 Preview

**Security Logging and Monitoring Failures (OWASP A09)** — why "we will check the logs later" is a dangerous mindset, what **SOC**, **SIEM**, and **detection engineering** mean, and how poor logging turns breaches into months-long incidents.
