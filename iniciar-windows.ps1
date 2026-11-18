[CmdletBinding()]
param(
    [switch]$SetupOnly
)

$ErrorActionPreference = "Stop"

$RootDir = $PSScriptRoot
$AppDir = Join-Path $RootDir "app"
$BancoDir = Join-Path $RootDir "banco"
$InitSqlPath = Join-Path $BancoDir "init.sql"
$MysqlBaseDir = Join-Path $RootDir ".mysql-win"
$MysqlAppDir = Join-Path $MysqlBaseDir "mysql"
$MysqlDataDir = Join-Path $MysqlBaseDir "data"
$MysqlIniPath = Join-Path $MysqlBaseDir "my.ini"
$MysqlErrLog = Join-Path $MysqlBaseDir "mysql-error.log"
$MysqlExe = Join-Path $MysqlAppDir "bin\mysql.exe"
$MysqldExe = Join-Path $MysqlAppDir "bin\mysqld.exe"
$MysqlAdminExe = Join-Path $MysqlAppDir "bin\mysqladmin.exe"

function Write-Info([string]$Msg) {
    Write-Host "[INFO] $Msg" -ForegroundColor Cyan
}

function Write-Ok([string]$Msg) {
    Write-Host "[OK]   $Msg" -ForegroundColor Green
}

function Write-Warn([string]$Msg) {
    Write-Host "[AVISO] $Msg" -ForegroundColor Yellow
}

function Test-PortOpen([string]$HostName = "127.0.0.1", [int]$Port = 3306, [int]$TimeoutMs = 400) {
    $client = New-Object System.Net.Sockets.TcpClient
    try {
        $iar = $client.BeginConnect($HostName, $Port, $null, $null)
        if ($iar.AsyncWaitHandle.WaitOne($TimeoutMs, $false)) {
            $client.EndConnect($iar)
            return $true
        }
        return $false
    } catch {
        return $false
    } finally {
        $client.Close()
    }
}

function Resolve-Mysql8ZipUrl {
    Write-Info "Consultando a versao mais recente do MySQL 8.0 para Windows..."
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    $candidateUrls = @()

    try {
        $resp = Invoke-WebRequest -UseBasicParsing -Uri "https://dev.mysql.com/downloads/mysql/8.0.html?os=2" -TimeoutSec 15
        $regexMatches = [regex]::Matches($resp.Content, "mysql-(8\.0\.\d+)-winx64\.zip")
        foreach ($m in $regexMatches) {
            $ver = $m.Groups[1].Value
            $url = "https://cdn.mysql.com/Downloads/MySQL-8.0/mysql-$ver-winx64.zip"
            if ($candidateUrls -notcontains $url) {
                $candidateUrls += $url
            }
        }
    } catch {
        Write-Warn "Nao foi possivel consultar a pagina de downloads do MySQL; tentando versoes conhecidas."
    }

    foreach ($ver in @("8.0.45", "8.0.44", "8.0.43", "8.0.42", "8.0.41", "8.0.40", "8.0.39")) {
        $url = "https://cdn.mysql.com/Downloads/MySQL-8.0/mysql-$ver-winx64.zip"
        if ($candidateUrls -notcontains $url) {
            $candidateUrls += $url
        }
    }

    foreach ($url in $candidateUrls) {
        try {
            $req = [System.Net.HttpWebRequest]::Create($url)
            $req.Method = "HEAD"
            $req.Timeout = 10000
            $res = $req.GetResponse()
            $status = [int]$res.StatusCode
            $res.Close()
            if ($status -ge 200 -and $status -lt 400) {
                return $url
            }
        } catch {
            continue
        }
    }

    throw "Nao foi possivel localizar uma URL valida do MySQL 8.0 ZIP para Windows."
}

