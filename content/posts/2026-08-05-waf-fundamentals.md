---
title: "Day 43 — Web Application Firewall (WAF) Fundamentals (Web 应用防火墙基础)"
date: 2026-08-05
tags:
  - daily
  - security
  - english
description: "A Web Application Firewall WAF Web 应用防火墙 sits between the internet and your web application, inspecting HTTP/HTTPS traffic 超文本传输协议流量 in real time. Unl"
---

**日期**: 2026-09-28
**难度**: ★★★☆☆ 技术级
**来源**: OWASP ModSecurity Core Rule Set (CRS) Documentation / OWASP WAF Cheat Sheet / Cloudflare Learning Center
**链接**: https://coreruleset.org/docs/ · https://cheatsheetseries.owasp.org/cheatsheets/WAF_Cheat_Sheet.html · https://www.cloudflare.com/learning/security/what-is-a-waf/

---

## Why WAFs Matter (为什么 WAF 很重要)

A **Web Application Firewall (WAF)** (Web 应用防火墙) sits between the internet and your web application, inspecting **HTTP/HTTPS traffic** (超文本传输协议流量) in real time. Unlike a traditional **network firewall** (网络防火墙), which filters traffic by IP address and port, a WAF understands the **application layer** (应用层) — it reads URLs, headers, cookies, and request bodies, looking for malicious payloads.

Think of it this way: a network firewall is a **gate guard** checking IDs at the building entrance; a WAF is a **body scanner** that inspects what you carry inside. （网络防火墙查"谁来了"，WAF 查"带来了什么"。）

For a service-side security engineer, the WAF is the first **detection and prevention layer** (检测与防护层) in front of every web-facing system — SSO portals, APIs, patient-service websites. But a WAF is not magic: misconfigured rules block legitimate users, and over-tuned rules create **false positives** (误报) that drown your SOC. Today we learn how WAFs work, what they check, how attackers bypass them, and how to tune them properly.

## How a WAF Inspects Traffic (WAF 如何检测流量)

A typical WAF processes each HTTP request through several stages:

```
Client Request
      │
      ▼
┌─────────────────────────────────────────────┐
│  1. Protocol Validation (协议校验)            │
│     - Malformed HTTP? Illegal headers?       │
│     - Request smuggling patterns?            │
├─────────────────────────────────────────────┤
│  2. Signature Matching (签名匹配)             │
│     - Regex rules vs known payloads          │
│     - e.g. ' UNION SELECT, <script>, ../     │
├─────────────────────────────────────────────┤
│  3. Anomaly Scoring (异常评分)                │
│     - Accumulate scores per rule match       │
│     - Block if total score exceeds threshold │
├─────────────────────────────────────────────┤
│  4. Reputation Check (信誉检查)               │
│     - Known-bad IPs, bots, Tor exit nodes    │
├─────────────────────────────────────────────┤
│  5. Rate Limiting (频率限制)                  │
│     - Brute force / credential stuffing      │
└─────────────────────────────────────────────┘
      │
      ▼
  Allow / Log / Block / Challenge (CAPTCHA, JS challenge)
```

## WAF Deployment Modes (部署模式)

| Mode (模式) | How It Works (工作方式) | Pros (优点) | Cons (缺点) |
|---|---|---|---|
| **Reverse Proxy (反向代理)** | All traffic flows through the WAF; it forwards clean requests upstream | Full visibility; can rewrite requests | Added latency (延迟); single point of failure |
| **Transparent Bridge (透明桥接)** | Inline at Layer 2, invisible to clients | No network/DNS changes needed | Harder to scale |
| **Out-of-Band / Monitor-only (旁路监听)** | Receives mirrored traffic (流量镜像) from a probe; alerts but cannot block | Zero impact on production; great for tuning | **Detection only — cannot block** (只告警不拦截) |
| **Cloud WAF (云 WAF)** | DNS points to vendor scrubbing center | Fast deployment; managed rule updates | Data leaves your network; trust boundary shifts |

> **甲方提示**: Your SIP/NGFW stack likely already mirrors traffic to a probe — an out-of-band WAF fits that pattern for detection, but real blocking needs an inline (串接) reverse-proxy mode.

## The OWASP Core Rule Set (OWASP 核心规则集)

You rarely write WAF rules from scratch. The industry baseline is the **OWASP ModSecurity Core Rule Set (CRS)** (OWASP 核心规则集) — an open-source rule package covering the **OWASP Top 10** attack families:

- **SQL injection (SQL 注入)** — detects `UNION SELECT`, `' OR 1=1--`, etc.
- **Cross-site scripting (XSS, 跨站脚本)** — detects `<script>`, `onerror=`, event handlers
- **Local/Remote File Inclusion (本地/远程文件包含)** — detects `../../`, `php://input`
- **Command injection (命令注入)** — detects `; cat /etc/passwd`, backticks
- **Protocol anomalies (协议异常)** — malformed requests, smuggling patterns
- **Scanner detection (扫描器识别)** — known tool User-Agents and probes

CRS uses **anomaly scoring mode** (异常评分模式) by default: each rule match adds points to a **per-request score** (单请求评分). When the inbound score crosses a threshold, the request is blocked. This design matters — a single weak rule match won't block a legitimate user, but several matches together will.

Paranoia levels (偏执等级, PL1–PL4) let you raise sensitivity: **PL1** is the gentle default; **PL3–PL4** catch subtler attacks but generate far more false positives.

## How Attackers Bypass WAFs (攻击者如何绕过 WAF)

A WAF is a **defense-in-depth layer, never a fix**. Attackers use these families of bypass techniques (绕过技术):

