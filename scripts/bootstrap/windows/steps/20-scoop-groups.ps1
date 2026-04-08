param(
    [Parameter(Mandatory = $true)]
    $Context
)

$ErrorActionPreference = "Stop"

Write-Step "Installing Selected Scoop Groups"

# 说明：
#   这一步处理 scoopGroups 中：
#     - selection = default
#     - selection = optional

#   required 组已经在 15-bootstrap-required.ps1 中处理过，这里不重复安装。

#   安装模型：
#     1. default 组：默认安装，但用户可以跳过
#     2. optional 组：默认不安装，用户手动选择
#     3. 组选中之后，若某个包在 packageOptions 中被标记 selection=optional，
#        则该包会成为“组内二级可选项”
#     4. installMode=manual 的包不会自动安装，只会提示用户手动处理
#     5. installMode=skip 的包完全跳过

#   这样就对应了当前 windows.scoop-classification.yaml 的语义：
#     - group.selection 决定“组是否参与安装”
#     - packageOverrides.<bucket>.<pkg>.selection 决定“组选中后包是否继续可选”

$windowsPackages = $Context.WindowsPackages
if ($null -eq $windowsPackages) {
    throw "Context.WindowsPackages is null."
}

Assert-ManifestHasScoopGroups -WindowsPackages $windowsPackages

function Get-ObjectPropValue {
    <#
    .SYNOPSIS
        安全读取对象属性，属性不存在时返回 fallback。
    #>
    param(
        [object]$Object,
        [string]$Name,
        [object]$Fallback = $null
    )

    if ($null -ne $Object -and $Object.PSObject.Properties[$Name]) {
        return $Object.$Name
    }

    return $Fallback
}

function Read-IndexSelection {
    <#
    .SYNOPSIS
        读取用户输入的序号选择。
    .DESCRIPTION
        支持：
          - Enter：返回空
          - 单个编号：1
          - 多个编号：1,3,5
          - 范围：2-4
          - A：全选
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object[]]$Items,

        [Parameter(Mandatory = $true)]
        [string]$Prompt,

        [switch]$AllowEmpty
    )

    if ($Items.Count -eq 0) {
        return @()
    }

    while ($true) {
        $raw = Read-Host $Prompt

        if ([string]::IsNullOrWhiteSpace($raw)) {
            if ($AllowEmpty) { return @() }
            Write-Warn "Please enter at least one selection."
            continue
        }

        if ($raw -match '^[Aa]$') {
            return @(0..($Items.Count - 1))
        }

        $set = [System.Collections.Generic.HashSet[int]]::new()

        try {
            $tokens = @($raw -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ })
            foreach ($token in $tokens) {
                if ($token -match '^(\d+)-(\d+)$') {
                    $start = [int]$matches[1]
                    $end   = [int]$matches[2]

                    if ($start -gt $end) {
                        $tmp = $start
                        $start = $end
                        $end = $tmp
                    }

                    for ($i = $start; $i -le $end; $i++) {
                        if ($i -lt 1 -or $i -gt $Items.Count) {
                            throw "Selection '$i' out of range."
                        }
                        [void]$set.Add($i - 1)
                    }
                } elseif ($token -match '^\d+$') {
                    $index = [int]$token
                    if ($index -lt 1 -or $index -gt $Items.Count) {
                        throw "Selection '$index' out of range."
                    }
                    [void]$set.Add($index - 1)
                } else {
                    throw "Invalid token '$token'."
                }
            }

            return @($set | Sort-Object)
        } catch {
            Write-Warn $_
            Write-Host "  Use numbers like: 1,3,5-7 or A for all." -ForegroundColor DarkGray
        }
    }
}

function Get-ScoopGroupObjects {
    <#
    .SYNOPSIS
        将 manifest.scoopGroups 转成便于排序和交互展示的对象列表。
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$Manifest
    )

    if (-not $Manifest.PSObject.Properties["scoopGroups"] -or $null -eq $Manifest.scoopGroups) {
        return @()
    }

    $groups = @()

    foreach ($groupProp in $Manifest.scoopGroups.PSObject.Properties) {
        $groupId = [string]$groupProp.Name
        $group   = $groupProp.Value

        $packageCount = 0
        $buckets = Get-ObjectPropValue -Object $group -Name "buckets" -Fallback $null
        if ($null -ne $buckets) {
            foreach ($bucketProp in $buckets.PSObject.Properties) {
                $packageCount += @($bucketProp.Value).Count
            }
        }

        $groups += [PSCustomObject]@{
            Id              = $groupId
            Title           = [string](Get-ObjectPropValue -Object $group -Name "title" -Fallback $groupId)
            Description     = [string](Get-ObjectPropValue -Object $group -Name "description" -Fallback "")
            Selection       = [string](Get-ObjectPropValue -Object $group -Name "selection" -Fallback "optional")
            PromptOrder     = [int](Get-ObjectPropValue -Object $group -Name "promptOrder" -Fallback 999)
            InstallPriority = [int](Get-ObjectPropValue -Object $group -Name "installPriority" -Fallback 500)
            Buckets         = $buckets
            PackageOptions  = Get-ObjectPropValue -Object $group -Name "packageOptions" -Fallback $null
            PackageCount    = $packageCount
        }
    }

    return @($groups | Sort-Object PromptOrder, InstallPriority, Title)
}

