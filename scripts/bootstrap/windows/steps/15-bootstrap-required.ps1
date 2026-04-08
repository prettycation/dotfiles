param(
    [Parameter(Mandatory = $true)]
    $Context
)

$ErrorActionPreference = "Stop"

Write-Step "Installing Required Scoop Groups"

# 说明：
#   这一步只处理 scoopGroups 中 selection = required 的组。
#   它的目标是尽早装好 bootstrap 后续真正依赖的工具链，例如：
#     - git
#     - pwsh
#     - chezmoi
#     - bitwarden-cli

# 行为规则：
#   1. 只看 group.selection = required 的组
#   2. 如果某个包在 packageOptions 里被标记 selection = optional，则本步骤跳过它
#      （它应留给后续更细的组内选择逻辑处理）
#   3. installMode = manual 的包不自动安装，只汇总提醒
#   4. installMode = skip 的包直接跳过
#   5. 如果本次新装了 pwsh，并且当前还不是在 pwsh 中运行，则提示切换到 pwsh 后重跑

$windowsPackages = $Context.WindowsPackages
if ($null -eq $windowsPackages) {
    throw "Context.WindowsPackages is null."
}

Assert-ManifestHasScoopGroups -WindowsPackages $windowsPackages

function Get-ObjectPropValue {
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

function Get-RequiredGroupObjects {
    param(
        [Parameter(Mandatory = $true)]
        [object]$Manifest
    )

    $result = @()

    if (-not $Manifest.PSObject.Properties["scoopGroups"] -or $null -eq $Manifest.scoopGroups) {
        return @()
    }

    foreach ($groupProp in $Manifest.scoopGroups.PSObject.Properties) {
        $groupId = [string]$groupProp.Name
        $group   = $groupProp.Value

        $selection = [string](Get-ObjectPropValue -Object $group -Name "selection" -Fallback "optional")
        if ($selection -ne "required") {
            continue
        }

        $result += [PSCustomObject]@{
            Id              = $groupId
            Title           = [string](Get-ObjectPropValue -Object $group -Name "title" -Fallback $groupId)
            Description     = [string](Get-ObjectPropValue -Object $group -Name "description" -Fallback "")
            Selection       = $selection
            PromptOrder     = [int](Get-ObjectPropValue -Object $group -Name "promptOrder" -Fallback 999)
            InstallPriority = [int](Get-ObjectPropValue -Object $group -Name "installPriority" -Fallback 500)
            Buckets         = Get-ObjectPropValue -Object $group -Name "buckets" -Fallback $null
            PackageOptions  = Get-ObjectPropValue -Object $group -Name "packageOptions" -Fallback $null
        }
    }

    return @($result | Sort-Object InstallPriority, PromptOrder, Title)
}

function Get-RequiredGroupPackageSpecs {
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
        $packageNames = @($bucketProp.Value)
        $bucketPackageOptions = $null

        if ($null -ne $Group.PackageOptions -and $Group.PackageOptions.PSObject.Properties[$bucketName]) {
            $bucketPackageOptions = $Group.PackageOptions.$bucketName
        }

        foreach ($pkg in $packageNames) {
            $packageName = [string]$pkg
            $packageOption = $null

            if ($null -ne $bucketPackageOptions -and $bucketPackageOptions.PSObject.Properties[$packageName]) {
                $packageOption = $bucketPackageOptions.$packageName
            }

            # 对 required group 来说：
            # - 包级 selection=optional => 本阶段跳过，留给后续更细的交互逻辑
            # - 包级 selection 未写 / required / default => 本阶段安装
            $packageSelection = [string](Get-ObjectPropValue -Object $packageOption -Name "selection" -Fallback "required")
            if ($packageSelection -eq "optional") {
                continue
            }

            $installMode = [string](Get-ObjectPropValue -Object $packageOption -Name "installMode" -Fallback "auto")
            if ($installMode -eq "skip") {
                continue
            }

            $packagePriority = [int](Get-ObjectPropValue -Object $packageOption -Name "installPriority" -Fallback $Group.InstallPriority)
            $requiresAdmin   = [bool](Get-ObjectPropValue -Object $packageOption -Name "requiresAdmin" -Fallback $false)
            $notes           = [string](Get-ObjectPropValue -Object $packageOption -Name "notes" -Fallback "")

            $packageRef = if ($bucketName -and $bucketName -ne "main") { "$bucketName/$packageName" } else { $packageName }

            $specs += [PSCustomObject]@{
                GroupId            = $Group.Id
                GroupTitle         = $Group.Title
                GroupInstallPriority = [int]$Group.InstallPriority
                Bucket             = $bucketName
                Name               = $packageName
                PackageRef         = $packageRef
                Selection          = $packageSelection
                InstallMode        = $installMode
                InstallPriority    = $packagePriority
                RequiresAdmin      = $requiresAdmin
                Notes              = $notes
            }
        }
    }

    return @($specs | Sort-Object GroupInstallPriority, InstallPriority, Bucket, Name)
}

