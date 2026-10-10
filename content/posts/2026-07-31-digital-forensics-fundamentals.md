---
title: "Day 38 — Digital Forensics Fundamentals"
date: 2026-07-31
tags:
  - daily
  - security
  - english
description: "Unlike incident response, which prioritizes restoring service quickly, forensics prioritizes evidentiary soundness 证据有效性. The two disciplines often co"
---

**Date:** Wednesday, September 23, 2026
**Difficulty:** ★★★☆☆ Technical
**Source:** NIST SP 800-86 — *Guide to Integrating Forensic Techniques into Incident Response*
**Link:** https://csrc.nist.gov/publications/detail/sp/800-86/final

---

## 1. What Is Digital Forensics?

**Digital forensics** (数字取证) is the application of science to the identification, collection, examination, and analysis of data while preserving the **integrity** (完整性) of the information and maintaining a strict **chain of custody** (证据监管链) for the data. In plain terms: find out what happened, prove it, and don't contaminate the evidence while doing so.

Unlike incident response, which prioritizes restoring service quickly, forensics prioritizes **evidentiary soundness** (证据有效性). The two disciplines often conflict — rebooting a compromised server may restore business, but it also destroys volatile memory evidence. 取证优先考虑证据不被破坏，而不是服务恢复速度，两者经常冲突。

---

## 2. The Four Phases of a Forensic Investigation

NIST SP 800-86 defines a four-phase process that applies to any evidence source:

| Phase | Goal | Key Activities |
|-------|------|----------------|
| **Collection** (采集) | Identify, label, record, and acquire data | Document hardware, photograph setup, take hashes |
| **Examination** (检验) | Process and extract relevant data | Forensic tools, keyword search, file carving |
| **Analysis** (分析) | Interpret and correlate findings | Build timeline, attribute activity, test hypotheses |
| **Reporting** (报告) | Communicate results | Written report, executive summary, evidence list |

Skipping the collection discipline is the most common failure: an examiner who mounts a suspect disk directly on a Windows workstation changes hundreds of files the moment it boots. 直接挂载嫌疑磁盘会改变大量文件元数据，这是最常见的取证事故。

---

## 3. Acquisition: Order of Volatility

When you can only take some things, take the most fragile first. The classic **order of volatility** (易失性顺序) from RFC 3227 still governs every acquisition plan:

1. **CPU registers and cache** — gone in microseconds
2. **RAM / memory** — gone at power-off (内存镜像，断电即失)
3. **Network state** — connections, ARP tables
4. **Running processes** — process lists, open handles
5. **Disk** — persistent but large
6. **Backups and archives** — slowest but most durable

Memory acquisition has become non-negotiable. **Ransomware** (勒索软件) keys, injected code, and credential theft all live in RAM and vanish on reboot. Tools like **WinPMEM** (Windows 内存采集驱动) or **LiME** (Linux Memory Extractor) capture a full memory image before anything else touches the system. 勒索软件的密钥和注入代码只存在于内存中，重启就没了，所以内存镜像必须最先做。

---

## 4. Integrity: Hashing and Chain of Custody

Every piece of evidence must be provably unmodified. This is achieved with two controls:

- **Cryptographic hashing** (密码学哈希): compute **MD5/SHA-256** hashes at acquisition and re-verify before every analysis session. A single bit change produces a different hash.
- **Chain of custody** (证据监管链): a signed log recording who handled the evidence, when, where, and why. One gap in the chain and opposing counsel will argue the evidence was tampered with.

The gold standard is a **forensic image** (取证镜像) — a **bit-for-bit copy** (逐位复制) of the original media, typically in **E01 (EnCase)** or **RAW (dd)** format, acquired through a **write blocker** (写保护器) that physically prevents any write to the source disk. 原始盘永远只读，所有分析都在镜像副本上进行。

---

## 5. Timeline Analysis: The Investigator's Spine