function Get-GroupPackageSpecs {
    <#
    .SYNOPSIS
        展开某个组下的 bucket/package 列表，并合并 packageOptions。
    .DESCRIPTION
        输出的规格对象统一包含：
          - PackageRef
          - Selection
          - InstallMode
          - InstallPriority
          - RequiresAdmin
          - Notes
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$Group
    )

    $specs = @()

    if ($null -eq $Group.Buckets) {
        return @()
    }

    foreach ($bucketProp in $Group.Buckets.PSObject.Properties) {
        $bucketName = [string]$bucketProp.Name
        $bucketPackages = @($bucketProp.Value)
        $bucketOptions = $null

        if ($null -ne $Group.PackageOptions -and $Group.PackageOptions.PSObject.Properties[$bucketName]) {
            $bucketOptions = $Group.PackageOptions.$bucketName
        }

        foreach ($pkg in $bucketPackages) {
            $packageName = [string]$pkg
            $override = $null

            if ($null -ne $bucketOptions -and $bucketOptions.PSObject.Properties[$packageName]) {
                $override = $bucketOptions.$packageName
            }

            $selection = [string](Get-ObjectPropValue -Object $override -Name "selection" -Fallback "required")
            $installMode = [string](Get-ObjectPropValue -Object $override -Name "installMode" -Fallback "auto")
            $installPriority = [int](Get-ObjectPropValue -Object $override -Name "installPriority" -Fallback $Group.InstallPriority)
            $requiresAdmin = [bool](Get-ObjectPropValue -Object $override -Name "requiresAdmin" -Fallback $false)
            $notes = [string](Get-ObjectPropValue -Object $override -Name "notes" -Fallback "")

            $packageRef = if ($bucketName -and $bucketName -ne "main") { "$bucketName/$packageName" } else { $packageName }

            $specs += [PSCustomObject]@{
                GroupId         = $Group.Id
                GroupTitle      = $Group.Title
                Bucket          = $bucketName
                Name            = $packageName
                PackageRef      = $packageRef
                Selection       = $selection
                InstallMode     = $installMode
                InstallPriority = $installPriority
                RequiresAdmin   = $requiresAdmin
                Notes           = $notes
            }
        }
    }

    return @($specs | Sort-Object InstallPriority, Bucket, Name)
}

function Resolve-SelectedScoopGroups {
    <#
    .SYNOPSIS
        交互式选择 default / optional 组。
    .DESCRIPTION
        - default 组：默认安装，允许跳过
        - optional 组：默认不安装，允许选择
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$Manifest
    )

    $groups = @(Get-ScoopGroupObjects -Manifest $Manifest)
    if ($groups.Count -eq 0) {
        return @()
    }

    $defaultGroups  = @($groups | Where-Object { $_.Selection -eq "default" })
    $optionalGroups = @($groups | Where-Object { $_.Selection -eq "optional" })

    $selected = New-Object System.Collections.Generic.List[object]

    if ($defaultGroups.Count -gt 0) {
        Write-Host "  Default groups (installed unless you skip them):" -ForegroundColor Gray
        for ($i = 0; $i -lt $defaultGroups.Count; $i++) {
            $g = $defaultGroups[$i]
            Write-Host ("    [{0}] {1} ({2} packages)" -f ($i + 1), $g.Title, $g.PackageCount) -ForegroundColor White
            if ($g.Description) {
                Write-Host ("         {0}" -f $g.Description) -ForegroundColor DarkGray
            }
        }

        $skipIndices = Read-IndexSelection -Items $defaultGroups -Prompt "Skip any default groups? [Enter=none, numbers, A=all]" -AllowEmpty
        for ($i = 0; $i -lt $defaultGroups.Count; $i++) {
            if ($skipIndices -notcontains $i) {
                [void]$selected.Add($defaultGroups[$i])
            }
        }
    }

    if ($optionalGroups.Count -gt 0) {
        Write-Host ""
        Write-Host "  Optional groups:" -ForegroundColor Gray
        for ($i = 0; $i -lt $optionalGroups.Count; $i++) {
            $g = $optionalGroups[$i]
            Write-Host ("    [{0}] {1} ({2} packages)" -f ($i + 1), $g.Title, $g.PackageCount) -ForegroundColor White
            if ($g.Description) {
                Write-Host ("         {0}" -f $g.Description) -ForegroundColor DarkGray
            }
        }

        $includeIndices = Read-IndexSelection -Items $optionalGroups -Prompt "Select optional groups to install [Enter=none, numbers, A=all]" -AllowEmpty
        foreach ($index in $includeIndices) {
            [void]$selected.Add($optionalGroups[$index])
        }
    }

    return @($selected | Sort-Object InstallPriority, PromptOrder, Title -Unique)
}

