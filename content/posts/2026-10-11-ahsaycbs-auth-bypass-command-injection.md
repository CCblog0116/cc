---
title: "2026-10-11 — AhsayCBS Flaws Chained for Webshells and Cryptomining"
date: 2026-10-11
tags:
  - daily
  - security
  - english
  - vulnerability
  - cryptojacking
  - incident-response
description: Threat actors are chaining an authentication bypass and a command injection in AhsayCBS backup servers to drop webshells and XMRig miners disguised as Microsoft Edge.
---

> [!abstract] TL;DR
> Attackers are actively chaining two AhsayCBS backup-platform flaws — an authentication bypass (CVE-2026-105133) and an OS command injection (CVE-2026-105134) — to deploy JSP webshells and XMRig miners masquerading as Microsoft Edge, with no fully working patch available yet.

## Original Article

Threat actors have been observed exploiting two recently disclosed vulnerabilities in the AhsayCBS enterprise backup management platform to seize control of affected servers, plant webshells, and install cryptocurrency miners.

The first flaw, **CVE-2026-105133** (CVSS v4: 5.5), is an improper authentication vulnerability in the `checkSysPwd()` function of the `ApiStructsAction.java` component. The second, **CVE-2026-105134** (CVSS v4: 9.3), is an operating system command injection in the Replication Receiver component. Chained together, they let a remote, unauthenticated attacker bypass the login check and execute arbitrary commands on the host — a classic and devastating exploit chain.

According to Huntress, active exploitation began on October 7, 2026, at 11:20 p.m. UTC, only three days after the CVE identifiers were published. At least five organizations were hit within the first 24 hours, turning these into de facto zero-days: although the vendor's release notes claim version 10.3.4 fixes the issues, Huntress confirmed that version is still vulnerable.

Post-exploitation activity is methodical. Attackers run reconnaissance, drop JSP webshells for persistence, and install the XMRig cryptominer under the name `edge.exe` to impersonate the Microsoft Edge browser. Persistence is achieved through a service named `MicrosoftEdgeUpdateSvc`, built with a modified NSSM utility. In at least one incident, the attackers abused the legitimate Windows binary `certutil.exe` to download the vulnerable `WinRing0x64.sys` driver — a bring-your-own-vulnerable-driver (BYOVD) technique used to gain kernel-level access and optimize mining.

The most curious artifact is `Taskgmr.ps1`, a PowerShell script suspected to be AI-assisted. It monitors Windows Task Manager: if a victim opens Task Manager, mining stops immediately to avoid suspicion; if Task Manager is left open past 6 p.m. for more than an hour overnight, the script kills it. This anti-analysis behavior shows how commodity malware is becoming context-aware.

Backup servers are high-value targets: they hold privileged credentials, sensitive data, and network paths into production systems. A compromised backup platform can also undermine an organization's last line of defense against ransomware.

Mitigation (no reliable patch yet):
- Restrict the AhsayCBS management interface to trusted IPs or VPN-only access.
- Hunt for indicators: `edge.exe` miners, `MicrosoftEdgeUpdateSvc` service, `Taskgmr.ps1`, `WinRing0x64.sys`, unexpected JSP files.
- If compromise is confirmed, rebuild the host from a known-safe backup rather than cleaning in place.

Source: https://thehackernews.com/2026/10/attackers-exploit-ahsaycbs-flaws-to.html

## Key Vocabulary

| Word | Meaning | 中文 |
| ---- | ------- | ---- |
| authentication bypass | a flaw that lets attackers skip identity verification | 认证绕过 |
| command injection | inserting OS commands into input that the server executes | 命令注入 |
| exploit chain | combining multiple vulnerabilities into one attack path | 漏洞利用链 |
| webshell | a malicious script uploaded to a server for remote control | WebShell（网页后门） |
| cryptojacking | hijacking computing resources to mine cryptocurrency | 加密劫持/挖矿劫持 |
| masquerade | to disguise malware as a legitimate program | 伪装/冒充 |
| persistence | techniques that keep access after reboot or cleanup | 持久化 |
| BYOVD | Bring Your Own Vulnerable Driver, abusing signed drivers for kernel access | 自带漏洞驱动攻击 |
| zero-day | a flaw exploited before an effective patch exists | 零日漏洞 |
| reconnaissance | gathering information about a target before/after intrusion | 侦察 |
| LOLBin | legitimate system binary abused for malicious purposes | 被滥用的系统合法程序 |
| anti-analysis | behaviors designed to evade detection or inspection | 反分析 |

## Sentence Patterns

1. **"Threat actors have been observed exploiting ... to ..."**
   - *Threat actors have been observed exploiting unpatched VPN flaws to deploy ransomware.*

2. **"Chained together, the vulnerabilities allow an unauthenticated attacker to ..."**
   - *Chained together, the vulnerabilities allow an unauthenticated attacker to achieve remote code execution.*

3. **"The miner masquerades as ... to fly under the radar."**
   - *The miner masquerades as a system update service to fly under the radar.*

4. **"In the absence of a patch, organizations are advised to ..."**
   - *In the absence of a patch, organizations are advised to restrict access to trusted IP addresses.*

5. **"... is a high-value target because it holds privileged access to ..."**
   - *A backup server is a high-value target because it holds privileged access to production systems.*

## 中文摘要

攻击者正组合利用 AhsayCBS 备份平台的认证绕过（CVE-2026-105133）与命令注入（CVE-2026-105134）漏洞，在野外部署 JSP WebShell 和伪装成 edge.exe 的 XMRig 挖矿程序，并利用疑似 AI 生成的 PowerShell 脚本躲避任务管理器检测。官方 10.3.4 版本仍未修复，等同零日。建议限制管理接口访问并排查失陷指标。