function Ensure-VcRedist {
    $dll1 = Join-Path $env:SystemRoot "System32\vcruntime140_1.dll"
    $dll2 = Join-Path $env:SystemRoot "System32\msvcp140.dll"
    if ((Test-Path $dll1) -and (Test-Path $dll2)) {
        return
    }

    Write-Warn "Visual C++ Redistributable x64 nao detectado (necessario para o MySQL 8)."
    $winget = Get-Command winget -ErrorAction SilentlyContinue
    if ($winget) {
        Write-Info "Tentando instalar Microsoft.VCRedist.2015+.x64 via winget..."
        & $winget.Source install --id Microsoft.VCRedist.2015+.x64 --silent --accept-package-agreements --accept-source-agreements
        if ((Test-Path $dll1) -and (Test-Path $dll2)) {
            Write-Ok "Visual C++ Redistributable instalado."
            return
        }
    }

    $vcInstaller = Join-Path $MysqlBaseDir "vc_redist.x64.exe"
    Write-Info "Baixando vc_redist.x64.exe oficial da Microsoft..."
    Invoke-FileDownload -Url "https://aka.ms/vs/17/release/vc_redist.x64.exe" -Destination $vcInstaller
    Write-Info "Executando instalador do Visual C++ Redistributable (pode solicitar permissao)..."
    $proc = Start-Process -FilePath $vcInstaller -ArgumentList "/install", "/passive", "/norestart" -Wait -PassThru
    Remove-Item $vcInstaller -Force -ErrorAction SilentlyContinue
    if ($proc.ExitCode -ne 0 -and $proc.ExitCode -ne 3010) {
        throw "Falha ao instalar Visual C++ Redistributable (codigo $($proc.ExitCode))."
    }
}

function Invoke-FileDownload([string]$Url, [string]$Destination) {
    $curl = Get-Command curl.exe -ErrorAction SilentlyContinue
    if ($curl) {
        & $curl.Source -fL --retry 3 --progress-bar -o $Destination $Url
        if ($LASTEXITCODE -eq 0 -and (Test-Path $Destination)) {
            return
        }
        Write-Warn "curl.exe falhou (codigo $LASTEXITCODE); tentando fallback PowerShell..."
    }

    $prevProgress = $ProgressPreference
    try {
        $ProgressPreference = "SilentlyContinue"
        Invoke-WebRequest -UseBasicParsing -Uri $Url -OutFile $Destination
    } finally {
        $ProgressPreference = $prevProgress
    }
}

function Expand-ZipFast([string]$ZipPath, [string]$DestDir) {
    $tar = Get-Command tar.exe -ErrorAction SilentlyContinue
    if ($tar) {
        & $tar.Source -xf $ZipPath -C $DestDir
        if ($LASTEXITCODE -eq 0) {
            return
        }
        Write-Warn "tar.exe falhou; usando Expand-Archive..."
    }
    Expand-Archive -Path $ZipPath -DestinationPath $DestDir -Force
}

function Ensure-PortableMysqlInstalled {
    if ((Test-Path $MysqldExe) -and (Test-Path $MysqlExe)) {
        Write-Ok "MySQL 8 portatil ja baixado em .mysql-win\mysql."
        return
    }

    New-Item -ItemType Directory -Force -Path $MysqlBaseDir | Out-Null
    Ensure-VcRedist

    $zipUrl = Resolve-Mysql8ZipUrl
    $zipName = Split-Path $zipUrl -Leaf
    $zipPath = Join-Path $MysqlBaseDir $zipName
    $extractTmp = Join-Path $MysqlBaseDir "extract_tmp"

    if (Test-Path $extractTmp) {
        Remove-Item -Recurse -Force $extractTmp
    }

    Write-Info "Baixando MySQL 8.0 portatil ($zipName)..."
    Invoke-FileDownload -Url $zipUrl -Destination $zipPath

    Write-Info "Extraindo MySQL 8.0..."
    New-Item -ItemType Directory -Force -Path $extractTmp | Out-Null
    Expand-ZipFast -ZipPath $zipPath -DestDir $extractTmp

    $extractedRoot = Get-ChildItem -Path $extractTmp -Directory | Select-Object -First 1
    if (-not $extractedRoot) {
        throw "Estrutura inesperada ao extrair $zipName."
    }

    if (Test-Path $MysqlAppDir) {
        Remove-Item -Recurse -Force $MysqlAppDir
    }
    Move-Item -Path $extractedRoot.FullName -Destination $MysqlAppDir
    Remove-Item -Recurse -Force $extractTmp
    Remove-Item -Force $zipPath -ErrorAction SilentlyContinue

    if (-not (Test-Path $MysqldExe)) {
        throw "Binario mysqld.exe nao encontrado apos extracao."
    }
    Write-Ok "MySQL 8.0 portatil extraido com sucesso."
}

function Write-MysqlConfig {
    $baseSlash = $MysqlAppDir -replace "\\", "/"
    $dataSlash = $MysqlDataDir -replace "\\", "/"
    $errSlash = $MysqlErrLog -replace "\\", "/"

    $iniContent = @"
[mysqld]
basedir="$baseSlash"
datadir="$dataSlash"
log-error="$errSlash"
port=3306
bind-address=127.0.0.1,::1
character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
default-authentication-plugin=mysql_native_password
"@
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($MysqlIniPath, $iniContent, $utf8NoBom)
}

