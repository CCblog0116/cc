---
title: "Day 36 — Network Traffic Analysis for Threat Detection"
date: 2026-09-21
tags:
  - daily
  - security
  - english
description: "📅 Date: 2026-09-21 | 🎯 Difficulty: ★★★☆☆ | 📖 Sources: Zeek Documentation, Cisco NetFlow, NIST SP 800-94, Salesforce JA3 | ⏱️ 15 min read"
---

📅 Date: 2026-09-21 | 🎯 Difficulty: ★★★☆☆ | 📖 Sources: Zeek Documentation, Cisco NetFlow, NIST SP 800-94, Salesforce JA3 | ⏱️ 15 min read

---

## 1. Why Network Traffic Analysis Matters

Even the most carefully hidden malware must eventually **"phone home" (回连 C2 服务器)**. Firewalls and endpoint tools can be bypassed, but network traffic leaves traces that are difficult to erase. **Network Traffic Analysis (NTA, 网络流量分析)** — analyzing **NetFlow (网络流记录)**, **PCAP (Packet Capture, 抓包文件)**, and sensor metadata — lets defenders spot **Command and Control (C2, 命令与控制)** beacons, **DNS tunneling (DNS 隧道)**, and **lateral movement (横向移动)** even when payloads are encrypted.

For a 甲方 team running **NGFW (Next-Generation Firewall, 下一代防火墙)**, traffic probes, and a **SIP (Situational Awareness Platform, 态势感知平台)**, NTA is the glue that turns raw flow records into detections.

---

## 2. Three Levels of Network Telemetry

| Telemetry | What You Get | Typical Tool | Cost / Blind Spot |
|-----------|-------------|--------------|-------------------|
| **Flow records (流记录)** | Who talked to whom, when, how much, on which port | NetFlow v9 / IPFIX, sFlow | No payload — content invisible |
| **Metadata / logs (元数据)** | Protocol-level facts: HTTP headers, DNS queries, TLS certificates, file hashes | **Zeek (formerly Bro)** | No full reassembly, but very cheap |
| **Full packet capture (全流量抓包)** | Every byte | Suricata, Wireshark, pcap storage | Huge storage; privacy and retention constraints |

Best practice is a **pyramid**: flow everywhere, metadata on core links, full PCAP only at choke points for a limited retention window (e.g., 72 hours) for forensics.

---

## 3. Flow-Based Detection with NetFlow

A NetFlow record is a 5-tuple summary: source IP/port, destination IP/port, protocol — plus byte and packet counters. Individually dull; in aggregate, powerful:

- **Beaconing detection (心跳外联检测)**：C2 malware checks in at remarkably regular intervals. Compute the *jitter* (standard deviation of inter-connection gaps) — human browsing is irregular, malware often is not. A host making a connection to the same external IP every 60±2 seconds for days is a strong beacon candidate.
- **Data exfiltration (数据外泄)**：track **long-tail upload ratios**. A server that normally uploads 10 MB/day suddenly pushing 5 GB to an unknown ASN is an incident, not a backup job.
- **Lateral movement (横向移动)**：workstations rarely talk to each other via **SMB (445)** or **RDP (3389)**. New workstation-to-workstation flows after a phishing alert usually mean an attacker is mapping the internal network.

Free tooling: **nfdump / NfSen** for collection and analysis; most NGFWs and probes can export flow records directly to your SIEM.

---

## 4. Zeek — Metadata at Protocol Depth

**Zeek** parses protocols into structured logs. The logs most useful for threat detection:

| Zeek Log | Detection Value |
|----------|----------------|
| `conn.log` | All connections — the flow-level baseline |
| `dns.log` | Excessive query length, high-entropy labels, unusual RR types (TXT/NULL) → **DNS tunneling** |
| `http.log` | Odd User-Agents, POSTs to uncategorized domains, direct-IP requests |
| `ssl.log` | Self-signed certs, short validity, JA3 hashes |
| `files.log` | File hashes transferred over HTTP/SMTP — pivot straight to sandbox/EDR |
| `notice.log` | Zeek's built-in anomaly notices (weird traffic, scan detection) |

**DNS tunneling example**: a query like `aGVsbG8gd29ybGQ.tunnel.evil-domain.com` encodes data in subdomain labels. Zeek signals: query length > 52 chars, TXT record frequency, or one host generating hundreds of unique subdomains per hour against a single authoritative NS. Your recent MSS alerts on malicious domain resolution fit exactly here — correlate `dns.log` with the probe's DNS session data.

---

## 5. TLS Fingerprinting — JA3 and JA3S

Encrypted traffic hides payloads, but the **TLS ClientHello (客户端握手包)** is sent in plaintext and is remarkably distinctive. **JA3** (by Salesforce researchers) hashes the ClientHello fields — TLS version, cipher suites, extensions, elliptic curves, formats — into a 32-character MD5 fingerprint.

