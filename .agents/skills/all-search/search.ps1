param(
    [Parameter(Mandatory = $true)]
    [string]$Query,

    [Parameter(Mandatory = $false)]
    [ValidateSet("auto", "exa", "tavily", "anysearch", "firecrawl", "context7")]
    [string]$Provider = "auto",

    [Parameter(Mandatory = $false)]
    [int]$MaxResults = 5,

    [Parameter(Mandatory = $false)]
    [string]$ConfigPath = ""
)

$ErrorActionPreference = "Stop"

# 解析脚本目录（兼容从 Git Bash 调用时 $PSScriptRoot 为空的情况）
$ScriptDir = if ($PSScriptRoot) { $PSScriptRoot } elseif ($MyInvocation.MyCommand.Path) { Split-Path -Parent $MyInvocation.MyCommand.Path } else { $PWD.Path }
if (-not $ConfigPath) { $ConfigPath = "$ScriptDir/config.json" }

# 读取配置
$config = Get-Content $ConfigPath -Raw | ConvertFrom-Json
$apiKeys = $config.apiKeys

# 意图分类
function Classify-Intent {
    param([string]$Query)
    $q = $Query.ToLower()
    if ($q -match '\b(stock|price|ticker|forex|crypto|market|trade|earnings|fund|etf|ipo|cve|vulnerability|security|gdp|ppp|macro)\b') { return "finance" }
    if ($q -match '\b(paper|research|journal|doi|arxiv|scholar|academic|study|thesis)\b') { return "academic" }
    if ($q -match '\b(doc|docs|documentation|library|framework|api|sdk|how to|example|syntax|function|method|class|component)\b') { return "docs" }
    if ($q -match '\b(code|github|repo|repository|pull request|commit|branch|merge)\b') { return "technical" }
    if ($q -match '\b(news|latest|today|breaking|announced|update|release)\b') { return "news" }
    return "general"
}

$intent = Classify-Intent -Query $Query

# 提供商路由
$routes = @{
    finance   = @("anysearch", "exa", "tavily")
    academic  = @("exa", "anysearch", "tavily")
    docs      = @("context7", "exa", "tavily")
    technical = @("firecrawl", "exa", "tavily")
    news      = @("tavily", "anysearch", "exa")
    general   = @("tavily", "anysearch", "exa", "firecrawl")
}

# 如果用户指定了 provider
$providerList = @()
if ($Provider -ne "auto") {
    $providerList = @($Provider)
} else {
    $providerList = $routes[$intent]
}

# snippet 截断
function Truncate-Snippet {
    param([string]$Text, [int]$MaxLen = 200)
    if (-not $Text) { return "" }
    if ($Text.Length -gt $MaxLen) { return $Text.Substring(0, $MaxLen) + "..." }
    return $Text
}

# 搜索函数
function Search-Exa {
    param([string]$Key, [string]$Query, [int]$MaxResults)
    $body = @{ query = $Query; numResults = $MaxResults; type = "neural"; contents = @{ text = @{ maxCharacters = 300 } } } | ConvertTo-Json
    $resp = Invoke-RestMethod -Uri "https://api.exa.ai/search" -Method Post -Headers @{ "Content-Type" = "application/json"; "x-api-key" = $Key } -Body $body
    return $resp.results | ForEach-Object { [PSCustomObject]@{ title = $_.title; url = $_.url; snippet = (Truncate-Snippet $_.text); score = $_.score } }
}

function Search-Tavily {
    param([string]$Key, [string]$Query, [int]$MaxResults)
    $body = @{ api_key = $Key; query = $Query; max_results = $MaxResults; search_depth = "basic" } | ConvertTo-Json
    $resp = Invoke-RestMethod -Uri "https://api.tavily.com/search" -Method Post -Headers @{ "Content-Type" = "application/json" } -Body $body
    return $resp.results | ForEach-Object { [PSCustomObject]@{ title = $_.title; url = $_.url; snippet = (Truncate-Snippet $_.content); score = $_.score } }
}

