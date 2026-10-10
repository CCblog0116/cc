---
title: "Day 35 — Email Security: SPF, DKIM, and DMARC"
date: 2026-09-20
tags:
  - daily
  - security
  - english
description: "📅 Date: 2026-09-20 | 🎯 Difficulty: ★★★☆☆ | 📖 Sources: NIST SP 800-177, DMARC.org, Google Workspace Admin Help | ⏱️ 15 min read"
---

📅 Date: 2026-09-20 | 🎯 Difficulty: ★★★☆☆ | 📖 Sources: NIST SP 800-177, DMARC.org, Google Workspace Admin Help | ⏱️ 15 min read

---

## 1. Why Email Security Still Matters in 2026

Despite decades of evolution, email remains the **primary attack vector** for cybercriminals. According to industry reports, over **90% of targeted attacks** begin with a phishing email, and **Business Email Compromise (BEC, 商业邮件欺诈)** losses continue to reach billions annually. The problem is not that email protocols are broken — it is that the original **SMTP (Simple Mail Transfer Protocol, 简单邮件传输协议)** design trusts senders by default. SPF, DKIM, and DMARC were created to close that trust gap.

Email security is especially critical for enterprises because a single successful **spear-phishing (鱼叉式钓鱼)** message can lead to credential theft, malware deployment, or a full-scale **ransomware (勒索软件)** incident.

---

## 2. SPF — Who Is Allowed to Send?

**SPF (Sender Policy Framework, 发送方策略框架)** is a DNS-based allowlist. A domain owner publishes a **DNS TXT record (DNS文本记录)** listing which IP addresses or hosts are authorized to send email on behalf of that domain. When a receiving **MTA (Mail Transfer Agent, 邮件传输代理)** gets an email, it queries the sender domain's SPF record and checks whether the originating IP is on the list.

**Example SPF record:**
```
v=spf1 include:_spf.google.com include:sendgrid.net ip4:203.0.113.0/24 -all
```

- `v=spf1` — Version identifier.
- `include:` — Delegates to another domain's SPF record.
- `ip4:` — Explicit IPv4 range allowed to send.
- `-all` — **Hard fail (硬失败)**: reject everything else.
- `~all` — **Soft fail (软失败)**: accept but mark as suspicious.
- `+all` — Dangerous; allows anyone to send.

**SPF's Limitation**: SPF validates the **envelope From (信封发件人)**, also known as the `MAIL FROM` address used in the SMTP transaction. It does *not* validate the **Header From (邮件头发件人)** that the end user actually sees in their email client. An attacker can pass SPF while spoofing the display name — this is why SPF alone is insufficient.

---

## 3. DKIM — Cryptographic Proof of Integrity

**DKIM (DomainKeys Identified Mail, 域名密钥识别邮件)** adds a cryptographic signature to every outgoing email. The sending server signs selected headers and the message body using a private key. The corresponding public key is published in a DNS TXT record. The receiving server retrieves the public key, verifies the signature, and confirms that the message was not altered in transit.

**How DKIM works:**
1. The sending server hashes selected headers + body, signs the hash with its private key, and adds a `DKIM-Signature` header.
2. The receiving server extracts the `s=` (**selector, 选择器**) and `d=` (domain) from the header.
3. It queries DNS for `selector._domainkey.domain` to retrieve the public key.
4. It verifies the signature against the received message content.

**Key rotation (密钥轮换)** is critical. If a private key is compromised or if you rotate keys periodically, you publish the new public key under a different selector while keeping the old one for a grace period. Many organizations fail to rotate DKIM keys for years — a leaked private key allows an attacker to forge legitimate-looking signed emails until the key is revoked.

---

## 4. DMARC — Enforcing Alignment and Reporting

**DMARC (Domain-based Message Authentication, Reporting and Conformance, 基于域的消息认证、报告和一致性)** ties SPF and DKIM together through the concept of **alignment (对齐)**. It tells receivers what to do when SPF or DKIM fails, and it provides visibility into who is sending email using your domain.

**Alignment modes:**
- **Strict alignment (严格对齐)**: The Header From domain must exactly match the SPF domain or DKIM `d=` domain.
- **Relaxed alignment (宽松对齐)** (default): Subdomains are acceptable.

**DMARC policy (`p=`):**
- `p=none` — Monitor only; no action taken. (Many organizations get stuck here forever.)
- `p=quarantine` — Suspect emails go to spam/junk folder.
- `p=reject` — Reject failing emails outright.

**DMARC DNS record example:**
```
v=DMARC1; p=quarantine; rua=mailto:dmarc-rua@example.com; ruf=mailto:dmarc-ruf@example.com; pct=100; adkim=r; aspf=r
```

- `rua=` — **Aggregate reports (RUA, 聚合报告)**: Daily XML summaries of authentication results across all receivers.
- `ruf=` — **Forensic reports (RUF, 取证报告)**: Near-real-time samples of individual failed messages (may contain sensitive data; use with caution).
- `pct=` — Percentage of messages to which the policy applies (useful for staged rollouts).
- `adkim=` / `aspf=` — Alignment mode for DKIM / SPF (`r` = relaxed, `s` = strict).

---

## 5. How the Three Layers Work Together

Think of it as **defense in depth (纵深防御)** for email:

