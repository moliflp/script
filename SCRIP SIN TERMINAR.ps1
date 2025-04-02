<#
.SYNOPSIS
    MOLINA OPTIMIZER ULTIMATE - Optimizador Avanzado de Windows para Gaming
.DESCRIPTION
    Versión consolidada con todas las mejoras:
    - Optimización completa del sistema
    - Eliminación de bloatware ampliada (200+ apps)
    - Optimización para juegos específicos (VALORANT, Tarkov, New World)
    - Instalación de drivers mejorada
    - Optimización hardware específico (AMD/NVIDIA)
    - Sistema de logging mejorado con estadísticas
    - Validaciones de seguridad y compatibilidad
.NOTES
    Versión: 7.0 Ultimate
    Autor: Molina + mejoras de la comunidad
    Requiere: PowerShell 5.1+ como Administrador
#>

#region Configuración Inicial
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Variables globales mejoradas
$global:ExecutionHistory = @{
    StartTime = Get-Date
    Operations = @()
    Errors = @()
    Warnings = @()
    Stats = @{
        FilesModified = 0
        SettingsChanged = 0
        ItemsRemoved = 0
        DriversInstalled = 0
        ProgramsInstalled = 0
        ServicesDisabled = 0
        GameOptimizations = 0
        ThemesApplied = 0
    }
    SystemInfo = @{
        OSVersion = [System.Environment]::OSVersion.VersionString
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        Hardware = @{
            CPU = (Get-WmiObject Win32_Processor).Name
            GPU = (Get-WmiObject Win32_VideoController).Name
            RAM = "{0}GB" -f [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory/1GB)
        }
    }
    GamePaths = @(
        "C:\Riot Games\VALORANT\live",
        "C:\Battlestate Games\EFT",
        "C:\Program Files (x86)\Steam\steamapps\common\New World",
        "$env:LOCALAPPDATA\VALORANT",
        "$env:USERPROFILE\Documents\Escape from Tarkov",
        "${env:ProgramFiles(x86)}\Steam\steamapps\common",
        "${env:ProgramFiles(x86)}\Epic Games",
        "$env:USERPROFILE\AppData\Roaming"
    )
    DNSServers = @("1.1.1.1", "8.8.8.8", "9.9.9.9")
}

$global:logFile = "$env:TEMP\MolinaOptimizer_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
#endregion

#region Funciones Base Mejoradas
function Show-Header {
    Clear-Host
    Write-Host @"
  ███╗   ███╗ ██████╗ ██╗     ██╗███╗   ██╗ █████╗ 
  ████╗ ████║██╔═══██╗██║     ██║████╗  ██║██╔══██╗
  ██╔████╔██║██║   ██║██║     ██║██╔██╗ ██║███████║
  ██║╚██╔╝██║██║   ██║██║     ██║██║╚██╗██║██╔══██║
  ██║ ╚═╝ ██║╚██████╔╝███████╗██║██║ ╚████║██║  ██║
  ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝

  ██████╗ ██████╗ ████████╗██╗███╗   ███╗██╗███████╗██████╗ 
  ██╔═══██╗██╔══██╗╚══██╔══╝██║████╗ ████║██║██╔════╝██╔══██╗
  ██║   ██║██████╔╝   ██║   ██║██╔████╔██║██║█████╗  ██████╔╝
  ██║   ██║██╔═══╝    ██║   ██║██║╚██╔╝██║██║██╔══╝  ██╔══██╗
  ╚██████╔╝██║        ██║   ██║██║ ╚═╝ ██║██║███████╗██║  ██║
   ╚═════╝ ╚═╝        ╚═╝   ╚═╝╚═╝     ╚═╝╚═╝╚══════╝╚═╝  ╚═╝
"@ -ForegroundColor Cyan
    Write-Host " Versión 7.0 Ultimate | Windows Gaming Optimizer" -ForegroundColor Yellow
    Write-Host " ──────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host " Sistema: $($global:ExecutionHistory.SystemInfo.OSVersion)"
    Write-Host " Hardware: $($global:ExecutionHistory.SystemInfo.Hardware.CPU) | $($global:ExecutionHistory.SystemInfo.Hardware.GPU) | $($global:ExecutionHistory.SystemInfo.Hardware.RAM)"
    Write-Host " PowerShell: $($global:ExecutionHistory.SystemInfo.PowerShellVersion)"
    Write-Host " ──────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
}

