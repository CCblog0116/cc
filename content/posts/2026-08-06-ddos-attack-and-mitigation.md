---
title: "Day 44 — DDoS Attacks and Mitigation Fundamentals"
date: 2026-08-06
tags:
  - daily
  - security
  - english
description: "One DDoS attack Distributed Denial-of-Service，分布式拒绝服务攻击 is an attempt to make an online service unavailable by overwhelming it with traffic from multi"
---

**日期**: 2026-09-29 (Tuesday)
**难度**: ★★★☆☆ 技术 (Day 22–45 技术阶段)
**来源**: Cloudflare Learning Center + CISA + US-CERT AA20-033A + OWASP
**链接**: https://www.cloudflare.com/learning/ddos/what-is-a-ddos-attack/ · https://www.cisa.gov/news-events/alerts/2020/01/08/ddos-threat-advisory

---

One **DDoS attack** (Distributed Denial-of-Service，分布式拒绝服务攻击) is an attempt to make an online service unavailable by overwhelming it with traffic from multiple sources. Unlike a single-source **DoS attack** (Denial-of-Service，拒绝服务攻击), a DDoS attack uses a **botnet** (僵尸网络) — thousands or millions of compromised devices — so the attack cannot be stopped simply by blocking one IP address. The goal is rarely "hacking into" your systems; it is **exhaustion** (耗尽) of a resource: bandwidth, connections, CPU, memory, or application capacity. 本质不是入侵，而是把某项资源（带宽/连接/CPU）活活拖垮。

## Why Volume Is Only Half the Story

It is tempting to measure attacks only by **throughput** (吞吐量，通常以 Gbps 计), but that misses the more dangerous half. A small **L7 attack** (Layer 7，应用层) — e.g., 20 requests per second to an expensive search endpoint — can take down a database faster than 100 Gbps of junk traffic. CISA's advisory (AA20-033A) therefore asks defenders to profile attacks along two axes: **volumetric** (容量型) and **application-layer** (应用层，L7).

| Attack Layer | Example Vectors | Exhausted Resource | Typical Size | Harder to Defend Because |
|---|---|---|---|---|
| **L3/L4 (网络/传输层)** | UDP flood (UDP 洪水), SYN flood (SYN 洪水), ICMP flood, **amplification** (反射放大, e.g. DNS/NTP/memcached) | Bandwidth, connection tables | 10s–1000s Gbps | Volume only — filter by protocol/port/rate |
| **L7 (应用层)** | HTTP flood (HTTP 洪水), slowloris (慢速连接), cache-busting requests (缓存穿透), API abuse | CPU, DB connections, application threads | KBs–Gbps | Looks like legitimate traffic — needs behavior analysis |

**Amplification attacks** (放大攻击) deserve special attention: the attacker sends a small request with a **spoofed source IP** (伪造源 IP) — yours — to open reflector servers (e.g., public DNS resolvers), which send a much larger reply to you. A 60-byte memcached request can yield a ~10,000× larger response. 你只需为 60 字节的提问"背锅"，回复却是上万倍砸向你。This is why **BCP 38** (source address validation，源地址校验) matters network-wide, not just at your edge.

## Anatomy of an Attack

```
                ATTACK TRAFFIC PATH
 ┌──────────┐   spoofed small req   ┌────────────┐  amplified reply   ┌──────────┐
 │ Botnet   │ ────────────────────▶ │ Open DNS / │ ─────────────────▶ │  Victim  │
 │ (C2 控制) │   src IP = victim    │ NTP / memc │   1000x+ volume    │  Target  │
 └──────────┘                       └────────────┘                    └──────────┘
                                                                       │
                                                          ┌────────────▼──────────┐
                                                          │ Overflow: bandwidth   │
                                                          │ SYN backlog, app pool │
                                                          └───────────────────────┘
```

A TCP **SYN flood** works differently: the attacker sends SYNs but never completes the handshake, filling the server's **backlog queue** (半连接队列) until legitimate users cannot connect. Modern kernels use **SYN cookies** (SYN Cookie 技术) to survive this statelessly, but stateful **firewalls** and **load balancers** (负载均衡) can still become the bottleneck themselves — a classic "the defense becomes the victim" scenario.

## Defense in Layers

**Rule one: you cannot out-price a botnet with bandwidth.** DDoS defense is upstream and architectural, not a bigger server. 带宽买不过僵尸网络，纵深防御才是正解。

| Layer | Controls | Notes |
|---|---|---|
| **Upstream / ISP** | **Scrubbing centers** (流量清洗中心), **blackhole routing** (黑洞路由, e.g. RTBH), **Flowspec** (BGP FlowSpec 精细过滤) | RTBH drops *all* traffic to the target — a scalpel's blunt cousin; use for survival, not strategy |
| **CDN / Anti-DDoS service** (抗 DDoS 服务) | Anycast distribution (Anycast 分发), TLS termination, L3–L7 filtering, always-on vs on-demand | Anycast spreads attack traffic across dozens of PoPs; origin must be locked to CDN IPs only, or attackers bypass it |
| **Network internal** | Rate limiting (限速), ACLs, egress/ingress filtering, disable unused services (amplifiers hate closed UDP ports) | Hiding the origin IP (源站隐藏) is the cheapest and most underrated control |
| **Application** | Caching (缓存), WAF L7 rules, **CAPTCHA/challenge** (人机验证), per-identity rate limits, graceful degradation (优雅降级) | Serve cached static pages even when the database is drowning |