Why it matters: every malware family built on a specific library (e.g., a Go-based **RAT (Remote Access Trojan, 远控木马)**) produces a stable JA3. You can:

1. Compute JA3 for all outbound TLS sessions via Zeek (community packages) or your probe.
2. Alert on JA3 hashes known-bad (feed: abuse.ch **SSL Blacklist**) or simply *rare* in your environment.
3. Pair with **JA3S** (server response fingerprint) to reduce false positives.

⚠️ Caveat: JA3 is MD5-based and increasingly evaded by malware randomizing ClientHello fields — modern deployments also look at **JA4/JA4+** fingerprints, which are more robust.

---

## 6. Building the Detection Pipeline

A pragmatic NTA architecture for an enterprise:

```
Traffic probes (span ports / TAPs)
        │
        ▼
Zeek / Suricata sensors ──► metadata logs + IDS alerts
        │
        ▼
SIEM / SIP  ◄── NetFlow exports from NGFW & core switches
        │
        ▼
Detection rules: beaconing jitter, DNS entropy,
JA3 watchlist, exfil ratio baselines
        │
        ▼
SOC triage → EDR pivot → containment
```

Detection ideas to start with:

- **Jitter rule**: group by (src, dst), compute connection-interval stddev; alert when < 5% variance over 20+ connections in 24h.
- **DNS rule**: alert when average query length > 40 chars AND > 50 unique subdomains/hour to one domain.
- **JA3 rule**: join `ssl.log` JA3 against a watchlist; enrich with threat intel for known C2.
- **Exfil rule**: alert when a host's outbound bytes exceed 10× its 30-day baseline.

---

## 7. Common Pitfalls

1. **Ignoring encrypted traffic** — "It's TLS, we can't see it" is wrong; metadata (SNI, JA3, flow timing, byte patterns) still leaks plenty.
2. **No baselines (基线缺失)** — anomaly detection without 30-day baselines produces alert storms. Establish "normal" before hunting "abnormal."
3. **Storage over analysis** — buying full PCAP retention while never writing detection rules is a common 甲方 trap. Metadata + rules beats raw bytes + no rules.
4. **One sensor, one blind spot** — traffic that never crosses your sensor (VPN, cloud interconnects, IoT on flat networks) is invisible. Map coverage first.

---

## 💡 甲方视角思考

- **探针点位盘点**：先画出流量探针与旁路镜像的覆盖图，找出 VPN 出口、云专线等盲区，比急着上检测规则更重要。
- **DNS 隧道检测落地**：把 Zeek `dns.log` 的域名长度/熵值规则接入 SIP，与 MSS 恶意域名告警做关联，形成双向印证。
- **JA3 情报闭环**：用 abuse.ch SSL Blacklist + 自建环境 JA3 白名单双轨运行，避免单纯黑名单的高误报。
- **基线先行**：任何异常流量规则上线前，先跑 2–4 周纯观察模式，确认基线稳定再转告警。

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| NTA (Network Traffic Analysis) | 网络流量分析 | Detecting threats from flow/metadata patterns. |
| NetFlow / IPFIX | 网络流记录协议 | Router/switch-exported flow summaries. |
| PCAP (Packet Capture) | 抓包文件 | Full raw packet recording for forensics. |
| C2 (Command and Control) | 命令与控制 | Attacker channel controlling compromised hosts. |
| Beaconing | 心跳外联 | Periodic C2 check-in connections. |
| Jitter | 抖动 | Timing variance; low jitter suggests automation. |
| Lateral Movement | 横向移动 | Attacker spreading inside the internal network. |
| DNS Tunneling | DNS 隧道 | Exfiltrating data encoded in DNS queries. |
| Zeek (formerly Bro) | — | Protocol-analyzing network sensor producing logs. |
| Suricata | — | IDS/IPS engine with EVE JSON output. |
| JA3 | — | MD5 fingerprint of the TLS ClientHello. |
| JA4 | — | Robust successor TLS fingerprinting method. |
| ClientHello | 客户端握手包 | First TLS handshake message, sent in plaintext. |
| SNI (Server Name Indication) | 服务器名称指示 | Plaintext hostname in TLS; useful despite encryption. |
| SMB (Server Message Block) | 文件共享协议 | Port 445; workstation-to-workstation SMB is suspicious. |
| ASN (Autonomous System Number) | 自治系统号 | Identifies a network operator on the internet. |
| Exfiltration | 数据外泄 | Unauthorized transfer of data out of the network. |
| Baseline | 基线 | Established "normal" behavior for anomaly comparison. |
| Sensor | 流量探针 | Passive monitoring point on a network link. |
| IDS / IPS | 入侵检测/防御系统 | Signature- or anomaly-based network detection. |

---

## 🔮 Tomorrow's Topic — Day 37

**Threat Intelligence Fundamentals** — What makes IOCs useful, TLP marking, STIX/TAXII feeds, and how to operationalize threat intel in a SIEM without drowning in false positives. We'll also cover building an intel requirements list driven by your actual attack surface.
