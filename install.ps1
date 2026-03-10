#!/usr/bin/env pwsh
<#
.SYNOPSIS
    Claude Skills Enumerator 一键安装脚本

.DESCRIPTION
    自动将 Claude Skills Enumerator 安装到 Codex skills 目录

.NOTES
    File: install.ps1
    Author: Claude Skills Enumerator Project
    Version: 1.0.0
#>

#Requires -Version 5.1

param(
    [switch]$Force = $false,
    [switch]$SkipVerification = $false
)

$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"

# 颜色输出函数
function Write-ColorOutput {
    param(
        [string]$Message,
        [string]$Color = "White"
    )
    Write-Host $Message -ForegroundColor $Color
}

function Write-Success {
    param([string]$Message)
    Write-ColorOutput "✓ $Message" "Green"
}

function Write-Info {
    param([string]$Message)
    Write-ColorOutput "ℹ $Message" "Cyan"
}

function Write-Warning {
    param([string]$Message)
    Write-ColorOutput "⚠ $Message" "Yellow"
}

function Write-Error {
    param([string]$Message)
    Write-ColorOutput "✗ $Message" "Red"
}

# 检查管理员权限
function Test-Administrator {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# 检查 Python
function Test-Python {
    try {
        $version = python --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "Python 已安装: $version"
            return $true
        }
    }
    catch {
        Write-Error "未找到 Python"
        return $false
    }
    Write-Error "未找到 Python"
    return $false
}

# 检查 pip
function Test-Pip {
    try {
        $version = pip --version 2>&1
        if ($LASTEXITCODE -eq 0) {
            Write-Success "pip 已安装"
            return $true
        }
    }
    catch {
        Write-Error "未找到 pip"
        return $false
    }
    Write-Error "未找到 pip"
    return $false
}

# 检查 Python 依赖
function Test-PythonDependencies {
    Write-Info "检查 Python 依赖..."

    $missing = @()

    try {
        pip show python-frontmatter | Out-Null
        if ($LASTEXITCODE -ne 0) {
            $missing += "python-frontmatter"
        }
        else {
            Write-Success "python-frontmatter 已安装"
        }
    }
    catch {
        $missing += "python-frontmatter"
    }

    try {
        pip show pyyaml | Out-Null
        if ($LASTEXITCODE -ne 0) {
            $missing += "pyyaml"
        }
        else {
            Write-Success "pyyaml 已安装"
        }
    }
    catch {
        $missing += "pyyaml"
    }

    return $missing
}

# 安装 Python 依赖
function Install-PythonDependencies {
    Write-Info "安装 Python 依赖..."
    pip install python-frontmatter pyyaml

    if ($LASTEXITCODE -eq 0) {
        Write-Success "Python 依赖安装成功"
        return $true
    }
    else {
        Write-Error "Python 依赖安装失败"
        return $false
    }
}

# 获取项目根目录
function Get-ProjectRoot {
    $scriptPath = $PSScriptRoot
    return Split-Path -Parent $scriptPath
}

# 创建目录结构
function Initialize-Directories {
    Write-Info "创建目录结构..."

    $codexSkillsRoot = "$HOME\.codex\skills\claude-skills-enumerator"
    $scriptsDir = "$codexSkillsRoot\scripts"

    try {
        New-Item -ItemType Directory -Force -Path $scriptsDir | Out-Null
        Write-Success "目录创建成功: $codexSkillsRoot"
        return $codexSkillsRoot
    }
    catch {
        Write-Error "目录创建失败: $_"
        return $null
    }
}

# 复制文件
function Copy-ProjectFiles {
    param(
        [string]$ProjectRoot,
        [string]$TargetRoot
    )

    Write-Info "复制项目文件..."

    try {
        # 复制 SKILL.md
        Copy-Item "$ProjectRoot\SKILL.md" "$TargetRoot\SKILL.md" -Force
        Write-Success "已复制: SKILL.md"

        # 复制 list-skills.py
        Copy-Item "$ProjectRoot\scripts\list-skills.py" "$TargetRoot\scripts\list-skills.py" -Force
        Write-Success "已复制: scripts\list-skills.py"

        return $true
    }
    catch {
        Write-Error "文件复制失败: $_"
        return $false
    }
}

# 配置 AGENTS.md
function Initialize-AgentsConfig {
    param(
        [string]$ProjectRoot
    )

    Write-Info "配置 AGENTS.md..."

    $agentsFile = "$HOME\.codex\AGENTS.md"
    $sourceFile = "$ProjectRoot\AGENTS.md"

    try {
        # 检查文件是否存在
        if (Test-Path $agentsFile) {
            Write-Warning "AGENTS.md 已存在"
            $response = Read-Host "是否覆盖? (y/N)"
            if ($response -ne 'y' -and $response -ne 'Y') {
                Write-Info "跳过 AGENTS.md 配置"
                return $false
            }
        }

        # 复制文件
        Copy-Item $sourceFile $agentsFile -Force
        Write-Success "已创建: $agentsFile"
        Write-Warning "请编辑 AGENTS.md，将 'YourUsername' 替换为你的实际用户名"
        return $true
    }
    catch {
        Write-Error "AGENTS.md 配置失败: $_"
        return $false
    }
}