function Search-Anysearch {
    param([string]$Key, [string]$Query, [int]$MaxResults)
    $body = @{ jsonrpc = "2.0"; id = 1; method = "tools/call"; params = @{ name = "search"; arguments = @{ query = $Query; max_results = $MaxResults } } } | ConvertTo-Json -Depth 10
    $resp = Invoke-RestMethod -Uri "https://api.anysearch.com/mcp" -Method Post -Headers @{ "Content-Type" = "application/json"; Authorization = "Bearer $Key" } -Body $body
    $markdown = $resp.result.content[0].text
    # 将 markdown 文本按条目解析为结构化结果
    $results = @()
    $lines = $markdown -split "`n"
    $currentTitle = ""
    $currentUrl = ""
    $currentSnippet = ""
    foreach ($line in $lines) {
        $line = $line.Trim()
        if ($line -match '^#{1,3}\s+(.+)') {
            if ($currentTitle) { $results += [PSCustomObject]@{ title = $currentTitle; url = $currentUrl; snippet = (Truncate-Snippet $currentSnippet.Trim()) } }
            $currentTitle = $Matches[1]
            $currentUrl = ""
            $currentSnippet = ""
        } elseif ($line -match '^\[(.+?)\]\((https?://[^\)]+)\)') {
            if ($currentTitle) { $results += [PSCustomObject]@{ title = $currentTitle; url = $currentUrl; snippet = (Truncate-Snippet $currentSnippet.Trim()) } }
            $currentTitle = $Matches[1]
            $currentUrl = $Matches[2]
            $currentSnippet = ""
        } elseif ($line -match '^\*\*URL\*\*:\s*(https?://\S+)') {
            $currentUrl = $Matches[1]
        } elseif ($line -match '^-\s*\*\*URL\*\*:\s*(https?://\S+)') {
            $currentUrl = $Matches[1]
        } elseif ($line -match '^(https?://\S+)') {
            if (-not $currentUrl) { $currentUrl = $Matches[1] }
        } elseif ($line) {
            if ($currentSnippet) { $currentSnippet += " " }
            $currentSnippet += $line
        }
    }
    if ($currentTitle) { $results += [PSCustomObject]@{ title = $currentTitle; url = $currentUrl; snippet = (Truncate-Snippet $currentSnippet.Trim()) } }
    # 如果未能解析出结构化结果，将整段文本作为单条结果返回
    if ($results.Count -eq 0 -and $markdown) {
        $results += [PSCustomObject]@{ title = "AnySearch Result"; url = ""; snippet = (Truncate-Snippet $markdown) }
    }
    return $results
}

function Search-Firecrawl {
    param([string]$Key, [string]$Query, [int]$MaxResults)
    $body = @{ query = $Query; limit = $MaxResults } | ConvertTo-Json
    $resp = Invoke-RestMethod -Uri "https://api.firecrawl.dev/v1/search" -Method Post -Headers @{ "Content-Type" = "application/json"; Authorization = "Bearer $Key" } -Body $body
    return $resp.data | ForEach-Object { [PSCustomObject]@{ title = $_.title; url = $_.url; snippet = (Truncate-Snippet $_.description) } }
}

function Search-Context7 {
    param([string]$Key, [string]$Query, [int]$MaxResults)
    $libResp = Invoke-RestMethod -Uri "https://context7.com/api/v2/libs/search?libraryName=$([System.Uri]::EscapeDataString($Query))&query=$([System.Uri]::EscapeDataString($Query))" -Headers @{ Authorization = "Bearer $Key" }
    if (-not $libResp.results -or $libResp.results.Count -eq 0) { return @() }
    $lib = $libResp.results[0]
    $ctxResp = Invoke-RestMethod -Uri "https://context7.com/api/v2/context?libraryId=$([System.Uri]::EscapeDataString($lib.id))&query=$([System.Uri]::EscapeDataString($Query))&type=json" -Headers @{ Authorization = "Bearer $Key" }
    $results = @()
    foreach ($snippet in $ctxResp.codeSnippets) {
        if ($results.Count -ge $MaxResults) { break }
        $results += [PSCustomObject]@{ title = if ($snippet.pageTitle) { $snippet.pageTitle } else { $lib.title }; url = if ($snippet.codeId) { $snippet.codeId } else { "https://context7.com$($lib.id)" }; snippet = (Truncate-Snippet $(if ($snippet.codeDescription) { $snippet.codeDescription } else { "" })) }
    }
    foreach ($snippet in $ctxResp.infoSnippets) {
        if ($results.Count -ge $MaxResults) { break }
        $results += [PSCustomObject]@{ title = if ($snippet.breadcrumb) { $snippet.breadcrumb } else { $lib.title }; url = if ($snippet.pageId) { $snippet.pageId } else { "https://context7.com$($lib.id)" }; snippet = (Truncate-Snippet $snippet.content) }
    }
    return $results
}

# 执行搜索（主提供商 + 回退）
$allResults = @()
$usedProvider = ""
$errors = @()

foreach ($p in $providerList) {
    $key = $apiKeys.$p
    if (-not $key) { continue }
    try {
        switch ($p) {
            "exa"       { $results = Search-Exa -Key $key -Query $Query -MaxResults $MaxResults }
            "tavily"    { $results = Search-Tavily -Key $key -Query $Query -MaxResults $MaxResults }
            "anysearch" { $results = Search-Anysearch -Key $key -Query $Query -MaxResults $MaxResults }
            "firecrawl" { $results = Search-Firecrawl -Key $key -Query $Query -MaxResults $MaxResults }
            "context7"  { $results = Search-Context7 -Key $key -Query $Query -MaxResults $MaxResults }
        }
        if ($results -and $results.Count -gt 0) {
            $allResults = $results
            $usedProvider = $p
            break
        }
    } catch {
        $errors += "$p`: $($_.Exception.Message)"
    }
}

# 输出
$output = @{
    query    = $Query
    intent   = $intent
    provider = $usedProvider
    results  = $allResults
    errors   = $errors
}

Write-Output ($output | ConvertTo-Json -Depth 10)