| Bypass Family (绕过类型) | Example (示例) |
|---|---|
| **Encoding tricks (编码变换)** | URL-encode, double-encode, or Unicode-encode payloads so regex misses them: `%252e%252e%252f` |
| **Syntax variants (语法变体)** | SQL: `UNION/**/SELECT`, `/*!50000SELECT*/`; XSS: `<svg/onload=...>`, `<img src=x onerror=...>` |
| **HTTP parser differences (解析差异)** | Request smuggling (Day 27), header injection — WAF and backend disagree on request boundaries |
| **Fragmentation (分片)** | Split payload across parameters, chunks, or multipart fields |
| **API/parameter pollution (参数污染)** | Send `?id=1&id=2` — WAF checks one, backend takes the other |
| **Direct-to-origin (源站绕过)** | Discover the origin server IP (源站 IP) and attack it directly, skipping the WAF entirely |
| **Encoding in content types** | Payload inside `Content-Type: multipart`, JSON, or compressed bodies the WAF doesn't inspect |

The last one — **origin IP discovery** — is the most common real-world failure: an organization buys a cloud WAF, but old DNS records, exposed subdomains, or leaked config files still reveal the origin. Once attackers hit the origin directly, the WAF never sees the request. **Force all traffic through the WAF** (强制全量走 WAF): origin servers should only accept connections from WAF IP ranges.

## Tuning Without Drowning the SOC (调优而不淹没 SOC)

A freshly deployed WAF in blocking mode will break production. The proven rollout path (灰度上线路径):

1. **Detection-only mode first (先上检测模式)** — run 2–4 weeks, log every would-be block. This is your baseline.
2. **Analyze logs, find noisy rules (分析日志找噪声规则)** — e.g. a patient-service page posting base64 blobs triggers SQLi rules. Add **rule exclusions** (规则排除) scoped narrowly: specific rule ID + parameter name + endpoint. Never disable a rule globally.
3. **Raise thresholds gradually (逐步收紧)** — start with a high anomaly score threshold (few blocks, few false positives), then lower it as exclusions mature.
4. **Block known-bad first (先封明确恶意)** — scanner User-Agents, known-bad IPs, and obvious attack paths (admin panels exposed to the internet) can be blocked on day one.
5. **Feed WAF logs into the SIP (接入态势感知)** — WAF events correlated with EDR and network probe telemetry turn a standalone box into part of your detection pipeline. Watch for **block-rate spikes** (拦截率突增) — they often signal an active campaign.

> **关键认知**: A WAF buys you **time** (争取时间) — it slows down generic attacks so your team can patch the root cause. It does not replace secure coding, and it will not stop a logic flaw (Day 26) or a zero-day. Track which attacks the WAF blocked, then verify the underlying vulnerability actually got fixed.

## Key Terms (专有名词表)

| English | 中文 | Notes |
|---|---|---|
| Web Application Firewall (WAF) | Web 应用防火墙 | Filters HTTP traffic at the application layer |
| Network Firewall | 网络防火墙 | Layer 3/4 filtering — IP, port, protocol |
| Application Layer | 应用层 | Layer 7 of the OSI model — where WAFs operate |
| Reverse Proxy | 反向代理 | Common inline WAF deployment mode |
| Out-of-Band (OOB) | 旁路部署 | Mirror traffic; detect only, cannot block |
| Detection-only Mode | 只检测模式 | Log-first rollout phase; also called monitor mode |
| Inline (串接) | 串联部署 | Traffic must pass through the device; can block |
| Signature Matching | 签名匹配 | Regex/keyword rules against known payloads |
| Anomaly Scoring | 异常评分 | Cumulative per-request score vs threshold |
| Threshold (阈值) | 阈值 | Score at which a request is blocked |
| Paranoia Level (PL) | 偏执等级 | CRS sensitivity level 1–4 |
| Core Rule Set (CRS) | 核心规则集 | OWASP's open-source WAF rule package |
| Rule Exclusion | 规则排除 | Narrow exception for a rule on one parameter/endpoint |
| False Positive (FP) | 误报 | Legitimate request wrongly flagged/blocked |
| False Negative (FN) | 漏报 | Malicious request missed by the WAF |
| Bypass Technique | 绕过技术 | Method to evade WAF detection |
| Encoding Trick | 编码变换 | URL/double/Unicode encoding to defeat regex |
| Parameter Pollution | 参数污染 | Duplicate parameters parsed differently |
| Origin Server | 源站 | Backend server behind the WAF |
| Rate Limiting | 频率限制 | Throttling brute force and abuse |
| CAPTCHA / JS Challenge | 人机验证 | Challenge issued to suspicious clients |
| Block Rate | 拦截率 | Percentage of requests blocked — monitor spikes |
| Defense in Depth | 纵深防御 | WAF is one layer, never the only layer |

## 甲方视角思考 (Buyer-Side Perspective)

- **上线路径要定死**: detection-only 2–4 周 → 逐条排除 → 再切拦截模式；直接上 blocking 一定会误伤业务。
- **规则排除必须窄化**：绑定 rule ID + 参数 + 接口，禁止全局关规则；每次排除留审计记录。
- **源站强制走 WAF**：只允许 WAF 回源 IP 访问源站，防止直连绕过；定期查旧 DNS 记录和暴露子域名。
- **WAF 日志进 SIP**：拦截率突增、绕过尝试和扫描行为要能关联到 EDR/流量探针，形成告警闭环。

## Tomorrow's Preview (明日预告)

**Day 44 — DDoS Attack and Mitigation Fundamentals (DDoS 攻击与缓解基础):** volumetric vs application-layer attacks, reflection and amplification, rate limiting and CDN scrubbing, and how to build a mitigation playbook before the attack starts.
