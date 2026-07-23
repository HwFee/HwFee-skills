[CmdletBinding()]
param(
    [Parameter(Mandatory = $true)]
    [string]$Prompt,

    [string]$Output = "./image2-output.png",
    [string]$Size = "1024x1024",
    [string]$Endpoint,
    [string]$ApiKey,
    [string]$Model = "gpt-image-2",
    [int]$PollIntervalSec = 3,
    [int]$MaxWaitSec = 600
)

$ErrorActionPreference = "Stop"

$SkillRoot = if ($PSScriptRoot) { $PSScriptRoot } else { Split-Path -Parent $MyInvocation.MyCommand.Path }
$ConfigPath = Join-Path $SkillRoot "config.json"

if (-not $Endpoint -or -not $ApiKey) {
    if (Test-Path -LiteralPath $ConfigPath) {
        $cfg = Get-Content -LiteralPath $ConfigPath -Raw | ConvertFrom-Json
        if (-not $Endpoint) { $Endpoint = $cfg.endpoint }
        if (-not $ApiKey)   { $ApiKey   = $cfg.api_key }
    }
}

if (-not $Endpoint) { $Endpoint = "https://img-cn.65535.space" }
if (-not $ApiKey)   { throw "API key missing. Set api_key in $ConfigPath or pass -ApiKey." }

$Endpoint = $Endpoint.TrimEnd('/')

# 1) async submit
$body = @{
    model           = $Model
    prompt          = $Prompt
    size            = $Size
    response_format = "url"
} | ConvertTo-Json -Compress

Write-Host "[image2] POST $Endpoint/v1/images/generations (X-Async-Mode, model=$Model, size=$Size)"
$submitResp = Invoke-RestMethod -Method Post -Uri "$Endpoint/v1/images/generations" `
    -Headers @{
        "Authorization" = "Bearer $ApiKey"
        "X-Async-Mode"  = "true"
        "Content-Type"  = "application/json"
    } `
    -Body $body -TimeoutSec 30

$jobId = $submitResp.job_id
if (-not $jobId) {
    throw "No job_id in submit response: $($submitResp | ConvertTo-Json -Compress -Depth 5)"
}
Write-Host "[image2] job_id=$jobId  polling every ${PollIntervalSec}s (max ${MaxWaitSec}s)..."

# 2) poll
$start = Get-Date
$pollUrl = "$Endpoint/v1/images/async-generations/$jobId"
while ($true) {
    Start-Sleep -Seconds $PollIntervalSec
    $elapsed = (Get-Date) - $start
    if ($elapsed.TotalSeconds -gt $MaxWaitSec) {
        throw "Timeout after $([int]$elapsed.TotalSeconds)s. job_id=$jobId (task still running in background; poll manually: GET $pollUrl)"
    }

    try {
        $job = Invoke-RestMethod -Method Get -Uri $pollUrl `
            -Headers @{ "Authorization" = "Bearer $ApiKey" } `
            -TimeoutSec 15
    } catch {
        Write-Host "[image2] poll error (will retry): $($_.Exception.Message)"
        continue
    }

    $status = $job.data.status
    $sec = [int]$elapsed.TotalSeconds
    Write-Host "[image2] status=$status  elapsed=${sec}s"

    if ($status -eq "done" -or $status -eq "succeeded") {
        $urls = $job.data.result_urls
        if (-not $urls -or $urls.Count -eq 0) {
            throw "Job done but no result_urls. job_id=$jobId"
        }
        $imgUrl = $urls[0]

        $outDir = Split-Path -Parent (Resolve-Path -LiteralPath ".").Path
        $outFull = if ([System.IO.Path]::IsPathRooted($Output)) { $Output } else { Join-Path $outDir $Output }
        $outParent = Split-Path -Parent $outFull
        if ($outParent -and -not (Test-Path -LiteralPath $outParent)) {
            New-Item -ItemType Directory -Path $outParent -Force | Out-Null
        }

        Write-Host "[image2] downloading $imgUrl -> $outFull"
        Invoke-WebRequest -Uri $imgUrl -OutFile $outFull -TimeoutSec 180

        $cost = $job.data.cost_usd
        $tier = $job.data.image_size_tier
        Write-Host "[image2] saved -> $outFull"
        Write-Host "[image2] cost_usd=$cost  tier=$tier  job_id=$jobId"
        return
    }

    if ($status -eq "failed" -or $status -eq "error" -or $status -eq "cancelled") {
        $ec = $job.data.error_code
        $em = $job.data.error_message
        throw "Job ${status}: code=$ec msg=$em  job_id=$jobId"
    }
}