function Ensure-PortableMysqlRunning {
    if (Test-PortOpen -HostName "127.0.0.1" -Port 3306) {
        Write-Ok "MySQL ja esta respondendo na porta 3306."
        return
    }

    Ensure-PortableMysqlInstalled
    New-Item -ItemType Directory -Force -Path $MysqlDataDir | Out-Null
    Write-MysqlConfig

    $isFreshInit = -not (Test-Path (Join-Path $MysqlDataDir "mysql"))
    if ($isFreshInit) {
        Write-Info "Inicializando banco de dados MySQL local (--initialize-insecure)..."
        $initProc = Start-Process -FilePath $MysqldExe -ArgumentList "--defaults-file=`"$MysqlIniPath`"", "--initialize-insecure" -Wait -PassThru -WindowStyle Hidden
        if ($initProc.ExitCode -ne 0) {
            if (Test-Path $MysqlErrLog) {
                Get-Content $MysqlErrLog -Tail 30 | Write-Host -ForegroundColor Red
            }
            throw "Falha ao inicializar MySQL (codigo $($initProc.ExitCode))."
        }
        Write-Ok "Diretorio de dados inicializado."
    }

    Write-Info "Iniciando servidor MySQL 8 local na porta 3306..."
    $proc = Start-Process -FilePath $MysqldExe -ArgumentList "--defaults-file=`"$MysqlIniPath`"" -PassThru -WindowStyle Hidden

    $ready = $false
    for ($i = 0; $i -lt 60; $i++) {
        if ($proc.HasExited) {
            if (Test-Path $MysqlErrLog) {
                Get-Content $MysqlErrLog -Tail 30 | Write-Host -ForegroundColor Red
            }
            throw "O processo mysqld.exe encerrou inesperadamente (codigo $($proc.ExitCode))."
        }
        if (Test-PortOpen -HostName "127.0.0.1" -Port 3306 -TimeoutMs 300) {
            $ready = $true
            break
        }
        Start-Sleep -Milliseconds 500
    }

    if (-not $ready) {
        throw "Tempo esgotado aguardando o MySQL responder na porta 3306."
    }
    Write-Ok "MySQL 8 rodando em localhost:3306 (PID $($proc.Id))."

    if ($isFreshInit) {
        Configure-RootAndImportTechStore
    }
}

function Invoke-MysqlQuery([string]$Password, [string]$Sql) {
    $args = @("--default-character-set=utf8mb4", "-h", "127.0.0.1", "-P", "3306", "-u", "root", "-N", "-B", "-e", $Sql)
    $prevPwd = $env:MYSQL_PWD
    $prevPref = $ErrorActionPreference
    try {
        if ($Password -ne "") {
            $env:MYSQL_PWD = $Password
        } else {
            Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue
        }
        $ErrorActionPreference = "Continue"
        $output = & $MysqlExe @args 2>&1
        $code = $LASTEXITCODE
    } finally {
        $ErrorActionPreference = $prevPref
        if ($null -ne $prevPwd) {
            $env:MYSQL_PWD = $prevPwd
        } else {
            Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue
        }
    }
    return @{
        ExitCode = $code
        Output   = ($output -join "`n")
    }
}

function Configure-RootAndImportTechStore {
    Write-Info "Configurando usuario root e importando banco/init.sql..."

    $setupSql = @"
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'root';
CREATE USER IF NOT EXISTS 'root'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY 'root';
ALTER USER 'root'@'127.0.0.1' IDENTIFIED WITH mysql_native_password BY 'root';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'127.0.0.1' WITH GRANT OPTION;
CREATE USER IF NOT EXISTS 'root'@'::1' IDENTIFIED WITH mysql_native_password BY 'root';
ALTER USER 'root'@'::1' IDENTIFIED WITH mysql_native_password BY 'root';
GRANT ALL PRIVILEGES ON *.* TO 'root'@'::1' WITH GRANT OPTION;
FLUSH PRIVILEGES;
"@

    # Tenta primeiro sem senha (logo apos --initialize-insecure); se falhar, tenta com senha root
    $res = Invoke-MysqlQuery -Password "" -Sql $setupSql
    if ($res.ExitCode -ne 0) {
        $resRoot = Invoke-MysqlQuery -Password "root" -Sql $setupSql
        if ($resRoot.ExitCode -ne 0) {
            throw "Nao foi possivel configurar o usuario root no MySQL: $($resRoot.Output)"
        }
    }

    $prevPwd = $env:MYSQL_PWD
    try {
        $env:MYSQL_PWD = "root"
        $importProc = Start-Process -FilePath $MysqlExe `
            -ArgumentList "--default-character-set=utf8mb4", "-h", "127.0.0.1", "-P", "3306", "-u", "root" `
            -RedirectStandardInput $InitSqlPath `
            -Wait -PassThru -WindowStyle Hidden
    } finally {
        if ($null -ne $prevPwd) {
            $env:MYSQL_PWD = $prevPwd
        } else {
            Remove-Item Env:MYSQL_PWD -ErrorAction SilentlyContinue
        }
    }

    if ($importProc.ExitCode -ne 0) {
        throw "Erro ao importar banco/init.sql (codigo $($importProc.ExitCode))."
    }
    Write-Ok "Banco TechStore importado com sucesso!"
}

function Ensure-TechStoreSeeded {
    if (-not (Test-Path $MysqlExe)) {
        return
    }
    $check = Invoke-MysqlQuery -Password "root" -Sql "SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='techstore' AND table_name='pedidos';"
    if ($check.ExitCode -eq 0 -and $check.Output.Trim() -eq "1") {
        Write-Ok "Banco 'techstore' verificado e pronto."
        return
    }
    Configure-RootAndImportTechStore
}

Write-Host ""
Write-Host "=== TechStore CLI — Setup & Execucao Automatica (Windows) ===" -ForegroundColor Cyan

# 1. Validar Node.js e npm
$nodeCmd = Get-Command node -ErrorAction SilentlyContinue
$npmCmd = Get-Command npm -ErrorAction SilentlyContinue
if (-not $nodeCmd -or -not $npmCmd) {
    throw "Node.js e npm precisam estar instalados e no PATH."
}
$nodeVer = & $nodeCmd.Source -v
$npmVer = & $npmCmd.Source -v
Write-Ok "Node $nodeVer | npm $npmVer"

# 2. Garantir MySQL 8 rodando e banco techstore importado
Ensure-PortableMysqlRunning
Ensure-TechStoreSeeded

# 3. Garantir app/.env
$envPath = Join-Path $AppDir ".env"
$envExamplePath = Join-Path $AppDir ".env.example"
if (-not (Test-Path $envPath)) {
    Copy-Item $envExamplePath $envPath
    Write-Ok "Arquivo app\.env criado a partir de .env.example."
} else {
    Write-Ok "Arquivo app\.env ja existe."
}

# 4. Instalar dependencias npm em app/ se necessario
$nodeModulesDir = Join-Path $AppDir "node_modules"
if (-not (Test-Path $nodeModulesDir)) {
    Write-Info "Instalando dependencias npm em app/..."
    Push-Location $AppDir
    try {
        & $npmCmd.Source install
        if ($LASTEXITCODE -ne 0) {
            throw "npm install falhou (codigo $LASTEXITCODE)."
        }
    } finally {
        Pop-Location
    }
    Write-Ok "Dependencias instaladas."
} else {
    Write-Ok "Dependencias em app\node_modules ja instaladas."
}

# 5. Gerar PrismaClient se necessario
$prismaSchemaMarker = Join-Path $AppDir "node_modules\.prisma\client\schema.prisma"
if (-not (Test-Path $prismaSchemaMarker)) {
    Write-Info "Gerando PrismaClient (npx prisma generate)..."
    Push-Location $AppDir
    try {
        & npx prisma generate
        if ($LASTEXITCODE -ne 0) {
            throw "npx prisma generate falhou (codigo $LASTEXITCODE)."
        }
    } finally {
        Pop-Location
    }
    Write-Ok "PrismaClient gerado."
} else {
    Write-Ok "PrismaClient ja gerado."
}

# 6. Iniciar aplicacao ou finalizar se -SetupOnly
if ($SetupOnly) {
    Write-Host ""
    Write-Ok "Setup concluido! Para abrir o menu interativo, execute: npm start"
    exit 0
}

Write-Host ""
Write-Info "Iniciando TechStore CLI (npm start em app/)..."
Push-Location $AppDir
try {
    & $npmCmd.Source start
} finally {
    Pop-Location
}