Once evidence is secured, the most powerful analytical technique is **timeline analysis** (时间线分析). By extracting and normalizing timestamps from the **file system** (文件系统), **registry** (注册表), **event logs** (事件日志), and **browser history** (浏览器历史), the examiner reconstructs the attacker's story: initial access, privilege escalation, lateral movement, exfiltration.

Key artifacts on a Windows system:

| Artifact | What It Reveals |
|----------|-----------------|
| **MFT** (Master File Table, 主文件表) | File create/modify/access times |
| **USN Journal** (更新序列号日志) | File system change history |
| **Prefetch** (预取文件) | Program execution history |
| **Event Logs** (4624/4625/4720) | Logons, failed attempts, account creation |
| **Amcache/ShimCache** | Program execution and binary metadata |
| **SRUM** (系统资源使用监测) | Network usage per application |

Watch for **anti-forensics** (反取证): **timestomping** (时间戳伪造) alters file timestamps to hide activity, so cross-validate MFT times against $LogFile and the USN Journal — a single artifact's clock can lie, but consistent multi-artifact timelines rarely do. 单一工件的时间可以伪造，多个工件交叉验证后谎言很难维持。

---

## 6. Memory and Disk Forensics

- **Memory forensics** (内存取证) with the **Volatility** (开源内存分析框架) framework can extract running processes, injected code, network connections, cached credentials, and even decrypted ransomware keys — all from a RAM image.
- **Disk forensics** (磁盘取证) combines file system analysis with **file carving** (文件雕刻/ carving — 从原始数据中恢复文件), recovering deleted files from unallocated space (未分配空间) where the content remains until overwritten.

A practical rule: **start in memory, finish on disk**. Memory tells you *what is happening now*; disk tells you *what happened and when it started*. 内存告诉你现在正在发生什么，磁盘告诉你过去发生了什么。

---

## 7. 甲方视角思考

- 先定预案再谈取证：把"先内存镜像、后关机"写进应急响应流程，避免一线运维习惯性重启毁证。
- 结合态势感知平台 (SIP)：取证时间线与 SIP 告警双向印证，告警定位可疑主机，取证还原攻击路径。
- 关键服务器预留采集能力：提前部署 WinPMEM/LiME 与日志集中化，事发时不必"现场找工具"。
- 证据留存兼顾合规：等保三级要求日志留存不少于 6 个月，镜像与哈希记录同步归档。

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| Digital forensics | 数字取证 | Science of identifying, collecting, and analyzing digital evidence |
| Chain of custody | 证据监管链 | Signed log of everyone who handled the evidence |
| Order of volatility | 易失性顺序 | Acquire most fragile data first (RAM before disk) |
| Forensic image | 取证镜像 | Bit-for-bit copy of original media (E01/RAW) |
| Write blocker | 写保护器 | Hardware device preventing writes to source disk |
| Hashing | 哈希 | MD5/SHA-256 to prove evidence integrity |
| Timeline analysis | 时间线分析 | Correlating timestamps to reconstruct attacker activity |
| MFT | 主文件表 | NTFS record of all files and timestamps |
| USN Journal | 更新序列号日志 | NTFS change journal |
| Prefetch | 预取文件 | Windows artifact showing program execution |
| Amcache / ShimCache | 执行痕迹工件 | Registry artifacts proving binary execution |
| Timestomping | 时间戳伪造 | Anti-forensic technique altering file times |
| Anti-forensics | 反取证 | Techniques designed to hinder investigation |
| File carving | 文件雕刻 | Recovering files from raw unallocated space |
| Memory forensics | 内存取证 | Analyzing RAM images (e.g., Volatility) |
| WinPMEM / LiME | 内存采集工具 | Windows / Linux memory acquisition drivers |
| Volatility | 开源内存分析框架 | De facto standard for RAM analysis |
| Evidentiary soundness | 证据有效性 | Evidence acceptable in legal/administrative proceedings |

---

## Tomorrow's Preview

**Day 39 — Malware Analysis Fundamentals (恶意软件分析基础):** static vs dynamic analysis, sandboxing, unpacking, and the malware triage workflow — how a sample becomes detection rules.