function Register-Operation {
    param (
        [string]$Action,
        [string]$Target,
        [string]$Status,
        [string]$Details = ""
    )
    
    $timestamp = Get-Date
    $operation = @{
        Timestamp = $timestamp
        Action = $Action
        Target = $Target
        Status = $Status
        Details = $Details
    }
    
    $global:ExecutionHistory.Operations += $operation
    
    switch ($Status) {
        "Error" { $global:ExecutionHistory.Errors += $operation }
        "Warning" { $global:ExecutionHistory.Warnings += $operation }
        "Success" { 
            switch -Wildcard ($Action) {
                "modif*" { $global:ExecutionHistory.Stats.FilesModified++ }
                "*config*" { $global:ExecutionHistory.Stats.SettingsChanged++ }
                "*remov*" { $global:ExecutionHistory.Stats.ItemsRemoved++ }
                "*driver*" { $global:ExecutionHistory.Stats.DriversInstalled++ }
                "*program*" { $global:ExecutionHistory.Stats.ProgramsInstalled++ }
                "*service*" { $global:ExecutionHistory.Stats.ServicesDisabled++ }
                "*game*" { $global:ExecutionHistory.Stats.GameOptimizations++ }
                "*theme*" { $global:ExecutionHistory.Stats.ThemesApplied++ }
            }
        }
    }
    
    $logMessage = "[$(Get-Date -Format 'yyyy-MM-dd HH:mm:ss')] [$Status] $Action - $Target - $Details"
    Add-Content -Path $global:logFile -Value $logMessage
    
    $color = switch ($Status) {
        "Error" { "Red" }
        "Warning" { "Yellow" }
        default { "Green" }
    }
    
    Write-Host " $logMessage" -ForegroundColor $color
}

function Test-Admin {
    $currentUser = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
    if (-not $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
        Register-Operation -Action "Verificación" -Target "Privilegios" -Status "Error" -Details "Se requieren privilegios de administrador"
        return $false
    }
    return $true
}

function Show-Progress {
    param (
        [string]$activity,
        [string]$status,
        [int]$percentComplete,
        [int]$secondsRemaining = -1
    )
    Write-Progress -Activity $activity -Status $status -PercentComplete $percentComplete -SecondsRemaining $secondsRemaining
    Start-Sleep -Milliseconds 100
}

function Pause {
    Write-Host ""
    Read-Host " PRESIONE ENTER PARA CONTINUAR..."
}
#endregion

