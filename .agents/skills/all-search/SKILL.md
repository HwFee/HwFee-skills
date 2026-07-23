---
name: all-search
description: "Default web search - routes any online query to the right specialist engine: exa (academic), anysearch (finance/CVE/macroeconomics), context7 (docs), firecrawl (code), tavily (general/deep research). Use instead of built-in WebSearch/moonshot_search for all web lookups."
---

# all-search · Default Web Search

The only web search tool. **Route** every online lookup to one of five engines by domain. Do not use the built-in `WebSearch`/`moonshot_search`.

## Step 0 - Read API keys

`Read` the [`config.json`](config.json) in this skill's directory. It contains `apiKeys` for all five engines:

```json
{ "apiKeys": { "exa": "...", "tavily": "...", "anysearch": "...", "firecrawl": "...", "context7": "..." } }
```

Substitute the real key wherever `${key}` appears below.

**Completion criterion**: config.json read and all five keys available.

## Step 1 - Run auto search first, correct if needed

Default: run the script with `-Provider auto` - it classifies and calls in one shot:

```bash
powershell.exe -ExecutionPolicy Bypass -File "<skill_dir>/search.ps1" -Query "your query" -Provider auto
```

The script returns compact JSON: `{ query, intent, provider, results[], errors[] }`. Each result has `{ title, url, snippet, score? }` with snippets truncated to 200 chars.

**Check the `intent` field** in the output. If it looks wrong for the query (e.g. a CVE query classified as `technical` instead of `finance`), re-run with the correct engine:

```bash
powershell.exe -ExecutionPolicy Bypass -File "<skill_dir>/search.ps1" -Query "your query" -Provider <correct_engine>
```

Engine-to-domain mapping for correction:

| Domain | Engine |
|--------|--------|
| Academic (papers, DOI, arxiv) | exa |
| Finance / macro / security (GDP, PPP, tickers, CVE) | anysearch |
| Docs (library/framework/API) | context7 |
| Code (GitHub, repos, snippets) | firecrawl |
| General / deep research (news, broad topics) | tavily |

If the primary engine returns empty or errors, re-run with a fallback from the same domain. Optional flags: `-MaxResults 10`.

**Completion criterion**: results obtained from the correct engine (or the whole chain exhausted + empty reported).

## Step 2 - Present results

Return results as markdown: numbered list with title, URL, snippet. Name the source provider.

**Completion criterion**: results rendered, with the source provider named.

## Manual API calls (fallback when search.ps1 is unavailable)

> **Do NOT use `FetchURL`** for POST-based APIs - it only supports GET and will fail silently or return 401.

**POST engines** (Exa / Tavily / AnySearch / Firecrawl) - use `Bash` + `curl`:

```bash
curl -s -X POST https://api.tavily.com/search \
  -H "Content-Type: application/json" \
  -d '{"api_key":"<key>","query":"...","max_results":5}'
```

**GET engine** (Context7, two-step) - `FetchURL` or `curl` both work:

1. `GET https://context7.com/api/v2/libs/search?libraryName=<query>&query=<query>` -> pick first result's `id`
2. `GET https://context7.com/api/v2/context?libraryId=<id>&query=<query>&type=json` -> read `codeSnippets[]` and `infoSnippets[]`

`curl` responses can be large and may get **truncated** by the Bash tool. Pipe through `python -m json.tool` for readability, or extract key fields with `python -c "import sys,json; ..."`.

### API call shapes

#### Exa
```bash
curl -s -X POST https://api.exa.ai/search \
  -H "Content-Type: application/json" -H "x-api-key: ${key}" \
  -d '{"query":"...","numResults":5,"type":"neural","contents":{"text":{"maxCharacters":300}}}'
```

#### Tavily
```bash
curl -s -X POST https://api.tavily.com/search \
  -H "Content-Type: application/json" \
  -d '{"api_key":"${key}","query":"...","max_results":5}'
```

#### AnySearch
```bash
curl -s -X POST https://api.anysearch.com/mcp \
  -H "Content-Type: application/json" -H "Authorization: Bearer ${key}" \
  -d '{"jsonrpc":"2.0","id":1,"method":"tools/call","params":{"name":"search","arguments":{"query":"...","max_results":5}}}'
```
Response is JSON-RPC with markdown text in `result.content[0].text`.

#### Firecrawl
```bash
curl -s -X POST https://api.firecrawl.dev/v1/search \
  -H "Content-Type: application/json" -H "Authorization: Bearer ${key}" \
  -d '{"query":"...","limit":5}'
```

#### Context7
Two-step (GET, can use `FetchURL`):
1. `GET https://context7.com/api/v2/libs/search?libraryName=${query}&query=${query}` -> pick first result's `id`
2. `GET https://context7.com/api/v2/context?libraryId=${id}&query=${query}&type=json` -> read `codeSnippets[]` and `infoSnippets[]`

Auth tokens are stored in [`config.json`](config.json).

## Fallback rule

If every engine in the chain returns empty or errors, report that clearly and suggest rephrasing the query.

## Supplementary queries

A single search may not cover all aspects of a question. If the first result set is incomplete (e.g. found the "Current" version but not the "LTS" version), run a **second targeted query** to fill the gap. Cross-reference multiple results for completeness.
