---
name: image2-gen
description: Generate images via the 65535.space image2 service when the user asks to draw, paint, render, create a picture, or produce a visual asset. Use gpt-image-2 only; call the local PowerShell script by absolute path and verify the saved file exists.
---

# image2-gen · 65535.space 生图

Generate images through the 65535.space image2 API. The tight path is: call the script by absolute path, verify the saved file exists.

唯一可用模型：`gpt-image-2`。不要切换到其他 image2 变体（eco / auto / n / native / gemini）。

## Steps

1. Run the script by absolute path.
   Completion criterion: 命令使用 `C:\Users\17445\Desktop\HwFee-skills\.agents\skills\image2-gen\generate.ps1`（项目 `.agents/skills/` 下），不是 workspace-relative 路径。
2. Report the saved file.
   Completion criterion: 图片存在于 `-Output` 路径；失败则报上游 `error_code` / `error_message` 或超时。

## 调用

```powershell
powershell -ExecutionPolicy Bypass -File "C:\Users\17445\Desktop\HwFee-skills\.agents\skills\image2-gen\generate.ps1" -Prompt "a red apple on white table" -Output "C:\Users\17445\Desktop\HwFee-skills\out.png"
```

参数：
- `-Prompt`（必填）提示词
- `-Output` 输出路径（**必须用绝对路径**，相对路径会解析到脚本所在目录而非项目根目录；默认 `./image2-output.png`）
- `-Size` 尺寸（默认 `1024x1024`，1K 档最便宜）
- `-Endpoint` / `-ApiKey`（默认读 `config.json`，不要在命令行传 key）

## 默认策略

- 端点：`https://img-cn.65535.space`（大陆优化，CN2GIA）。失败可改 `https://sub-proxy-us-1.65535.space`（分发专用，异步转同步更稳）
- 模式：`X-Async-Mode: true` 异步提交 + 轮询 `GET /v1/images/async-generations/{job_id}`（无 5min 超时限制，任务跑到完成）
- `quality` / `n` 参数传啥都被服务端改写为 `auto` / `1`，**不要传**
- `size` 宽高必须都能被 16 整除，长边 ≤ 3840，总像素 0.7-8.85 MP

## 计费档位（按最长边）

| 最长边 | 档位 |
|---|---|
| ≤1024 | 1K（默认，最便宜）|
| ≤2048 | 2K |
| >2048 | 4K |
| 特例 2560×1440 / 1440×2560 | 2K |

`gpt-image-2` 按次计费，1K 最便宜（实测 ~0.038/次）。

## 限制

| 项 | 值 |
|---|---|
| 单用户并发 | 5-20（账户配置，超限 `429`）|
| 结果有效期 | 24h（脚本会立即下载到本地，不受影响）|
| 最小像素 | 655360 |
| 最大像素 | 8294400 |

## 错误处理

| HTTP / 错误 | 含义 | 重试 |
|---|---|---|
| `400` Unsupported parameter | 参数不被接受 | 否 |
| `403` | Key 不在图片分组 | 否 |
| `429` | 并发超限 | 稍后 |
| `503` queue_too_long | 队列过载 | 稍后 |
| `Our servers are currently overloaded` | OpenAI 算力不足 | 可重试 |
| `Context not allow` | 风控命中（禁色情/破解/CTF等，频繁会封号）| 否 |
| `content_refused` | 模型拒绝内容 | 否，改 prompt |
| `upstream_5xx` / `upstream_error` | 上游临时故障 | 可重试 |

维护窗口：UTC+8 0-6 点可能 502，每次 30-50s。

## 注意

- gpt-image-2 在用户账户的「输出尺寸对齐请求」开关未开时，可能返回尺寸不匹配请求的图。这是账户级设置，skill 无法控制；如发现尺寸偏差，提醒用户去个人资料打开该开关。
- 调用脚本会输出 `cost_usd` 和 `tier`，便于核对计费。