# 验证安装
function Test-Installation {
    Write-Info "`n验证安装..."

    $codexSkillsRoot = "$HOME\.codex\skills\claude-skills-enumerator"
    $scriptPath = "$codexSkillsRoot\scripts\list-skills.py"

    # 检查文件结构
    Write-Info "检查文件结构..."
    if (!(Test-Path "$codexSkillsRoot\SKILL.md")) {
        Write-Error "缺少文件: SKILL.md"
        return $false
    }
    Write-Success "SKILL.md 存在"

    if (!(Test-Path $scriptPath)) {
        Write-Error "缺少文件: scripts\list-skills.py"
        return $false
    }
    Write-Success "scripts\list-skills.py 存在"

    # 测试脚本
    Write-Info "测试枚举脚本..."
    $output = python $scriptPath 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Success "脚本运行成功"
        Write-Info "输出: $($output.Substring(0, [Math]::Min(200, $output.Length)))..."
        return $true
    }
    else {
        if ($output -match "error: skills directory not found") {
            Write-Warning "脚本运行正常，但 Claude Code skills 目录不存在"
            Write-Info "这是正常的，如果你还没有创建任何 Claude Code skills"
            return $true
        }
        else {
            Write-Error "脚本运行失败: $output"
            return $false
        }
    }
}

# 主安装流程
function Install-All {
    Write-ColorOutput "`n====================================" "Cyan"
    Write-ColorOutput "  Claude Skills Enumerator 安装" "Cyan"
    Write-ColorOutput "====================================`n" "Cyan"

    # 检查 Python
    Write-Info "步骤 1/6: 检查 Python"
    if (!(Test-Python)) {
        Write-Error "请先安装 Python 3.7 或更高版本"
        return $false
    }

    # 检查 pip
    Write-Info "`n步骤 2/6: 检查 pip"
    if (!(Test-Pip)) {
        Write-Error "请先安装 pip"
        return $false
    }

    # 检查/安装依赖
    Write-Info "`n步骤 3/6: 检查 Python 依赖"
    $missing = Test-PythonDependencies
    if ($missing.Count -gt 0) {
        Write-Warning "缺少依赖: $($missing -join ', ')"
        $response = Read-Host "是否立即安装? (Y/n)"
        if ($response -ne 'n' -and $response -ne 'N') {
            if (!(Install-PythonDependencies)) {
                return $false
            }
        }
        else {
            Write-Error "缺少必要的依赖，无法继续"
            return $false
        }
    }

    # 获取项目根目录
    $projectRoot = Get-ProjectRoot

    # 创建目录
    Write-Info "`n步骤 4/6: 创建目录结构"
    $targetRoot = Initialize-Directories
    if ($null -eq $targetRoot) {
        return $false
    }

    # 复制文件
    Write-Info "`n步骤 5/6: 复制项目文件"
    if (!(Copy-ProjectFiles -ProjectRoot $projectRoot -TargetRoot $targetRoot)) {
        return $false
    }

    # 配置 AGENTS.md
    Write-Info "`n步骤 6/6: 配置 AGENTS.md"
    Initialize-AgentsConfig -ProjectRoot $projectRoot

    # 验证安装
    if (!$SkipVerification) {
        Write-Info "`n步骤 7/7: 验证安装"
        if (!(Test-Installation)) {
            Write-Error "安装验证失败"
            return $false
        }
    }

    return $true
}

# 执行安装
try {
    $success = Install-All

    Write-Host "`n"
    if ($success) {
        Write-ColorOutput "====================================" "Green"
        Write-Success "安装完成！"
        Write-ColorOutput "====================================`n" "Green"

        Write-Info "后续步骤:"
        Write-Host "  1. 编辑 $HOME\.codex\AGENTS.md"
        Write-Host "     将 'YourUsername' 替换为你的实际用户名"
        Write-Host "  2. 重启 Codex"
        Write-Host "  3. 在 Codex 中询问: 'What skills are available?'"
        Write-Host "`n详细文档: [INSTALL.md](../INSTALL.md)"
    }
    else {
        Write-ColorOutput "====================================" "Red"
        Write-Error "安装失败"
        Write-ColorOutput "====================================`n" "Red"
        Write-Info "请查看错误信息并参考 [INSTALL.md](../INSTALL.md) 进行排查"
        exit 1
    }
}
catch {
    Write-Error "安装过程中发生错误: $_"
    exit 1
}
