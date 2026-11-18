[CmdletBinding()]
param()

$ErrorActionPreference = "Stop"

$RootDir = $PSScriptRoot
$MysqlAdminExe = Join-Path $RootDir ".mysql-win\mysql\bin\mysqladmin.exe"

if (-not (Test-Path $MysqlAdminExe)) {
    Write-Host "[INFO] MySQL portatil nao esta instalado em .mysql-win." -ForegroundColor Yellow
    exit 0
}

Write-Host "[INFO] Encerrando MySQL 8 portatil..." -ForegroundColor Cyan
$prevPwd = $env:MYSQL_PWD
$prevPref = $ErrorActionPreference
try {
    $env:MYSQL_PWD = "root"
    $ErrorActionPreference = "Continue"
    & $MysqlAdminExe -h 127.0.0.1 -P 3306 -u root shutdown 2>$null
    $code = $LASTEXITCODE
} finally {
    $ErrorActionPreference = $prevPref
    if ($null -ne $prevPwd) {
        $env:MYSQL_PWD = $prevPwd
    } else {
        Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue
    }
}
if ($code -eq 0) {
    Write-Host "[OK]   MySQL portatil encerrado." -ForegroundColor Green
} else {
    $procs = Get-Process mysqld -ErrorAction SilentlyContinue
    if ($procs) {
        $procs | Stop-Process -Force
        Write-Host "[OK]   Processo mysqld encerrado." -ForegroundColor Green
    } else {
        Write-Host "[INFO] Nenhum processo MySQL portatil em execucao." -ForegroundColor Yellow
    }
}
