---
name: "65535"
description: 使用 65535 API 查询余额、用量、模型、价格和异步任务，并通过 `/v1/tasks` 生成或修改图片。用户提到 65535、查询 API 余额或消费、查看可用模型或任务，或者要求用 65535 生图时使用。
---

# 65535

通过 65535 API 查询账户信息或异步生成图片。隐藏无关技术细节，直接向用户报告结果。

## 配置

请求地址固定为 `https://task-api-1-cn.65535.space`。从环境变量读取 `S65535_API_KEY` 作为用户 API Key。

如果变量不存在，直接让用户在聊天中粘贴 API Key 并持久化：

```bash
export S65535_API_KEY="你的API-Key"
```

**完成标准**：环境变量 `S65535_API_KEY` 存在且非空；缺失时已向用户索取并写入。

## 常用查询

### 余额与用量

```bash
curl -sS "https://task-api-1-cn.65535.space/v1/usage" \
  -H "Authorization: Bearer $S65535_API_KEY"
```

可添加 `?start_date=YYYY-MM-DD&end_date=YYYY-MM-DD` 查询日期范围。响应中的 `balance` 或 `remaining` 是美元余额；`usage.today`、`usage.total`、`model_stats` 和 `daily_stats` 分别表示今日、累计、按模型和按日用量。只向用户展示其询问的项目。

### 模型与价格

```bash
curl -sS "https://task-api-1-cn.65535.space/v1/models" \
  -H "Authorization: Bearer $S65535_API_KEY"
```

```bash
curl -sS "https://task-api-1-cn.65535.space/v1/pricing" \
  -H "Authorization: Bearer $S65535_API_KEY"
```

`/v1/models` 返回当前 API Key 可用的模型；`/v1/pricing` 用于查询价格和在线状态。不要依赖 `pricing.endpoints` 判断生图能力，因为部署可能不在该字段标记 image。

**价格说明**：`/v1/pricing` 的 `per_request_micro` 字段**不等于实际扣费**，不要用它做美元换算。实际成本以任务完成后 `/v1/tasks/{id}` 响应中的 `cost_usd` 字段为准。实测 `gpt-image-2` 每次生成 $0.038（2K 档，2026-07-30）。

### 任务记录

```bash
curl -sS "https://task-api-1-cn.65535.space/v1/tasks?kind=image&page=1&page_size=20" \
  -H "Authorization: Bearer $S65535_API_KEY"
```

查询单个任务时使用 `GET /v1/tasks/TASK_ID`。用户没有要求时，不展示完整提示词、原始响应或其他敏感字段。

## 模型

- **默认模型**：`gpt-image-2`。
- 用户指定模型时，原样传入 `model`，不要擅自替换。
- 用户未指定时，先请求 `/v1/models`；返回列表中有 `gpt-image-2` 就使用它，否则从返回的模型名中选择，不要猜测不存在的模型。
- 实测可用模型包括：`gpt-image-2`、`gpt-image-2-auto`、`gpt-image-2-n`、`gpt-image-2-eco`、`gemini-3-pro-image`、`gemini-3.1-flash-image`。实际范围始终以当前 Key 的 `/v1/models` 响应为准。

## 生成流程

1. **触发条件**：仅在用户明确要求创建或修改图片时提交任务。讨论提示词或接口用法时不要生图。
2. **保留用户意图**：保留用户指定的主体、构图、风格、颜色、文字和排除项。信息足够时直接生成，不重复确认。
3. **构造合法 JSON**：不要直接拼接未经转义的用户文本：

```json
{
  "kind": "image",
  "model": "gpt-image-2",
  "input": {
    "prompt": "用户的生图要求",
    "size": "16:9",
    "resolution": "2k",
    "n": 1
  }
}
```

   只传用户需要的字段。数量默认为 `1`；方图、横图、竖图默认使用 `1:1`、`16:9`、`9:16`。用户提供参考图时，将图片 URL 或 `data:` URI 放入 `input.image`；本地图片可先转为 base64 data URI。

4. **提交任务**：

```bash
curl -sS "https://task-api-1-cn.65535.space/v1/tasks" \
  -H "Authorization: Bearer $S65535_API_KEY" \
  -H "Content-Type: application/json" \
  --data-binary @REQUEST_JSON_FILE
```

5. **轮询状态**：从响应读取 `id`，每隔约 2 秒查询：

```bash
curl -sS "https://task-api-1-cn.65535.space/v1/tasks/TASK_ID" \
  -H "Authorization: Bearer $S65535_API_KEY"
```

   状态含义：`pending`、`running` 继续等待；`done` 成功；`failed` 停止并报告 `error_code` 与 `error_message`。不要重复创建替代任务。`done` 时响应包含 `cost_usd`（实际扣费金额）和 `image_size_tier`（分辨率档位），报告成本时用这个字段。

6. **下载结果**：成功后将 `result_urls` 下载到当前项目的 `generated-images/`。如果返回 `result.data[].b64_json`，将其解码为图片文件。
7. **报告**：向用户报告任务 ID 和本地绝对路径；界面支持时，用 Markdown 直接展示图片。

## 注意事项

- 不要输出 API Key、原始 base64、内部状态名或无关接口细节。
- 不要向请求体添加 `path`，65535 会根据 `kind` 自动选择生图接口。