$requiredGroups = @(Get-RequiredGroupObjects -Manifest $windowsPackages)

if ($requiredGroups.Count -eq 0) {
    Write-Host "  No required Scoop groups found." -ForegroundColor DarkGray
    Write-OK "Required Scoop group step complete"
    return
}

Write-Host "  Required groups to install:" -ForegroundColor Gray
foreach ($group in $requiredGroups) {
    Write-Host ("    - {0} [{1}]" -f $group.Title, $group.Id) -ForegroundColor White
    if ($group.Description) {
        Write-Host ("      {0}" -f $group.Description) -ForegroundColor DarkGray
    }
}

$hadPwshBefore = Test-CommandExists "pwsh"
$runningInsidePwsh = ($PSVersionTable.PSEdition -eq "Core")

$plannedPackages = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$manualPackages  = New-Object System.Collections.Generic.List[object]

foreach ($group in $requiredGroups) {
    Write-Host ""
    Write-Host ("  Group: {0}" -f $group.Title) -ForegroundColor Cyan

    $packageSpecs = @(Get-RequiredGroupPackageSpecs -Group $group)
    if ($packageSpecs.Count -eq 0) {
        Write-Host "    No auto-install packages in this required group." -ForegroundColor DarkGray
        continue
    }

    foreach ($pkg in $packageSpecs) {
        if ($plannedPackages.Contains($pkg.PackageRef)) {
            Write-Host ("    Skip duplicate package: {0}" -f $pkg.PackageRef) -ForegroundColor DarkGray
            continue
        }

        [void]$plannedPackages.Add($pkg.PackageRef)

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

# 新装了 pwsh 后刷新 PATH，确保同一会话能探测到它。
Update-PathEnvironment

$hasPwshAfter = Test-CommandExists "pwsh"

if (-not $hadPwshBefore -and $hasPwshAfter -and -not $runningInsidePwsh) {
    Write-Host "`n============================================================" -ForegroundColor Green
    Write-Host "  ✓  PowerShell 7 installed successfully!" -ForegroundColor Green
    Write-Host "============================================================" -ForegroundColor Green
    Write-Host ""
    Write-Host "Please CLOSE this window and re-run bootstrap under PowerShell 7 (pwsh)." -ForegroundColor Cyan
    Write-Host "This ensures later steps run in the intended shell environment." -ForegroundColor Gray
    exit 0
}

if ($manualPackages.Count -gt 0) {
    Write-Host ""
    Write-Warn "Required group packages that need manual handling:"
    foreach ($pkg in $manualPackages) {
        Write-Warn "  $($pkg.PackageRef) [$($pkg.GroupTitle)]"
        if ($pkg.Notes) {
            Write-Host ("      {0}" -f $pkg.Notes) -ForegroundColor DarkGray
        }
    }
}

Write-OK "Required Scoop groups installed"
