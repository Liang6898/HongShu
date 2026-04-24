# HongShu 开发环境配置脚本
# 双击运行，或在 PowerShell 中执行
# 需要管理员权限（用于设置系统 PATH）

$ErrorActionPreference = "Stop"

Write-Host "=== HongShu 开发环境配置 ===" -ForegroundColor Cyan

# 1. 找 Java
$javaDir = "C:\Program Files\Eclipse Adoptium\jdk-8.0.482.8-hotspot"
$javaBin = "$javaDir\bin\java.exe"
if (Test-Path $javaBin) {
    Write-Host "[OK] Java found: $javaBin" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Java not found at $javaBin" -ForegroundColor Red
    exit 1
}

# 2. 找 Maven
$mavenDir = "C:\apache-maven-3.9.15"
$mavenBin = "$mavenDir\bin\mvn.cmd"
if (Test-Path $mavenBin) {
    Write-Host "[OK] Maven found: $mavenBin" -ForegroundColor Green
} else {
    Write-Host "[ERROR] Maven not found at $mavenBin" -ForegroundColor Red
    exit 1
}

# 3. 写 .env 文件到 HongShu 目录（方便所有 Agent 读取）
$envFile = "$PSScriptRoot\..\HongShu-master\.env.dev"
$envContent = @"
# HongShu 开发环境变量
JAVA_HOME=$javaDir
MAVEN_HOME=$mavenDir
PATH=$javaDir\bin;$mavenDir\bin;`$PATH

# 数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_NAME=hongshu
DB_USER=root
DB_PASSWORD=root123456

# Redis 配置
REDIS_HOST=localhost
REDIS_PORT=6379

# 后端端口
BACKEND_PORT=8080
"@
Set-Content -Path $envFile -Value $envContent -Encoding UTF8
Write-Host "[OK] .env.dev written: $envFile" -ForegroundColor Green

# 4. 验证
Write-Host ""
Write-Host "=== 验证环境 ===" -ForegroundColor Cyan
& "$javaBin" -version 2>&1 | Select-Object -First 1
& "$mavenBin" -version 2>&1 | Select-Object -First 1
docker --version
git --version

Write-Host ""
Write-Host "=== 环境就绪 ===" -ForegroundColor Green
Write-Host "下一步：运行 dev-setup.ps1 进行 Docker 和数据库初始化"