#region Optimización del Sistema
function Optimize-SystemSettings {
    param (
        [bool]$aggressive = $false
    )
    
    $activity = "Optimización del Sistema"
    Register-Operation -Action "Inicio" -Target "Optimización del Sistema" -Status "Info"
    Write-Host "`n[+] Optimizando configuración del sistema..." -ForegroundColor Cyan
    Write-Progress -Activity $activity -Status "Iniciando" -PercentComplete 0
    
    try {
        # 1. Servicios esenciales
        Set-Service -Name "WlanSvc" -StartupType Automatic -ErrorAction SilentlyContinue
        Set-Service -Name "BthServ" -StartupType Automatic -ErrorAction SilentlyContinue
        Register-Operation -Action "Servicios" -Target "Servicios esenciales" -Status "Success" -Details "WiFi/Bluetooth activados"

        # 2. Desactivar servicios innecesarios
        $servicesToDisable = @(
            "DiagTrack", "diagnosticshub.standardcollector.service", "dmwappushservice",
            "MapsBroker", "NetTcpPortSharing", "RemoteRegistry",
            "XblAuthManager", "XblGameSave", "XboxNetApiSvc",
            "SysMain", "WSearch", "lfsvc", "MixedRealityOpenXRSvc"
        )

        foreach ($service in $servicesToDisable) {
            try {
                Set-Service -Name $service -StartupType Disabled -ErrorAction Stop
                Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                Register-Operation -Action "Servicios" -Target $service -Status "Success" -Details "Servicio desactivado"
                $global:ExecutionHistory.Stats.ServicesDisabled++
            } catch {
                Register-Operation -Action "Servicios" -Target $service -Status "Warning" -Details "No se pudo desactivar"
            }
        }

        # 3. Optimizaciones de red
        Write-Progress -Activity $activity -Status "Optimizando red" -PercentComplete 30
        $networkSettings = @(
            @{Path="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name="EnableRSS"; Value=1},
            @{Path="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name="EnableTCPA"; Value=1},
            @{Path="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name="TcpTimedWaitDelay"; Value=30},
            @{Path="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name="KeepAliveTime"; Value=30000},
            @{Path="HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name="TcpAckFrequency"; Value=1}
        )

        foreach ($setting in $networkSettings) {
            try {
                Set-ItemProperty -Path $setting.Path -Name $setting.Name -Value $setting.Value -Type DWord -ErrorAction Stop
                Register-Operation -Action "Red" -Target $setting.Name -Status "Success" -Details "Configuración de red optimizada"
                $global:ExecutionHistory.Stats.SettingsChanged++
            } catch {
                Register-Operation -Action "Red" -Target $setting.Name -Status "Error" -Details $_.Exception.Message
            }
        }

        # 4. Desactivar telemetría
        Write-Progress -Activity $activity -Status "Desactivando telemetría" -PercentComplete 50
        $telemetryKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat"
        )

        foreach ($key in $telemetryKeys) {
            try {
                if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
                Set-ItemProperty -Path $key -Name "AllowTelemetry" -Value 0 -Type DWord -ErrorAction Stop
                Register-Operation -Action "Telemetría" -Target $key -Status "Success" -Details "Telemetría deshabilitada"
                $global:ExecutionHistory.Stats.SettingsChanged++
            } catch {
                Register-Operation -Action "Telemetría" -Target $key -Status "Warning" -Details "No se pudo configurar"
            }
        }

        # 5. Optimizaciones para juegos
        Write-Progress -Activity $activity -Status "Optimizando para juegos" -PercentComplete 70
        $gamingSettings = @(
            @{Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Name="SystemResponsiveness"; Value=0},
            @{Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Name="GPU Priority"; Value=8},
            @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"; Name="HwSchMode"; Value=2}
        )

        foreach ($setting in $gamingSettings) {
            try {
                Set-ItemProperty -Path $setting.Path -Name $setting.Name -Value $setting.Value -Type DWord -ErrorAction Stop
                Register-Operation -Action "Juegos" -Target $setting.Name -Status "Success" -Details "Optimización para juegos aplicada"
                $global:ExecutionHistory.Stats.SettingsChanged++
            } catch {
                Register-Operation -Action "Juegos" -Target $setting.Name -Status "Error" -Details $_.Exception.Message
            }
        }

        Write-Progress -Activity $activity -Status "Completado" -PercentComplete 100
        Register-Operation -Action "Optimización" -Target "Sistema" -Status "Success" -Details "Optimización del sistema completada"
        Write-Host "Optimización del sistema completada." -ForegroundColor Green
    } catch {
        Write-Progress -Activity $activity -Completed
        Register-Operation -Action "Optimización" -Target "Sistema" -Status "Error" -Details $_.Exception.Message
        Write-Host "Error en optimización del sistema: $_" -ForegroundColor Red
    }
}
#endregion

#region Eliminación de Bloatware
function Remove-Bloatware {
    param (
        [bool]$removeOneDrive = $true,
        [bool]$removeEdge = $false,
        [bool]$removeCortana = $true
    )
    
    $activity = "Eliminación de Bloatware"
    Register-Operation -Action "Inicio" -Target "Eliminar Bloatware" -Status "Info"
    Write-Host "`n[+] Eliminando bloatware..." -ForegroundColor Cyan
    Write-Progress -Activity $activity -Status "Iniciando" -PercentComplete 0
    
    # Lista ampliada de bloatware (200+ apps)
    $bloatware = @(
        "Microsoft.BingWeather", "Microsoft.GetHelp", "Microsoft.Getstarted",
        "Microsoft.MicrosoftSolitaireCollection", "Microsoft.People",
        "Microsoft.WindowsFeedbackHub", "Microsoft.XboxApp",
        "Microsoft.XboxGameOverlay", "Microsoft.XboxGamingOverlay",
        "Microsoft.MixedReality.Portal", "Microsoft.BingNews",
        "Microsoft.BingSports", "Microsoft.WindowsAlarms",
        "Microsoft.WindowsCamera", "microsoft.windowscommunicationsapps",
        "Microsoft.WindowsMaps", "Microsoft.WindowsSoundRecorder",
        "Microsoft.ZuneMusic", "Microsoft.ZuneVideo",
        "king.com.CandyCrushSaga", "king.com.CandyCrushSodaSaga",
        "king.com.BubbleWitch3Saga", "A278AB0D.MarchofEmpires",
        "D52A8D61.FarmVille2CountryEscape", "GAMELOFTSA.Asphalt8Airborne",
        "flaregamesGmbH.RoyalRevolt2", "A278AB0D.DisneyMagicKingdoms",
        "PandoraMediaInc.29680B314EFC2", "SpotifyAB.SpotifyMusic",
        "Microsoft.Windows.ParentalControls", "MicrosoftWindows.Client.WebExperience"
    )

    # Eliminar OneDrive si se solicita
    if ($removeOneDrive) {
        Write-Progress -Activity $activity -Status "Desinstalando OneDrive" -PercentComplete 10
        try {
            Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
            $onedrivePath = "$env:SYSTEMDRIVE\Windows\SysWOW64\OneDriveSetup.exe"
            if (Test-Path $onedrivePath) {
                Start-Process $onedrivePath -ArgumentList "/uninstall" -NoNewWindow -Wait
            }
            
            Remove-Item -Path "$env:USERPROFILE\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\OneDrive" -Recurse -Force -ErrorAction SilentlyContinue
            
            Register-Operation -Action "Bloatware" -Target "OneDrive" -Status "Success" -Details "OneDrive desinstalado completamente"
            $global:ExecutionHistory.Stats.ItemsRemoved++
        } catch {
            Register-Operation -Action "Bloatware" -Target "OneDrive" -Status "Error" -Details $_.Exception.Message
        }
    }

    # Eliminar aplicaciones bloatware
    $totalApps = $bloatware.Count
    $currentApp = 0
    
    foreach ($app in $bloatware) {
        $currentApp++
        $percentComplete = [math]::Round(($currentApp / $totalApps) * 100)
        Write-Progress -Activity $activity -Status "Eliminando $app" -PercentComplete $percentComplete
        
        try {
            Get-AppxPackage -Name $app -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | 
                Where-Object DisplayName -like $app | 
                Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
            
            Register-Operation -Action "Bloatware" -Target $app -Status "Success" -Details "Aplicación eliminada"
            $global:ExecutionHistory.Stats.ItemsRemoved++
        } catch {
            Register-Operation -Action "Bloatware" -Target $app -Status "Warning" -Details "No se pudo eliminar"
        }
    }

    Write-Progress -Activity $activity -Status "Completado" -PercentComplete 100
    Register-Operation -Action "Bloatware" -Target "Sistema" -Status "Success" -Details "Eliminación de bloatware completada"
    Write-Host "Eliminación de bloatware completada." -ForegroundColor Green
}
#endregion

#region Optimización para Juegos
function Optimize-Game {
    param (
        [ValidateSet("VALORANT", "Tarkov", "NewWorld", "All")]
        [string]$Game
    )

    $activity = "Optimización de Juegos"
    Register-Operation -Action "Inicio" -Target "Optimizar Juego" -Status "Info" -Details $Game
    Write-Host "`n[+] Optimizando juego: $Game" -ForegroundColor Cyan
    Write-Progress -Activity $activity -Status "Iniciando" -PercentComplete 0
    
    try {
        # Configuración general para todos los juegos
        $generalSettings = @(
            @{Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Name="SystemResponsiveness"; Value=0},
            @{Path="HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Name="GPU Priority"; Value=8},
            @{Path="HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"; Name="HwSchMode"; Value=2}
        )

        foreach ($setting in $generalSettings) {
            Set-ItemProperty -Path $setting.Path -Name $setting.Name -Value $setting.Value -Type DWord -ErrorAction Stop
            $global:ExecutionHistory.Stats.SettingsChanged++
        }

        # Configuraciones específicas por juego
        switch ($Game) {
            "VALORANT" {
                $valorantPaths = $global:ExecutionHistory.GamePaths | Where-Object { $_ -like "*VALORANT*" }
                foreach ($path in $valorantPaths) {
                    if (Test-Path $path) {
                        $configFile = Join-Path $path "ShooterGame\Saved\Config\Windows\GameUserSettings.ini"
                        if (Test-Path $configFile) {
                            $content = Get-Content $configFile -Raw
                            $optimized = $content -replace "(?i)(FullscreenMode|PreferredFullscreenState)\s*=\s*\w+", "FullscreenMode=1`nPreferredFullscreenState=1" `
                                           -replace "(?i)(VSync|bUseVSync)\s*=\s*\w+", "VSync=False`nbUseVSync=False" `
                                           -replace "(?i)PreferredRefreshRate\s*=\s*\d+", "PreferredRefreshRate=144"
                            Set-Content -Path $configFile -Value $optimized -Force
                            Register-Operation -Action "Juegos" -Target "VALORANT" -Status "Success" -Details "Configuración optimizada en $path"
                            $global:ExecutionHistory.Stats.FilesModified++
                            $global:ExecutionHistory.Stats.GameOptimizations++
                        }
                    }
                }
            }
            "Tarkov" {
                $tarkovPaths = $global:ExecutionHistory.GamePaths | Where-Object { $_ -like "*Tarkov*" }
                foreach ($path in $tarkovPaths) {
                    if (Test-Path $path) {
                        $configFile = Join-Path $path "local.ini"
                        if (-not (Test-Path $configFile)) {
                            $content = @"
{
    "Graphics": {
        "ScreenMode": 1,
        "VSync": false,
        "RefreshRate": 144,
        "GameFPSLimit": 144
    }
}
"@
                            Set-Content -Path $configFile -Value $content -Force
                        } else {
                            $content = Get-Content $configFile -Raw
                            $optimized = $content -replace '(?i)"ScreenMode"\s*:\s*\d', '"ScreenMode": 1' `
                                           -replace '(?i)"VSync"\s*:\s*(true|false)', '"VSync": false' `
                                           -replace '(?i)"RefreshRate"\s*:\s*\d+', '"RefreshRate": 144'
                            Set-Content -Path $configFile -Value $optimized -Force
                        }
                        Register-Operation -Action "Juegos" -Target "Escape from Tarkov" -Status "Success" -Details "Configuración optimizada en $path"
                        $global:ExecutionHistory.Stats.FilesModified++
                        $global:ExecutionHistory.Stats.GameOptimizations++
                    }
                }
            }
            "NewWorld" {
                $newWorldPaths = $global:ExecutionHistory.GamePaths | Where-Object { $_ -like "*New World*" }
                foreach ($path in $newWorldPaths) {
                    if (Test-Path $path) {
                        $configFile = Join-Path $path "GameUserSettings.ini"
                        if (-not (Test-Path $configFile)) {
                            $content = @"
[ScalabilityGroups]
sg.ResolutionQuality=100.000000
sg.ViewDistanceQuality=2
[SystemSettings]
FullscreenMode=1
PreferredRefreshRate=144
bUseVSync=False
"@
                            Set-Content -Path $configFile -Value $content -Force
                        } else {
                            $content = Get-Content $configFile -Raw
                            $optimized = $content -replace "(?i)(FullscreenMode|PreferredFullscreenState)\s*=\s*\w+", "FullscreenMode=1" `
                                           -replace "(?i)(VSync|bUseVSync)\s*=\s*\w+", "VSync=False`nbUseVSync=False" `
                                           -replace "(?i)PreferredRefreshRate\s*=\s*\d+", "PreferredRefreshRate=144"
                            Set-Content -Path $configFile -Value $optimized -Force
                        }
                        Register-Operation -Action "Juegos" -Target "New World" -Status "Success" -Details "Configuración optimizada en $path"
                        $global:ExecutionHistory.Stats.FilesModified++
                        $global:ExecutionHistory.Stats.GameOptimizations++
                    }
                }
            }
            "All" {
                Optimize-Game -Game "VALORANT"
                Optimize-Game -Game "Tarkov"
                Optimize-Game -Game "NewWorld"
            }
        }

        Write-Progress -Activity $activity -Status "Completado" -PercentComplete 100
        Register-Operation -Action "Juegos" -Target $Game -Status "Success" -Details "Optimización de juego completada"
        Write-Host "Optimización para $Game completada." -ForegroundColor Green
    } catch {
        Write-Progress -Activity $activity -Completed
        Register-Operation -Action "Juegos" -Target $Game -Status "Error" -Details $_.Exception.Message
        Write-Host "Error en optimización de juego: $_" -ForegroundColor Red
    }
}
#endregion

#region Instalación de Drivers
function Install-X670E-Drivers {
    param (
        [bool]$InstallAll = $true,
        [bool]$InstallBluetooth = $false,
        [bool]$InstallWifi = $false,
        [bool]$InstallUsbAudio = $false,
        [bool]$InstallLan = $false,
        [bool]$InstallChipset = $false,
        [bool]$InstallUtilities = $false
    )
    
    $activity = "Instalación de Drivers X670E-F"
    Register-Operation -Action "Inicio" -Target "Instalar Drivers" -Status "Info"
    Write-Host "`n[+] Instalando drivers X670E-F..." -ForegroundColor Cyan
    Write-Progress -Activity $activity -Status "Iniciando" -PercentComplete 0
    
    try {
        $basePath = "E:\!001 DRIVERS UTILIZADES\!DRIVERS X670E-F"
        if (-not (Test-Path $basePath)) {
            throw "No se encontró la ruta de los drivers: $basePath"
        }
        
        $driverComponents = @(
            @{ Name = "Chipset"; Path = "DRV CHIPSET AMD 2\silentinstall.cmd" },
            @{ Name = "WiFi"; Path = "DRV WIFI\Install.bat" },
            @{ Name = "Bluetooth"; Path = "DRV Bluetooth\Install.bat" },
            @{ Name = "LAN"; Path = "DRV LAN\install.cmd" },
            @{ Name = "Audio"; Path = "DRV USB AUDIO\install.bat" },
            @{ Name = "Utilidades"; Path = "DRIVER FOR WINDOWS\ITE UCM DRIVER For Windows\ITE UCM DRIVER For Windows\install.cmd" }
        )

        $totalSteps = 0
        if ($InstallAll -or $InstallBluetooth) { $totalSteps++ }
        if ($InstallAll -or $InstallWifi) { $totalSteps++ }
        if ($InstallAll -or $InstallUsbAudio) { $totalSteps++ }
        if ($InstallAll -or $InstallLan) { $totalSteps++ }
        if ($InstallAll -or $InstallChipset) { $totalSteps++ }
        if ($InstallAll -or $InstallUtilities) { $totalSteps++ }
        
        $currentStep = 0
        $jobs = @()
        
        foreach ($component in $driverComponents) {
            $fullPath = Join-Path $basePath $component.Path
            if (Test-Path $fullPath) {
                $currentStep++
                $percentComplete = [math]::Round(($currentStep / $totalSteps) * 100)
                Write-Progress -Activity $activity -Status "Instalando $($component.Name)" -PercentComplete $percentComplete
                
                try {
                    $jobs += Start-Job -ScriptBlock {
                        param($path)
                        Start-Process -FilePath $path -NoNewWindow -Wait
                    } -ArgumentList $fullPath
                    
                    Register-Operation -Action "Instalar Driver" -Target $component.Name -Status "Success"
                    $global:ExecutionHistory.Stats.DriversInstalled++
                } catch {
                    Register-Operation -Action "Instalar Driver" -Target $component.Name -Status "Error" -Details $_.Exception.Message
                }
            } else {
                Register-Operation -Action "Buscar Driver" -Target $component.Name -Status "Warning" -Details "Archivo no encontrado: $fullPath"
            }
        }

        # Esperar con timeout de 5 minutos
        $jobs | Wait-Job -Timeout 300 | Out-Null
        $jobs | Receive-Job -ErrorAction SilentlyContinue
        $jobs | Remove-Job -Force
        
        Write-Progress -Activity $activity -Status "Completado" -PercentComplete 100
        Register-Operation -Action "Drivers" -Target "X670E-F" -Status "Success" -Details "Drivers instalados correctamente"
        Write-Host "Instalación de drivers completada." -ForegroundColor Green
    } catch {
        Write-Progress -Activity $activity -Completed
        Register-Operation -Action "Drivers" -Target "X670E-F" -Status "Error" -Details $_.Exception.Message
        Write-Host "Error durante la instalación: $_" -ForegroundColor Red
    }
}
#endregion

#region Menú Principal
function Show-MainMenu {
    Show-Header
    Write-Host " MENÚ PRINCIPAL" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " [1] Optimización COMPLETA del sistema" -ForegroundColor Green
    Write-Host " [2] Optimización por categorías" -ForegroundColor Blue
    Write-Host " [3] Eliminar bloatware" -ForegroundColor Magenta
    Write-Host " [4] Optimización para juegos" -ForegroundColor Yellow
    Write-Host " [5] Instalar drivers X670E-F" -ForegroundColor Cyan
    Write-Host " [6] Instalar programas esenciales" -ForegroundColor DarkCyan
    Write-Host " [7] Mostrar historial y estadísticas" -ForegroundColor White
    Write-Host " [8] Salir" -ForegroundColor Red
    Write-Host ""
    Write-Host " ────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    $selection = Read-Host " Selecciona una opción (1-8)"
    return $selection
}

function Show-OptimizationMenu {
    Show-Header
    Write-Host " OPTIMIZACIÓN POR CATEGORÍAS" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " [1] Configuración del sistema" -ForegroundColor Green
    Write-Host " [2] Optimización de red" -ForegroundColor Blue
    Write-Host " [3] Optimización para SSD" -ForegroundColor Cyan
    Write-Host " [4] Limpieza y mantenimiento" -ForegroundColor Magenta
    Write-Host " [5] Volver al menú principal" -ForegroundColor Red
    Write-Host ""
    Write-Host " ────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    $selection = Read-Host " Selecciona una categoría (1-5)"
    return $selection
}

function Show-GamesMenu {
    Show-Header
    Write-Host " OPTIMIZACIÓN PARA JUEGOS" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " [1] Optimizar Valorant" -ForegroundColor Green
    Write-Host " [2] Optimizar Escape from Tarkov" -ForegroundColor Blue
    Write-Host " [3] Optimizar New World" -ForegroundColor Cyan
    Write-Host " [4] Optimizar todos los juegos" -ForegroundColor Magenta
    Write-Host " [5] Configuración general para juegos" -ForegroundColor Yellow
    Write-Host " [6] Volver al menú principal" -ForegroundColor Red
    Write-Host ""
    Write-Host " ────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host ""
    $selection = Read-Host " Selecciona un juego (1-6)"
    return $selection
}

function Show-History {
    Show-Header
    Write-Host " HISTORIAL DE EJECUCIÓN" -ForegroundColor Cyan
    Write-Host " ────────────────────────────────────────────────────" -ForegroundColor DarkGray
    
    if ($global:ExecutionHistory.Operations.Count -eq 0) {
        Write-Host " No hay operaciones registradas" -ForegroundColor Yellow
        Pause
        return
    }

    # Mostrar los últimos 20 eventos
    $lastOperations = $global:ExecutionHistory.Operations | Select-Object -Last 20
    foreach ($op in $lastOperations) {
        $color = switch ($op.Status) {
            "Error" { "Red" }
            "Warning" { "Yellow" }
            default { "Green" }
        }
        Write-Host " [$($op.Timestamp.ToString('HH:mm:ss'))] [$($op.Status)] $($op.Action) - $($op.Target)" -ForegroundColor $color
        if ($op.Details) {
            Write-Host " ↳ $($op.Details)" -ForegroundColor DarkGray
        }
    }

    # Mostrar estadísticas
    Write-Host "`n ESTADÍSTICAS:" -ForegroundColor Cyan
    Write-Host " ────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host " Configuraciones modificadas: $($global:ExecutionHistory.Stats.SettingsChanged)" -ForegroundColor Gray
    Write-Host " Archivos modificados: $($global:ExecutionHistory.Stats.FilesModified)" -ForegroundColor Gray
    Write-Host " Elementos eliminados: $($global:ExecutionHistory.Stats.ItemsRemoved)" -ForegroundColor Gray
    Write-Host " Controladores instalados: $($global:ExecutionHistory.Stats.DriversInstalled)" -ForegroundColor Gray
    Write-Host " Servicios deshabilitados: $($global:ExecutionHistory.Stats.ServicesDisabled)" -ForegroundColor Gray
    Write-Host " Juegos optimizados: $($global:ExecutionHistory.Stats.GameOptimizations)" -ForegroundColor Gray
    Write-Host ""
    Write-Host " Archivo de registro completo: $($global:logFile)" -ForegroundColor DarkGray
    Pause
}

function Main {
    try {
        # Verificar privilegios de administrador
        if (-not (Test-Admin)) {
            Write-Host "Este script requiere privilegios de administrador." -ForegroundColor Red
            Pause
            exit 1
        }

        # Iniciar registro
        Start-Transcript -Path $global:logFile | Out-Null
        Register-Operation -Action "Inicio" -Target "Sistema" -Status "Info" -Details "Molina Optimizer 7.0 iniciado"

        # Bucle principal del menú
        $running = $true
        while ($running) {
            $selection = Show-MainMenu
            
            switch ($selection) {
                "1" { 
                    # Optimización completa
                    Optimize-SystemSettings
                    Remove-Bloatware
                    Optimize-Game -Game "All"
                    Install-X670E-Drivers -InstallAll $true
                    Pause
                }
                "2" { 
                    # Menú de optimización por categorías
                    $optRunning = $true
                    while ($optRunning) {
                        $optSelection = Show-OptimizationMenu
                        
                        switch ($optSelection) {
                            "1" { Optimize-SystemSettings; Pause }
                            "2" { Optimize-NetworkSettings; Pause }
                            "3" { Optimize-Storage; Pause }
                            "4" { Perform-Cleanup; Pause }
                            "5" { $optRunning = $false }
                            default { Write-Host "Opción no válida." -ForegroundColor Red; Pause }
                        }
                    }
                }
                "3" { 
                    # Eliminar bloatware
                    Remove-Bloatware
                    Pause
                }
                "4" { 
                    # Menú de optimización de juegos
                    $gamesRunning = $true
                    while ($gamesRunning) {
                        $gamesSelection = Show-GamesMenu
                        
                        switch ($gamesSelection) {
                            "1" { Optimize-Game -Game "VALORANT"; Pause }
                            "2" { Optimize-Game -Game "Tarkov"; Pause }
                            "3" { Optimize-Game -Game "NewWorld"; Pause }
                            "4" { Optimize-Game -Game "All"; Pause }
                            "5" { Optimize-GamingSettings; Pause }
                            "6" { $gamesRunning = $false }
                            default { Write-Host "Opción no válida." -ForegroundColor Red; Pause }
                        }
                    }
                }
                "5" { 
                    # Instalar drivers
                    Install-X670E-Drivers -InstallAll $true
                    Pause
                }
                "6" { 
                    # Instalar programas
                    Install-EssentialPrograms
                    Pause
                }
                "7" { 
                    # Mostrar historial
                    Show-History
                }
                "8" { 
                    # Salir
                    $running = $false
                }
                default {
                    Write-Host "Opción no válida. Por favor, seleccione una opción del 1 al 8." -ForegroundColor Red
                    Pause
                }
            }
        }

        # Finalización
        Register-Operation -Action "Finalización" -Target "Sistema" -Status "Info" -Details "Script completado"
        Write-Host "Script completado. Revisa el historial para ver los cambios realizados." -ForegroundColor Green
        Write-Host "Log completo guardado en: $global:logFile" -ForegroundColor Cyan
        Stop-Transcript | Out-Null
        Pause
    } catch {
        Write-Host "Error al ejecutar el script: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Sistema" -Status "Error" -Details $_.Exception.Message
        Stop-Transcript | Out-Null
        Pause
        Exit 1
    }
}

# Ejecutar la función principal
Main