function Resolve-SelectedGroupPackages {
    <#
    .SYNOPSIS
        对已经选中的组，处理组内 packageOptions.selection=optional 的二级选择。
    .DESCRIPTION
        组内包规则：
          - selection = required/default/未写：默认自动安装
          - selection = optional：进入二级选择
          - installMode = manual：即使被选中，也只提示手动处理
          - installMode = skip：直接忽略
    #>
    param(
        [Parameter(Mandatory = $true)]
        [object]$Group
    )

    $allSpecs = @(Get-GroupPackageSpecs -Group $Group)
    if ($allSpecs.Count -eq 0) {
        return @()
    }

    $alwaysSpecs   = @($allSpecs | Where-Object { $_.Selection -ne "optional" -and $_.InstallMode -ne "skip" })
    $optionalSpecs = @($allSpecs | Where-Object { $_.Selection -eq "optional" -and $_.InstallMode -ne "skip" })

    if ($optionalSpecs.Count -eq 0) {
        return @($alwaysSpecs | Sort-Object InstallPriority, Bucket, Name)
    }

    Write-Host ""
    Write-Host "  Optional packages in group: $($Group.Title)" -ForegroundColor Gray
    for ($i = 0; $i -lt $optionalSpecs.Count; $i++) {
        $pkg = $optionalSpecs[$i]
        $tags = @()

        if ($pkg.InstallMode -eq "manual") { $tags += "manual" }
        if ($pkg.RequiresAdmin) { $tags += "admin" }

        $tagSuffix = if ($tags.Count -gt 0) { " [" + ($tags -join ", ") + "]" } else { "" }
        Write-Host ("    [{0}] {1}{2}" -f ($i + 1), $pkg.PackageRef, $tagSuffix) -ForegroundColor White
        if ($pkg.Notes) {
            Write-Host ("         {0}" -f $pkg.Notes) -ForegroundColor DarkGray
        }
    }

    $includeIndices = Read-IndexSelection -Items $optionalSpecs -Prompt "Select optional packages for '$($Group.Title)' [Enter=none, numbers, A=all]" -AllowEmpty
    $selectedOptional = @()
    foreach ($index in $includeIndices) {
        $selectedOptional += $optionalSpecs[$index]
    }

    return @($alwaysSpecs + $selectedOptional | Sort-Object InstallPriority, Bucket, Name)
}

$selectedGroups = @(Resolve-SelectedScoopGroups -Manifest $windowsPackages)

if ($selectedGroups.Count -eq 0) {
    Write-Host "  No default/optional Scoop groups selected." -ForegroundColor DarkGray
    Write-OK "Selected Scoop group installation complete"
    return
}

$plannedPackages = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$manualPackages  = New-Object System.Collections.Generic.List[object]

foreach ($group in $selectedGroups) {
    Write-Host ""
    Write-Host ("  Group: {0}" -f $group.Title) -ForegroundColor Cyan

    $groupPackages = @(Resolve-SelectedGroupPackages -Group $group)

    if ($groupPackages.Count -eq 0) {
        Write-Host "    No packages selected in this group." -ForegroundColor DarkGray
        continue
    }

    foreach ($pkg in $groupPackages) {
        if ($plannedPackages.Contains($pkg.PackageRef)) {
            Write-Host ("    Skip duplicate package: {0}" -f $pkg.PackageRef) -ForegroundColor DarkGray
            continue
        }

        [void]$plannedPackages.Add($pkg.PackageRef)

        if ($pkg.InstallMode -eq "skip") {
            continue
        }

        if ($pkg.InstallMode -eq "manual") {
            [void]$manualPackages.Add($pkg)
            Write-Warn "Manual package skipped: $($pkg.PackageRef)"
            if ($pkg.Notes) {
                Write-Host ("      {0}" -f $pkg.Notes) -ForegroundColor DarkGray
            }
            continue
        }

        Install-ScoopApp -App $pkg.Name -Bucket $pkg.Bucket
    }
}

if ($manualPackages.Count -gt 0) {
    Write-Host ""
    Write-Step "Manual Scoop Packages"
    foreach ($pkg in $manualPackages) {
        Write-Warn "$($pkg.GroupTitle): $($pkg.PackageRef)"
        if ($pkg.Notes) {
            Write-Host ("    {0}" -f $pkg.Notes) -ForegroundColor DarkGray
        }
    }
}

Write-OK "Selected Scoop groups installed"
