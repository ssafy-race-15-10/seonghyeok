param(
    [int]$Runs    = 5,
    [int]$Warmup  = 3,
    [int]$Cooldown = 2
)

$AlgoExe    = "$PSScriptRoot\Algo.exe"
$BotJavaDir = "$PSScriptRoot\..\Bot_Java"

# 사전 확인
if (-not (Test-Path $AlgoExe)) {
    Write-Error "Algo.exe not found: $AlgoExe"
    exit 1
}
if (-not (Test-Path $BotJavaDir)) {
    Write-Error "Bot_Java directory not found: $BotJavaDir"
    exit 1
}

# java.exe 탐색 (PATH → JAVA_HOME → 일반 설치 경로 순)
$JavaExe = "java"
if (-not (Get-Command java -ErrorAction SilentlyContinue)) {
    $candidates = @(
        "$env:JAVA_HOME\bin\java.exe",
        "C:\Program Files\Java\jdk*\bin\java.exe",
        "C:\Program Files\Eclipse Adoptium\*\bin\java.exe",
        "C:\Program Files\Microsoft\jdk*\bin\java.exe",
        "C:\Program Files\JetBrains\*\jbr\bin\java.exe"
    )
    $found = $null
    foreach ($pattern in $candidates) {
        $found = Get-Item $pattern -ErrorAction SilentlyContinue | Select-Object -Last 1
        if ($found) { $JavaExe = $found.FullName; break }
    }
    if (-not $found) {
        Write-Error "java.exe를 찾을 수 없습니다. JAVA_HOME 환경변수를 설정하거나 Java를 PATH에 추가하세요."
        exit 1
    }
    Write-Host "Using java: $JavaExe"
}

try {
    for ($i = 1; $i -le $Runs; $i++) {
        Write-Host "=== Run $i/$Runs ===" -ForegroundColor Cyan
        Stop-Process -Name "Algo" -Force -ErrorAction SilentlyContinue

        # 1. 시뮬레이터 시작
        $algo = Start-Process -FilePath $AlgoExe `
                              -ArgumentList "-ResX=640 -ResY=480 -windowed" `
                              -PassThru
        Start-Sleep -Seconds $Warmup

        # 2. MyCar 실행 (종료될 때까지 대기)
        $java = Start-Process -FilePath $JavaExe `
                              -ArgumentList "-cp .;DrivingInterface -Djava.library.path=DrivingInterface MyCar" `
                              -WorkingDirectory $BotJavaDir `
                              -NoNewWindow `
                              -Wait `
                              -PassThru
        Write-Host "Exit code: $($java.ExitCode)"
        if ($java.ExitCode -ne 0) {
            Write-Warning "Run $i ended with non-zero exit code: $($java.ExitCode)"
        }

        # 3. 시뮬레이터 종료
        Stop-Process -Name "Algo" -Force -ErrorAction SilentlyContinue
        Write-Host "Algo stopped. Waiting ${Cooldown}s..."
        Start-Sleep -Seconds $Cooldown
    }
} finally {
    Stop-Process -Name "Algo" -Force -ErrorAction SilentlyContinue
}

Write-Host "All $Runs runs complete." -ForegroundColor Green