| Layer | What It Proves | What It Stops |
|-------|---------------|---------------|
| SPF | "This IP is authorized to send for this domain." | Simple spoofing from unauthorized infrastructure. |
| DKIM | "This message was signed by the domain and was not modified." | Content tampering in transit; replay attacks if combined with timestamp checks. |
| DMARC | "SPF or DKIM must align with the visible From header, and here's our enforcement policy." | Display-name spoofing; forces receivers to act on authentication failures. |

Without DMARC, an attacker can pass SPF using their own domain but set the Header From to your domain. Without DKIM, content can be modified by forwarding MTAs. Without SPF, you have no IP-level allowlist. The three together create a strong baseline — but they do *not* stop **lookalike domains (仿冒域名)** (e.g., `examp1e.com` vs `example.com`), which is why user awareness and mailbox rules remain necessary.

---

## 6. Common Misconfigurations and Attack Scenarios

**"p=none" Forever**
Organizations deploy DMARC but never move past `p=none` because they fear blocking legitimate third-party senders. The result: attackers spoof their domain with impunity. The correct approach is to use aggregate reports to inventory all legitimate senders, authorize them via SPF/DKIM, then gradually escalate to `p=quarantine` and finally `p=reject`.

**SPF Bypass via Subdomain**
If `example.com` has a strict SPF but `marketing.example.com` has none, attackers can spoof from the subdomain. Always cover subdomains or use wildcard SPF/DMARC records.

**DKIM Replay Attack**
An attacker captures a legitimately signed email and resends it to other recipients. Because the signature is still valid, DKIM passes. Mitigation: include a timestamp or message-id in the signed headers and enforce freshness checks at the application layer.

**Overly Permissive SPF**
Using `+all` or `?all` at the end of an SPF record effectively neutralizes it. Always end with `-all` or `~all`.

---

## 7. Enterprise Deployment Checklist

1. **Inventory all mail-sending services** — SaaS platforms, marketing tools, ticketing systems, HR portals. Every one must be in SPF or sign with DKIM.
2. **Publish SPF, DKIM, and DMARC for every domain and subdomain** that sends email.
3. **Start DMARC at `p=none`** with a dedicated mailbox for `rua=` reports.
4. **Parse aggregate reports weekly** to identify unauthorized senders. Open-source tools like `parsedmarc` or commercial DMARC analyzers help.
5. **Escalate policy** to `p=quarantine` after 2–4 weeks of clean reports, then `p=reject`.
6. **Rotate DKIM keys quarterly** and maintain an emergency revocation procedure.
7. **Configure BIMI (Brand Indicators for Message Identification, 品牌消息识别标识)** if brand protection is a priority — it requires a VMC (Verified Mark Certificate) and a `p=reject` DMARC policy.

---

## 💡 甲方视角思考

- **资产梳理先行**：在部署 DMARC 前，先通过 RUA 报告和邮件日志穷尽所有代发邮件的第三方系统，避免策略升级后误杀业务流。
- **子域名盲区 = 攻击面**：主域名 hardened 但子域名裸奔是常见短板，需用脚本批量检查所有域名的 SPF/DKIM/DMARC 覆盖。
- **密钥生命周期管理**：DKIM 私钥泄露风险不亚于 TLS 私钥，应纳入密钥管理系统（KMS）的定期轮换策略，并与应急响应预案联动。
- **SIP/流量探针联动**：将邮件网关的 DMARC 失败日志、SPF/DKIM 验证结果接入态势感知平台，建立"钓鱼邮件异常发件域"检测规则。

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| SPF (Sender Policy Framework) | 发送方策略框架 | DNS TXT allowlist for authorized mail servers. |
| DKIM (DomainKeys Identified Mail) | 域名密钥识别邮件 | Cryptographic email signing using RSA/ED25519. |
| DMARC | 基于域的消息认证、报告和一致性 | Enforces SPF/DKIM alignment and provides reporting. |
| MTA (Mail Transfer Agent) | 邮件传输代理 | Server software that routes email (e.g., Postfix, Exchange). |
| Envelope From | 信封发件人 | SMTP `MAIL FROM` address; checked by SPF. |
| Header From | 邮件头发件人 | The From: field visible to end users. |
| Alignment | 对齐 / 一致性 | DMARC requirement that SPF/DKIM domain matches Header From. |
| RUA (Aggregate Reports) | 聚合报告 | Daily XML summaries of DMARC authentication results. |
| RUF (Forensic Reports) | 取证报告 | Near-real-time samples of failed messages. |
| BEC (Business Email Compromise) | 商业邮件欺诈 | Social-engineering attack targeting wire transfers or data. |
| Selector | 选择器 | DKIM key identifier in DNS; enables smooth key rotation. |
| BIMI | 品牌消息识别标识 | Displays brand logos in supported email clients. |
| SMTP | 简单邮件传输协议 | The foundational email transmission protocol. |
| Hard Fail / Soft Fail | 硬失败 / 软失败 | `-all` rejects; `~all` marks but accepts. |
| Lookalike Domain | 仿冒域名 | Visually similar domain used in phishing (e.g., `examp1e.com`). |

---

## 🔮 Tomorrow's Topic — Day 36

**Network Traffic Analysis for Threat Detection** — How to spot C2 beacons, DNS tunneling, and lateral movement in NetFlow / Zeek / PCAP data. We'll cover flow-based detection, JA3 fingerprinting, and how to integrate network telemetry with your SIEM/SOC workflow. Relevant to anyone managing **NGFW (Next-Generation Firewall, 下一代防火墙)** and traffic probes.