**Always-on vs on-demand**: always-on scrubbing costs more but avoids the "traffic spike → reroute → DNS TTL delay" window during which users get nothing. For a hospital-grade availability requirement (医院级可用性要求), always-on L7 protection with on-demand volumetric burst capacity is the usual compromise.

## Response Playbook (甲方视角)

1. **Detect** (发现): alert on traffic anomalies from your **flow telemetry** (流量探针/NetFlow) — volume, new protocol mix, SYN/SYN-ACK ratio, per-destination packet rates. Baseline first; DDoS alarms without baselines are noise.
2. **Classify** (定级): volumetric or L7? Which service, which users, is business impacted (业务可用性) or just noisy? Log the start time — SLA and evidence both need it.
3. **Escalate** (上报处置): notify the ISP/anti-DDoS provider; open a ticket with the 5-tuple and time window. Do not wait for them to notice.
4. **Contain** (止损): enable scrubbing/CDN challenge, apply emergency rate limits, blackhole as last resort.
5. **Review** (复盘): post-incident review (事后复盘) within a week — update runbooks, validate runbook against what actually happened, and run a **tabletop exercise** (桌面演练) if the response relied on tribal knowledge.

> ⚠️ One trap worth repeating: if your origin server's real IP ever leaked (old DNS record, email headers, certificate transparency logs), attackers hit the origin directly and your CDN defense is a moat with a back door. 定期审计 DNS 历史解析记录与证书透明度日志，确认源站 IP 未泄露。

## 甲方视角思考

- 源站隐藏优先于一切抗 DDoS 采购：先确认所有域名/子域都走 CDN，且源站只放行 CDN 回源 IP 段。
- 流量探针/NGFW 的基线告警要进 SIP：SYN 比例异常、UDP 放大特征、单目标速率突增，三条规则覆盖大多数早期发现场景。
- 与 ISP/抗 DDoS 厂商的处置联系人、工单渠道、授权人清单，应写入应急预案并每半年演练一次。
- 复盘时把"黑洞路由生效期间的业务损失"量化，这是向管理层争取 always-on 防护预算的最有力论据。

---

**Key Terms**

| English | 中文 | 备注 |
|---|---|---|
| DDoS (Distributed Denial-of-Service) | 分布式拒绝服务攻击 | 多源同时发起，单靠封 IP 无效 |
| DoS (Denial-of-Service) | 拒绝服务攻击 | 单源版本 |
| Botnet | 僵尸网络 | 被控设备集群，DDoS 的弹药库 |
| Volumetric attack | 容量型攻击 | 拼 Gbps，耗带宽 |
| Application-layer attack (L7) | 应用层攻击 | 像正常请求，耗应用资源 |
| SYN flood | SYN 洪水攻击 | 半握手耗尽连接队列 |
| UDP flood | UDP 洪水攻击 | 无状态，流量为主 |
| Amplification / reflection | 反射放大攻击 | 伪造源 IP 借第三方服务器放大流量 |
| Spoofed source IP | 伪造源 IP | 放大攻击前提 |
| BCP 38 | 源地址校验最佳实践 | 运营商侧根治反射放大 |
| SYN cookies | SYN Cookie 技术 | 无状态抗 SYN 洪水 |
| Backlog queue | 半连接队列 | SYN 洪水的攻击目标 |
| Load balancer | 负载均衡 | 也可能成为瓶颈 |
| Scrubbing center | 流量清洗中心 | 运营商/云侧清洗恶意流量 |
| Blackhole routing (RTBH) | 黑洞路由 | 目标全丢弃，保命不保业务 |
| BGP FlowSpec | BGP 流量规范 | 精细化上游过滤 |
| Anycast | Anycast 任播 | 同一 IP 多点接入，摊薄攻击流量 |
| Origin hiding | 源站 IP 隐藏 | 最便宜且最易被忽视的控制 |
| Rate limiting | 限速 | L4/L7 通用止损手段 |
| Cache-busting | 缓存穿透 | 随机参数绕过 CDN 缓存打源站 |
| CAPTCHA / challenge | 人机验证 | L7 防护的流量分流阀 |
| Graceful degradation | 优雅降级 | 高压下保核心功能 |
| Always-on vs on-demand | 常开式/按需清洗 | 成本与防护时延的取舍 |
| Flow telemetry | 流量遥测（NetFlow/探针） | DDoS 检测的数据底座 |
| Tabletop exercise | 桌面演练 | 低成本验证应急预案 |

**Tomorrow's Preview (Day 45)**: 我们将迎来技术阶段的收官篇 — **Security Operations Center (SOC) Fundamentals**：SOC 的三层分级模型（Tier 1/2/3）、告警分诊（alert triage）流程、指标（MTTD/MTTR），以及它与 SIEM/SIP、EDR、威胁情报的协同。这也是把前面 40+ 篇技术文章串成一张作战地图的一课。
