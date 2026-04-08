param(
    [Parameter(Mandatory = $true)]
    $Context
)

$ErrorActionPreference = "Stop"

Write-Step "Configuring Scoop Buckets"

# 说明：
#   这一步只负责“bucket 配置”，不负责安装 Scoop 本体。
#   当前 bootstrap 假定 Scoop 已经手动安装并可正常使用。

# 行为：
#   1. 读取 manifest 中声明的所有 bucket
#   2. 读取本机当前已配置的 bucket
#   3. 缺失的 bucket 才执行 scoop bucket add
#   4. add 之后再次确认是否真的已存在，再决定输出成功/失败

# 注意：
#   - manifest 中的 bucket name 必须使用“实际 alias”
#   - main bucket 为 Scoop 内建 bucket，不需要显式添加
#   - 这里优先按对象属性读取 scoop bucket list，只有必要时才回退到文本解析

$windowsPackages = $Context.WindowsPackages
if ($null -eq $windowsPackages) {
    throw "Context.WindowsPackages is null."
}

$buckets = @()
if ($windowsPackages.PSObject.Properties["scoopBuckets"] -and $null -ne $windowsPackages.scoopBuckets) {
    $buckets = @($windowsPackages.scoopBuckets)
}

if ($buckets.Count -eq 0) {
    Write-Host "  No extra Scoop buckets declared in manifest." -ForegroundColor DarkGray
    Write-OK "Scoop bucket configuration complete"
    return
}

function Get-CurrentScoopBucketNames {
    [CmdletBinding()]
    param()

    $names = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)

    # 优先按对象属性读取
    try {
        $bucketItems = @(scoop bucket list)
        foreach ($item in $bucketItems) {
            if ($null -eq $item) { continue }

            # 如果是对象输出，优先直接取 Name
            if ($item.PSObject.Properties["Name"]) {
                $name = [string]$item.Name
                if (-not [string]::IsNullOrWhiteSpace($name)) {
                    [void]$names.Add($name.Trim())
                    continue
                }
            }

            # 回退：按字符串解析
            $text = ([string]$item).Trim()
            if ([string]::IsNullOrWhiteSpace($text)) { continue }
            if ($text -match '^(Name|----)\b') { continue }

            $firstToken = ($text -split '\s+')[0]
            if (-not [string]::IsNullOrWhiteSpace($firstToken)) {
                [void]$names.Add($firstToken.Trim())
            }
        }
    } catch {
        throw "Failed to query current Scoop buckets: $_"
    }

    return $names
}

$currentBucketNames = Get-CurrentScoopBucketNames

foreach ($bucket in $buckets) {
    $bucketName = if ($bucket.PSObject.Properties["name"]) { [string]$bucket.name } else { "" }
    $bucketUrl  = if ($bucket.PSObject.Properties["url"])  { [string]$bucket.url }  else { "" }

    if ([string]::IsNullOrWhiteSpace($bucketName)) {
        Write-Warn "Encountered a bucket entry without a valid name; skipping."
        continue
    }

    # main 是内建 bucket，不需要显式添加
    if ($bucketName -eq "main") {
        Write-Host "  -> Skip built-in bucket: main" -ForegroundColor DarkGray
        continue
    }

    if ($currentBucketNames.Contains($bucketName)) {
        Write-OK "Bucket already added: $bucketName"
        continue
    }

    Write-Host "  Adding bucket: $bucketName" -ForegroundColor Gray

    try {
        if ([string]::IsNullOrWhiteSpace($bucketUrl)) {
            scoop bucket add $bucketName | Out-Null
        } else {
            scoop bucket add $bucketName $bucketUrl | Out-Null
        }
    } catch {
        # 先不立刻认定失败，后面会重新检查是否已经存在
        Write-Host "  -> bucket add returned an error/warning for $bucketName, re-checking actual state..." -ForegroundColor DarkGray
    }

    # 重新读取当前 bucket 状态，避免把“已存在”误判成“新增成功”
    $currentBucketNames = Get-CurrentScoopBucketNames

    if ($currentBucketNames.Contains($bucketName)) {
        Write-OK "Bucket available: $bucketName"
    } else {
        throw "Failed to ensure Scoop bucket '$bucketName' is available."
    }
}

Write-OK "Scoop bucket configuration complete"
