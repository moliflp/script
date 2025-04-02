<#
.SYNOPSIS
    OPTIMIZADOR DEFINITIVO DE WINDOWS PARA GAMING - VERSIÓN 8.1 EXTENDIDA
.DESCRIPTION
    Script consolidado que combina las funcionalidades de Molina Optimizer 8.1 y Ultimate Windows Optimizer 6.1, incluyendo:
    - Optimización completa del sistema
    - Eliminación avanzada de bloatware
    - Optimización para juegos específicos (VALORANT, Tarkov, New World)
    - Instalación de drivers X670E-F con gestión de trabajos
    - Optimización de hardware (AMD Ryzen/NVIDIA/Intel)
    - Instalación de programas esenciales
    - Sistema de logging avanzado con estadísticas
    - Optimización de SSD/HDD
    - Configuración dinámica de DNS para gaming
    - Herramientas avanzadas (telemetría, Windows Update, UI, RDP, políticas)
    - Interfaz interactiva con menús detallados
.NOTES
    Versión: 8.1 Extendida
    Autor: Molina + Comunidad
    Requiere: PowerShell 5.1+ como Administrador
#>

# Configuración inicial
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

# Variables globales
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
        DNSOptimized = 0
    }
    SystemInfo = @{
        OSVersion = [System.Environment]::OSVersion.VersionString
        PowerShellVersion = $PSVersionTable.PSVersion.ToString()
        Hardware = @{
            CPU = (Get-WmiObject Win32_Processor).Name
            GPU = (Get-WmiObject Win32_VideoController).Name
            RAM = "{0}GB" -f [math]::Round((Get-WmiObject Win32_ComputerSystem).TotalPhysicalMemory/1GB)
            Storage = Get-Disk | Select-Object FriendlyName, Model, MediaType, Size | ForEach-Object {
                @{
                    Name = $_.FriendlyName
                    Model = $_.Model
                    Type = $_.MediaType
                    Size = "${:Round($_.Size/1GB})GB"
                }
            }
        }
    }
    GamePaths = @{
        VALORANT = @("C:\Riot Games\VALORANT\live", "$env:LOCALAPPDATA\VALORANT")
        Tarkov = @("C:\Battlestate Games\EFT", "C:\Games\Tarkov", "$env:USERPROFILE\Documents\Escape from Tarkov")
        NewWorld = @("C:\Program Files (x86)\Steam\steamapps\common\New World")
        CommonPaths = @(
            "${env:ProgramFiles(x86)}\Steam\steamapps\common",
            "${env:ProgramFiles(x86)}\Epic Games",
            "C:\Program Files\Epic Games",
            "$env:USERPROFILE\AppData\Roaming",
            "C:\Riot Games",
            "C:\Games"
        )
    }
    DnsServers = @("1.1.1.1", "1.0.0.1", "8.8.8.8", "8.8.4.4", "9.9.9.9", "149.112.112.112")
    BloatwareApps = @(
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
        "Microsoft.Windows.Photos", "Microsoft.WindowsCalculator",
        "Microsoft.WindowsStore", "MicrosoftWindows.Client.WebExperience"
    )
}

$global:LogFile = "$env:TEMP\UltimateOptimizer_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
$global:HardwareConfig = @{
    TargetCPU = "AMD Ryzen 7 7600X"
    TargetGPU = "NVIDIA GeForce RTX 4060"
}
$global:DriverPaths = @{
    X670E = "E:\!001 DRIVERS UTILIZADES\!DRIVERS X670E-F"
    NVIDIA = "C:\NVIDIA\DisplayDriver"
    AMD = "C:\AMD\Chipset_Drivers"
}

# region Helper Functions

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
                "*modif*" { $global:ExecutionHistory.Stats.FilesModified++ }
                "*config*" { $global:ExecutionHistory.Stats.SettingsChanged++ }
                "*elimin*" { $global:ExecutionHistory.Stats.ItemsRemoved++ }
                "*driver*" { $global:ExecutionHistory.Stats.DriversInstalled++ }
                "*programa*" { $global:ExecutionHistory.Stats.ProgramsInstalled++ }
                "*servicio*" { $global:ExecutionHistory.Stats.ServicesDisabled++ }
                "*juego*" { $global:ExecutionHistory.Stats.GameOptimizations++ }
                "*DNS*" { $global:ExecutionHistory.Stats.DNSOptimized++ }
            }
        }
    }
    
    $logMessage = "[${mm:ss'})] [$Status] $Action - $Target - $Details"
    Add-Content -Path $global:LogFile -Value $logMessage -ErrorAction SilentlyContinue
    
    $color = switch ($Status) {
        "Error" { "Red" }
        "Warning" { "Yellow" }
        default { "Green" }
    }
    
    Write-Host $logMessage -ForegroundColor $color
}

function Test-Admin {
    try {
        $currentUser = [Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()
        $isAdmin = $currentUser.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
        if (-not $isAdmin) {
            Register-Operation -Action "Verificación" -Target "Privilegios" -Status "Error" -Details "El script requiere privilegios de administrador"
        
} catch {
    Write-Host "Error desconocido en bloque try."
}}
        return $isAdmin
    } catch {
        Register-Operation -Action "Verificación" -Target "Privilegios" -Status "Error" -Details $_.Exception.Message
        return $false
    }
}

function Pause {
    Write-Host ""
    Read-Host "Presione Enter para continuar..."
}

function Show-Progress {
    param (
        [string]$activity,
        [string]$status,
        [int]$percentComplete,
        [int]$secondsRemaining = -1
    )
    $params = @{
        Activity = $activity
        Status = $status
        PercentComplete = $percentComplete
    }
    if ($secondsRemaining -ge 0) {
        $params.Add("SecondsRemaining", $secondsRemaining)
    }
    Write-Progress @params
    Start-Sleep -Milliseconds 100
}

function Invoke-WinutilThemeChange {
    param (
        [string]$theme,
        [bool]$init = $false
    )
    if ($theme -eq "Auto") {
        $theme = if ((Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme").AppsUseLightTheme -eq 0) { "Dark" } else { "Light" }
    }
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value ([int]($theme -eq "Light"))
    if (-not $init) {
        Write-Host "Tema cambiado a $theme" -ForegroundColor Cyan
        Register-Operation -Action "Cambio de tema" -Target "Interfaz" -Status "Success" -Details "Tema cambiado a $theme"
    }
}

# endregion

# region Core Optimization Functions

function Optimize-SystemFull {
    Write-Host "`n[!] INICIANDO OPTIMIZACIÓN COMPLETA DEL SISTEMA..." -ForegroundColor Cyan
    Register-Operation -Action "Inicio" -Target "Optimización Completa" -Status "Info" -Details "Proceso iniciado"

    try {
        $steps = @(
            "Optimizando configuración del sistema",
            "Eliminando bloatware",
            "Optimizando red y DNS",
            "Optimizando hardware",
            "Optimizando juegos",
            "Optimizando almacenamiento",
            "Realizando limpieza final"
        )
        
        for ($i = 0; $i -lt $steps.Count; $i++) {
            $percent = [math]::Round(($i / $steps.Count) * 100)
            Show-Progress -activity "Optimización Completa" -status $steps[$i] -percentComplete $percent
            
            switch ($i) {
                0 { Optimize-SystemSettings -aggressive $true 
} catch {
    Write-Host "Error desconocido en bloque try."
}}
                1 { Remove-Bloatware }
                2 { Optimize-NetworkDNS }
                3 { Optimize-Hardware }
                4 { Optimize-Games -GameName "All" }
                5 { Optimize-Storage }
                6 { Perform-Cleanup }
            }
        }
        
        Write-Host "`n[!] OPTIMIZACIÓN COMPLETA FINALIZADA CON ÉXITO" -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Optimización Completa" -Status "Success" -Details "Todas las optimizaciones aplicadas"
    }
    catch {
        Write-Host "`n[!] ERROR DURANTE LA OPTIMIZACIÓN: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Optimización Completa" -Status "Error" -Details $_.Exception.Message
    }
    
    Pause
}

function Optimize-SystemSettings {
    param ([bool]$aggressive = $false)
    
    Write-Host "`n[1] Optimizando configuración del sistema..." -ForegroundColor Cyan
    Register-Operation -Action "Inicio" -Target "Configuración Sistema" -Status "Info" -Details "Modo agresivo: $aggressive"

    # Servicios a deshabilitar
    $servicesToDisable = @(
        "DiagTrack", "diagnosticshub.standardcollector.service", "dmwappushservice",
        "MapsBroker", "NetTcpPortSharing", "RemoteRegistry",
        "XblAuthManager", "XblGameSave", "XboxNetApiSvc",
        "SysMain", "WSearch", "lfsvc", "MixedRealityOpenXRSvc",
        "WMPNetworkSvc", "WMPNetworkSharingService", "Fax",
        "WerSvc", "wisvc", "WpcMonSvc", "WdiServiceHost", "DPS",
        "HomeGroupListener", "HomeGroupProvider"
    )

    $servicesToEnable = @(
        "WlanSvc", "BthServ", "AudioEndpointBuilder", "Audiosrv"
    )

    foreach ($service in $servicesToDisable) {
        try {
            Set-Service -Name $service -StartupType Disabled -ErrorAction Stop
            Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
            Register-Operation -Action "Deshabilitar servicio" -Target $service -Status "Success" -Details "Servicio deshabilitado"
        
} catch {
    Write-Host "Error desconocido en bloque try."
}}
        catch {
            Register-Operation -Action "Deshabilitar servicio" -Target $service -Status "Error" -Details $_.Exception.Message
        }
    }

    foreach ($service in $servicesToEnable) {
        try {
            Set-Service -Name $service -StartupType Automatic -ErrorAction Stop
            Start-Service -Name $service -ErrorAction SilentlyContinue
            Register-Operation -Action "Habilitar servicio" -Target $service -Status "Success" -Details "Servicio habilitado"
        
} catch {
    Write-Host "Error desconocido en bloque try."
}}
        catch {
            Register-Operation -Action "Habilitar servicio" -Target $service -Status "Error" -Details $_.Exception.Message
        }
    }

    # Configuración de red
    $networkSettings = @(
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "EnableRSS"; Value = 1 },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "EnableTCPA"; Value = 1 },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "TcpTimedWaitDelay"; Value = 30 },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "KeepAliveTime"; Value = 30000 },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "DisableTaskOffload"; Value = 0 },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "TcpAckFrequency"; Value = 1 },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "TcpNoDelay"; Value = 1 },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"; Name = "DisabledComponents"; Value = 255 },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "Tcp1323Opts"; Value = 1 },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "DefaultTTL"; Value = 64 },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "EnablePMTUDiscovery"; Value = 1 },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "SackOpts"; Value = 1 }
    )

    foreach ($setting in $networkSettings) {
        try {
            Set-ItemProperty -Path $setting.Path -Name $setting.Name -Value $setting.Value -Type DWord -ErrorAction Stop
            Register-Operation -Action "Configurar red" -Target $setting.Name -Status "Success" -Details "Valor establecido a $($setting.Value)"
        
} catch {
    Write-Host "Error desconocido en bloque try."
}}
        catch {
            Register-Operation -Action "Configurar red" -Target $setting.Name -Status "Error" -Details $_.Exception.Message
        }
    }

    # Desactivar telemetría
    $telemetryKeys = @(
        "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports",
        "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy",
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
    )

    foreach ($key in $telemetryKeys) {
        try {
            if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null 
} catch {
    Write-Host "Error desconocido en bloque try."
}}
            Set-ItemProperty -Path $key -Name "AllowTelemetry" -Type DWord -Value 0
            Set-ItemProperty -Path $key -Name "DoNotShowFeedbackNotifications" -Type DWord -Value 1
            Set-ItemProperty -Path $key -Name "DisableTelemetry" -Type DWord -Value 1
            Register-Operation -Action "Deshabilitar telemetría" -Target $key -Status "Success" -Details "Configuración aplicada"
        } catch {
            Register-Operation -Action "Deshabilitar telemetría" -Target $key -Status "Error" -Details $_.Exception.Message
        }
    }

    # Desactivar Cortana
    $cortanaKeys = @(
        "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search",
        "HKLM:\SOFTWARE\Microsoft\PolicyManager\current\device\Experience"
    )
    
    foreach ($key in $cortanaKeys) {
        try {
            if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null 
} catch {
    Write-Host "Error desconocido en bloque try."
}}
            Set-ItemProperty -Path $key -Name "AllowCortana" -Type DWord -Value 0
            Set-ItemProperty -Path $key -Name "AllowSearchToUseLocation" -Type DWord -Value 0
            Set-ItemProperty -Path $key -Name "DisableWebSearch" -Type DWord -Value 1
            Register-Operation -Action "Deshabilitar Cortana" -Target $key -Status "Success" -Details "Configuración aplicada"
        } catch {
            Register-Operation -Action "Deshabilitar Cortana" -Target $key -Status "Error" -Details $_.Exception.Message
        }
    }

    # Optimizaciones para juegos
    $gamingSettings = @(
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Name = "SystemResponsiveness"; Value = 0 },
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Name = "GPU Priority"; Value = 8 },
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Name = "Priority"; Value = 6 },
        @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Name = "Scheduling Category"; Value = "High" },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"; Name = "HwSchMode"; Value = 2 },
        @{ Path = "HKCU:\System\GameConfigStore"; Name = "GameDVR_Enabled"; Value = 0 },
        @{ Path = "HKCU:\System\GameConfigStore"; Name = "GameDVR_FSEBehaviorMode"; Value = 2 },
        @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"; Name = "AllowGameDVR"; Value = 0 },
        @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name = "Win32PrioritySeparation"; Value = 26 }
    )
    
    foreach ($setting in $gamingSettings) {
        try {
            Set-ItemProperty -Path $setting.Path -Name $setting.Name -Value $setting.Value -Type DWord -ErrorAction Stop
            Register-Operation -Action "Configurar gaming" -Target $setting.Name -Status "Success" -Details "Valor establecido a $($setting.Value)"
        
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
            Register-Operation -Action "Configurar gaming" -Target $setting.Name -Status "Error" -Details $_.Exception.Message
        }
    }

    # Configuración de energía
    try {
        powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  # High Performance
        powercfg -h off
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -Type DWord -Value 0
        Register-Operation -Action "Configuración energía" -Target "Sistema" -Status "Success" -Details "Plan alto rendimiento activado"
    
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
        Register-Operation -Action "Configuración energía" -Target "Sistema" -Status "Error" -Details $_.Exception.Message
    }

    Write-Host "Optimización del sistema completada." -ForegroundColor Green
    Register-Operation -Action "Finalización" -Target "Configuración Sistema" -Status "Success" -Details "Optimización completada"
}

function Remove-Bloatware {
    Write-Host "`n[2] Eliminando bloatware..." -ForegroundColor Cyan
    Register-Operation -Action "Inicio" -Target "Eliminación de bloatware" -Status "Info" -Details "Iniciando eliminación"

    # Eliminar OneDrive
    try {
        Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
        Start-Sleep -Seconds 2
        $onedrivePath = "$env:SYSTEMDRIVE\Windows\SysWOW64\OneDriveSetup.exe"
        if (Test-Path $onedrivePath) {
            Start-Process -FilePath $onedrivePath -ArgumentList "/uninstall" -NoNewWindow -Wait
        
} catch {
    Write-Host "Error desconocido en bloque try."
}}
        $folders = @(
            "$env:USERPROFILE\OneDrive",
            "$env:LOCALAPPDATA\Microsoft\OneDrive",
            "$env:PROGRAMDATA\Microsoft OneDrive",
            "$env:SYSTEMDRIVE\OneDriveTemp"
        )
        foreach ($folder in $folders) {
            if (Test-Path $folder) {
                Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
            }
        }
        $registryPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\OneDrive",
            "HKCU:\SOFTWARE\Microsoft\OneDrive",
            "HKLM:\SOFTWARE\Microsoft\OneDrive"
        )
        foreach ($path in $registryPaths) {
            if (Test-Path $path) {
                Remove-ItemProperty -Path $path -Name "OneDrive" -ErrorAction SilentlyContinue
            }
        }
        Register-Operation -Action "Eliminar" -Target "OneDrive" -Status "Success" -Details "OneDrive desinstalado"
    } catch {
        Register-Operation -Action "Eliminar" -Target "OneDrive" -Status "Error" -Details $_.Exception.Message
    }

    # Eliminar aplicaciones preinstaladas
    foreach ($app in $global:ExecutionHistory.BloatwareApps) {
        try {
            Get-AppxPackage -Name $app -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
            Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
            Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
            Register-Operation -Action "Eliminar" -Target $app -Status "Success" -Details "Aplicación eliminada"
        
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
            Register-Operation -Action "Eliminar" -Target $app -Status "Error" -Details $_.Exception.Message
        }
    }

    # Deshabilitar características opcionales
    $featuresToDisable = @(
        "Internet-Explorer-Optional-amd64", "Printing-XPSServices-Features",
        "WorkFolders-Client", "MediaPlayback", "WindowsMediaPlayer",
        "Xps-Foundation-Xps-Viewer", "MicrosoftWindowsPowerShellV2Root",
        "MicrosoftWindowsPowerShellV2", "MSRDC-Infrastructure",
        "Windows-Defender-Default-Definitions", "Windows-Identity-Foundation"
    )

    foreach ($feature in $featuresToDisable) {
        try {
            Disable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart -ErrorAction SilentlyContinue | Out-Null
            Register-Operation -Action "Deshabilitar" -Target $feature -Status "Success" -Details "Característica deshabilitada"
        
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
            Register-Operation -Action "Deshabilitar" -Target $feature -Status "Error" -Details $_.Exception.Message
        }
    }

    # Deshabilitar Microsoft Recall y otras funciones
    try {
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsAI" -Name "DisableAIDataAnalysis" -Value 1 -Type DWord -Force
        DISM /Online /Disable-Feature /FeatureName:Recall
        Register-Operation -Action "Deshabilitar" -Target "Microsoft Recall" -Status "Success" -Details "Microsoft Recall deshabilitado"

        $serviceName = "LMS"
        Stop-Service -Name $serviceName -Force -ErrorAction SilentlyContinue
        Set-Service -Name $serviceName -StartupType Disabled -ErrorAction SilentlyContinue
        sc.exe delete $serviceName
        Get-ChildItem -Path "C:\Windows\System32\DriverStore\FileRepository" -Recurse -Filter "lms.inf*" | ForEach-Object {
            pnputil /delete-driver $_.Name /uninstall /force
        
} catch {
    Write-Host "Error desconocido en bloque try."
}}
        Get-ChildItem -Path "C:\Program Files", "C:\Program Files (x86)" -Recurse -Filter "LMS.exe" -ErrorAction SilentlyContinue | ForEach-Object {
            icacls $_.FullName /grant Administrators:F /T /C /Q
            takeown /F $_.FullName /A /R /D Y
            Remove-Item $_.FullName -Force -ErrorAction SilentlyContinue
        }
        Register-Operation -Action "Deshabilitar" -Target "Intel LMS" -Status "Success" -Details "Intel LMS deshabilitado"

        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\ActivityHistory" -Name "PublishUserActivities" -Value 0 -Type DWord -Force
        Register-Operation -Action "Deshabilitar" -Target "Historial de actividades" -Status "Success" -Details "Historial deshabilitado"

        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent" -Name "DisableConsumerFeatures" -Value 1 -Type DWord -Force
        Register-Operation -Action "Deshabilitar" -Target "Características consumidor" -Status "Success" -Details "Características deshabilitadas"

        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\lfsvc\Service\Configuration" -Name "Status" -Value 0 -Type DWord -Force
        Register-Operation -Action "Deshabilitar" -Target "Seguimiento ubicación" -Status "Success" -Details "Seguimiento deshabilitado"

        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\StorageSense\Parameters\StoragePolicy" -Name "01" -Value 0 -Type DWord -Force
        Register-Operation -Action "Deshabilitar" -Target "Storage Sense" -Status "Success" -Details "Storage Sense deshabilitado"

        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config" -Name "AutoConnectAllowedOEM" -Value 0 -Type DWord -Force
        Register-Operation -Action "Deshabilitar" -Target "Wifi-Sense" -Status "Success" -Details "Wifi-Sense deshabilitado"

        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\BackgroundAccessApplications" -Name "GlobalUserDisabled" -Value 1 -Type DWord -Force
        Register-Operation -Action "Deshabilitar" -Target "Apps en segundo plano" -Status "Success" -Details "Apps deshabilitadas"

        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Copilot" -Name "DisableCopilot" -Value 1 -Type DWord -Force
        Register-Operation -Action "Deshabilitar" -Target "Microsoft Copilot" -Status "Success" -Details "Copilot deshabilitado"

        New-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableSearchBoxSuggestions" -Value 1 -Type DWord -Force
        Register-Operation -Action "Deshabilitar" -Target "Sugerencias búsqueda" -Status "Success" -Details "Sugerencias deshabilitadas"

        # Debloat Microsoft Edge
        $edgeSettings = @(
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\EdgeUpdate"; Name = "CreateDesktopShortcutDefault"; Value = 0 },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "EdgeEnhanceImagesEnabled"; Value = 0 },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "PersonalizationReportingEnabled"; Value = 0 },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "ShowRecommendationsEnabled"; Value = 0 },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "HideFirstRunExperience"; Value = 1 },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "UserFeedbackAllowed"; Value = 0 },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "ConfigureDoNotTrack"; Value = 1 },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "AlternateErrorPagesEnabled"; Value = 0 },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "EdgeCollectionsEnabled"; Value = 0 },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "EdgeFollowEnabled"; Value = 0 },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Edge"; Name = "EdgeShoppingAssistantEnabled"; Value = 0 }
        )
        foreach ($setting in $edgeSettings) {
            try {
                if (-not (Test-Path $setting.Path)) { New-Item -Path $setting.Path -Force | Out-Null 
} catch {
    Write-Host "Error desconocido en bloque try."
}}
                Set-ItemProperty -Path $setting.Path -Name $setting.Name -Value $setting.Value -Type DWord
            } catch {
                Register-Operation -Action "Debloat Edge" -Target $setting.Name -Status "Error" -Details $_.Exception.Message
            }
        }
        Register-Operation -Action "Debloat" -Target "Microsoft Edge" -Status "Success" -Details "Debloat completado"

        # Adobe Debloat
        New-Item -Path "HKLM:\SOFTWARE\Policies\Adobe" -Force | Out-Null
        New-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Adobe" -Name "BlockNetwork" -Value 1 -Type DWord -Force
        $adobePath = "C:\Program Files (x86)\Common Files\Adobe\Adobe Desktop Common\ADS\Adobe Desktop Service.exe"
        if (Test-Path $adobePath) {
            Takeown /f $adobePath
            $acl = Get-Acl $adobePath
            $acl.SetOwner([System.Security.Principal.NTAccount]"Administrators")
            $acl | Set-Acl $adobePath
            Rename-Item -Path $adobePath -NewName "Adobe Desktop Service.exe.old" -Force
        }
        $adobeRoot = "HKLM:\SOFTWARE\WOW6432Node\Adobe\Adobe ARM\Legacy\Acrobat"
        $subKeys = Get-ChildItem -Path $adobeRoot -ErrorAction SilentlyContinue | Where-Object { $_.PSChildName -like "{*}" }
        foreach ($subKey in $subKeys) {
            Set-ItemProperty -Path "$adobeRoot\$($subKey.PSChildName)" -Name "Mode" -Value 0 -ErrorAction SilentlyContinue
        }
        Register-Operation -Action "Debloat" -Target "Adobe" -Status "Success" -Details "Adobe debloat completado"
    } catch {
        Register-Operation -Action "Debloat" -Target "Avanzado" -Status "Error" -Details $_.Exception.Message
    }

    Write-Host "Eliminación de bloatware completada." -ForegroundColor Green
    Register-Operation -Action "Finalización" -Target "Eliminación de bloatware" -Status "Success" -Details "Proceso completado"
}

function Optimize-Games {
    param (
        [ValidateSet("VALORANT", "NewWorld", "Tarkov", "All")]
        [string]$GameName = "All",
        [bool]$ApplyFullscreenTweaks = $true,
        [bool]$OptimizeConfigFiles = $true
    )
    
    Write-Host "`n[3] Optimizando juegos..." -ForegroundColor Cyan
    Register-Operation -Action "Inicio" -Target "Optimizar Juegos" -Status "Info" -Details "Juego: $GameName"

    try {
        # Configuración general
        $generalSettings = @(
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"; Name = "SystemResponsiveness"; Value = 0 
} catch {
    Write-Host "Error desconocido en bloque try."
}},
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Name = "GPU Priority"; Value = 8 },
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Name = "Priority"; Value = 6 },
            @{ Path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"; Name = "Scheduling Category"; Value = "High" },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"; Name = "HwSchMode"; Value = 2 },
            @{ Path = "HKCU:\System\GameConfigStore"; Name = "GameDVR_Enabled"; Value = 0 },
            @{ Path = "HKCU:\System\GameConfigStore"; Name = "GameDVR_FSEBehaviorMode"; Value = 2 },
            @{ Path = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\GameDVR"; Name = "AllowGameDVR"; Value = 0 },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl"; Name = "Win32PrioritySeparation"; Value = 26 }
        )
        
        foreach ($setting in $generalSettings) {
            try {
                Set-ItemProperty -Path $setting.Path -Name $setting.Name -Value $setting.Value -Type DWord -ErrorAction Stop
                Register-Operation -Action "Configuración general" -Target $setting.Name -Status "Success" -Details "Valor establecido a $($setting.Value)"
            
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
                Register-Operation -Action "Configuración general" -Target $setting.Name -Status "Error" -Details $_.Exception.Message
            }
        }

        # Función auxiliar para optimizar archivos de configuración
        function Optimize-Game-File {
            param ([System.IO.FileInfo]$configFile)
            try {
                $backupPath = "$($configFile.FullName).bak"
                if (-not (Test-Path $backupPath)) {
                    Copy-Item $configFile.FullName -Destination $backupPath -Force
                
} catch {
    Write-Host "Error desconocido en bloque try."
}}
                $content = Get-Content $configFile.FullName -Raw
                if ($configFile.Extension -eq ".json") {
                    $json = $content | ConvertFrom-Json
                    if ($json.Graphics) {
                        $json.Graphics.Resolution.Width = 1920
                        $json.Graphics.Resolution.Height = 1080
                        $json.Graphics.Resolution.RefreshRate = 144
                        $json.Graphics.VSync = $false
                        $json.Graphics.TextureQuality = "High"
                        $json.Graphics.ShadowQuality = "Low"
                        $optimized = $json | ConvertTo-Json -Depth 10
                    }
                } else {
                    $optimized = $content -replace "(?i)(Fullscreen|WindowMode)\s*=\s*\w+", "Fullscreen=True" `
                                        -replace "(?i)VSync\s*=\s*\w+", "VSync=False" `
                                        -replace "(?i)RefreshRate\s*=\s*.+", "RefreshRate=144" `
                                        -replace "(?i)TextureQuality\s*=\s*\d", "TextureQuality=3" `
                                        -replace "(?i)ShadowQuality\s*=\s*\d", "ShadowQuality=1"
                }
                Set-Content -Path $configFile.FullName -Value $optimized -Force
                Register-Operation -Action "Optimizar archivo" -Target $configFile.Name -Status "Success" -Details "Configuración optimizada"
                return $true
            } catch {
                Register-Operation -Action "Optimizar archivo" -Target $configFile.Name -Status "Error" -Details $_.Exception.Message
                return $false
            }
        }

        # Optimizar archivos de configuración
        if ($OptimizeConfigFiles) {
            $configExtensions = @("*.ini", "*.cfg", "*.json", "*.xml")
            foreach ($path in $global:ExecutionHistory.GamePaths.CommonPaths) {
                if (Test-Path $path) {
                    foreach ($ext in $configExtensions) {
                        Get-ChildItem -Path $path -Filter $ext -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                            Optimize-Game-File -configFile $_
                        }
                    }
                }
            }
        }

        # Configuraciones específicas por juego
        $gameConfigs = @{
            VALORANT = @{
                ProcessName = "valorant.exe"
                Paths = $global:ExecutionHistory.GamePaths.VALORANT
                RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\VALORANT-Win64-Shipping.exe\PerfOptions"
                ConfigFiles = @("Windows\GameUserSettings.ini", "ShooterGame\Saved\Config\Windows\GameUserSettings.ini")
            }
            NewWorld = @{
                ProcessName = "NewWorld.exe"
                Paths = $global:ExecutionHistory.GamePaths.NewWorld
                RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\NewWorld.exe\PerfOptions"
                ConfigFiles = @("GameUserSettings.ini")
            }
            Tarkov = @{
                ProcessName = "EscapeFromTarkov.exe"
                Paths = $global:ExecutionHistory.GamePaths.Tarkov
                RegistryPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\EscapeFromTarkov.exe\PerfOptions"
                ConfigFiles = @("local.ini", "shared.ini")
            }
        }

        foreach ($game in $gameConfigs.GetEnumerator()) {
            if ($GameName -eq "All" -or $GameName -eq $game.Key) {
                try {
                    $found = $false
                    foreach ($path in $game.Value.Paths) {
                        if (Test-Path $path) {
                            if (Get-Process -Name $game.Value.ProcessName -ErrorAction SilentlyContinue) {
                                $proc = Get-Process -Name $game.Value.ProcessName
                                $proc.PriorityClass = "High"
                                Register-Operation -Action "Prioridad" -Target $game.Key -Status "Success" -Details "Prioridad alta establecida"
                            
} catch {
    Write-Host "Error desconocido en bloque try."
}}
                            if (-not (Test-Path $game.Value.RegistryPath)) {
                                New-Item -Path $game.Value.RegistryPath -Force | Out-Null
                            }
                            Set-ItemProperty -Path $game.Value.RegistryPath -Name "CpuPriorityClass" -Value 3
                            Set-ItemProperty -Path $game.Value.RegistryPath -Name "IoPriority" -Value 3
                            
                            foreach ($configFile in $game.Value.ConfigFiles) {
                                $fullPath = Join-Path $path $configFile
                                if (Test-Path $fullPath) {
                                    Optimize-Game-File -configFile (Get-Item $fullPath)
                                }
                            }
                            $found = $true
                            break
                        }
                    }
                    if (-not $found) {
                        Register-Operation -Action "Optimización" -Target $game.Key -Status "Warning" -Details "Juego no encontrado"
                    }
                } catch {
                    Register-Operation -Action "Optimización" -Target $game.Key -Status "Error" -Details $_.Exception.Message
                }
            }
        }

        # Optimizaciones pantalla completa
        if ($ApplyFullscreenTweaks) {
            try {
                foreach ($path in $global:ExecutionHistory.GamePaths.CommonPaths) {
                    if (Test-Path $path) {
                        Get-ChildItem -Path $path -Filter "*.exe" -Recurse -ErrorAction SilentlyContinue | ForEach-Object {
                            $regPath = "HKCU:\System\GameConfigStore\Games\$($_.Name)"
                            if (-not (Test-Path $regPath)) {
                                New-Item -Path $regPath -Force | Out-Null
                            
} catch {
    Write-Host "Error desconocido en bloque try."
}}
                            Set-ItemProperty -Path $regPath -Name "FullscreenOptimization" -Value 0
                            Set-ItemProperty -Path $regPath -Name "FullscreenExclusive" -Value 1
                        }
                    }
                }
                Register-Operation -Action "Pantalla completa" -Target "Global" -Status "Success" -Details "Optimizaciones aplicadas"
            } catch {
                Register-Operation -Action "Pantalla completa" -Target "Global" -Status "Error" -Details $_.Exception.Message
            }
        }

        Write-Host "`n[!] CONFIGURACIÓN PARA JUEGOS OPTIMIZADA" -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Optimizar Juegos" -Status "Success" -Details "Optimización completada"
    } catch {
        Write-Host "`n[!] ERROR DURANTE LA OPTIMIZACIÓN DE JUEGOS: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Optimizar Juegos" -Status "Error" -Details $_.Exception.Message
    }
}

function Install-X670E-Drivers {
    param (
        [bool]$installAll = $true,
        [bool]$installBluetooth = $false,
        [bool]$installWifi = $false,
        [bool]$installUsbAudio = $false,
        [bool]$installLan = $false,
        [bool]$installChipset = $false,
        [bool]$installUtilities = $false
    )

    Write-Host "`n[4] Instalando drivers para X670E-F..." -ForegroundColor Cyan
    Register-Operation -Action "Inicio" -Target "Instalar Drivers" -Status "Info" -Details "Iniciando instalación"

    $basePath = $global:DriverPaths.X670E
    
    if (-not (Test-Path $basePath)) {
        Register-Operation -Action "Verificación" -Target "Ruta de drivers" -Status "Error" -Details "Ruta no encontrada: $basePath"
        Write-Host "Error: Ruta de drivers no encontrada." -ForegroundColor Red
        return
    }

    try {
        $totalSteps = 0
        if ($installAll -or $installBluetooth) { $totalSteps++ 
} catch {
    Write-Host "Error desconocido en bloque try."
}}
        if ($installAll -or $installWifi) { $totalSteps++ }
        if ($installAll -or $installUsbAudio) { $totalSteps++ }
        if ($installAll -or $installLan) { $totalSteps++ }
        if ($installAll -or $installChipset) { $totalSteps++ }
        if ($installAll -or $installUtilities) { $totalSteps++ }

        $currentStep = 0
        $jobs = @()

        if ($installAll -or $installBluetooth) {
            $currentStep++
            Show-Progress -activity "Instalando drivers" -status "Bluetooth..." -percentComplete ($currentStep/$totalSteps*100)
            $bluetoothPath = Join-Path $basePath "DRV Bluetooth"
            if (Test-Path (Join-Path $bluetoothPath "Install.bat")) {
                $jobs += Start-Job -ScriptBlock {
                    param($path)
                    Start-Process -FilePath "$path\Install.bat" -NoNewWindow -Wait
                } -ArgumentList $bluetoothPath
            }
        }

        if ($installAll -or $installWifi) {
            $currentStep++
            Show-Progress -activity "Instalando drivers" -status "WiFi..." -percentComplete ($currentStep/$totalSteps*100)
            $wifiPath = Join-Path $basePath "DRV WIFI"
            if (Test-Path (Join-Path $wifiPath "Install.bat")) {
                $jobs += Start-Job -ScriptBlock {
                    param($path)
                    Start-Process -FilePath "$path\Install.bat" -NoNewWindow -Wait
                } -ArgumentList $wifiPath
            }
        }

        if ($installAll -or $installUsbAudio) {
            $currentStep++
            Show-Progress -activity "Instalando drivers" -status "Audio USB..." -percentComplete ($currentStep/$totalSteps*100)
            $usbAudioPath = Join-Path $basePath "DRV USB AUDIO"
            if (Test-Path (Join-Path $usbAudioPath "install.bat")) {
                $jobs += Start-Job -ScriptBlock {
                    param($path)
                    Start-Process -FilePath "$path\install.bat" -NoNewWindow -Wait
                } -ArgumentList $usbAudioPath
            }
        }

        if ($installAll -or $installLan) {
            $currentStep++
            Show-Progress -activity "Instalando drivers" -status "LAN..." -percentComplete ($currentStep/$totalSteps*100)
            $lanPath = Join-Path $basePath "DRV LAN"
            if (Test-Path (Join-Path $lanPath "install.cmd")) {
                $jobs += Start-Job -ScriptBlock {
                    param($path)
                    Start-Process -FilePath "$path\install.cmd" -NoNewWindow -Wait
                } -ArgumentList $lanPath
            }
        }

        if ($installAll -or $installChipset) {
            $currentStep++
            Show-Progress -activity "Instalando drivers" -status "Chipset..." -percentComplete ($currentStep/$totalSteps*100)
            $chipsetPath1 = Join-Path $basePath "DRV CHIPSET AMD 1\PCI"
            $chipsetPath2 = Join-Path $basePath "DRV CHIPSET AMD 2"
            if (Test-Path (Join-Path $chipsetPath1 "Install.bat")) {
                $jobs += Start-Job -ScriptBlock {
                    param($path)
                    Start-Process -FilePath "$path\Install.bat" -NoNewWindow -Wait
                } -ArgumentList $chipsetPath1
            }
            if (Test-Path (Join-Path $chipsetPath2 "silentinstall.cmd")) {
                $jobs += Start-Job -ScriptBlock {
                    param($path)
                    Start-Process -FilePath "$path\silentinstall.cmd" -NoNewWindow -Wait
                } -ArgumentList $chipsetPath2
            }
        }

        if ($installAll -or $installUtilities) {
            $currentStep++
            Show-Progress -activity "Instalando drivers" -status "Utilidades..." -percentComplete ($currentStep/$totalSteps*100)
            $utilityPath = Join-Path $basePath "DRIVER FOR WINDOWS\ITE UCM DRIVER For Windows\ITE UCM DRIVER For Windows"
            if (Test-Path (Join-Path $utilityPath "install.cmd")) {
                $jobs += Start-Job -ScriptBlock {
                    param($path)
                    Start-Process -FilePath "$path\install.cmd" -NoNewWindow -Wait
                } -ArgumentList $utilityPath
            }
        }

        $jobs | Wait-Job -Timeout 300 | Out-Null
        foreach ($job in $jobs) {
            if ($job.State -eq "Failed") {
                Register-Operation -Action "Instalación" -Target "Drivers" -Status "Error" -Details "Error en trabajo: $($job.Name)"
            }
        }
        $jobs | Remove-Job -Force

        Write-Host "`n[!] DRIVERS INSTALADOS CORRECTAMENTE" -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Instalar Drivers" -Status "Success" -Details "Instalación completada"
    } catch {
        Write-Host "`n[!] ERROR: $_" -ForegroundColor Red
        Register-Operation -Action "Instalación" -Target "Drivers" -Status "Error" -Details $_.Exception.Message
    }
}

function Optimize-Hardware {
    Write-Host "`n[5] Optimizando hardware específico..." -ForegroundColor Cyan
    Register-Operation -Action "Inicio" -Target "Optimizar Hardware" -Status "Info" -Details "Iniciando optimización"

    try {
        $CPU = (Get-CimInstance Win32_Processor).Name
        $GPU = (Get-CimInstance Win32_VideoController).Name

        # Verificar si el procesador es AMD Ryzen 7600X
        if ($CPU -match "7600X") {
            Write-Host "Optimizando CPU AMD Ryzen 7600X..." -ForegroundColor Cyan
            
            try {
                # Activar plan de energía Ryzen High Performance si no está activo
                $RyzenPlan = "e9a42b02-d5df-44b1-8c3f-7c0d4b0a2e4f"
                $ActivePlan = powercfg -getactivescheme
                if ($ActivePlan -notmatch $RyzenPlan) {
                    powercfg -duplicatescheme $RyzenPlan
                    powercfg -setactive $RyzenPlan
                
} catch {
    Write-Host "Error desconocido en bloque try."
}}
                
                # Deshabilitar Cool'n'Quiet (evita reducción de frecuencia en reposo)
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\amdppm" -Name "Start" -Value 4 -Type DWord -Force
                
                # Deshabilitar C-States (evita estados de bajo consumo que pueden causar latencias)
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\amdppm" -Name "CState" -Value 0 -Type DWord -Force
                
                # Deshabilitar Precision Boost si se desea estabilidad constante (opcional)
                # Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\amdppm" -Name "PB" -Value 0 -Type DWord -Force
                
                # Mejorar rendimiento de GPU NVIDIA RTX 4060 con el modo de rendimiento máximo
                if (Get-Command -Name "nvidia-smi" -ErrorAction SilentlyContinue) {
                    Start-Process "nvidia-smi" -ArgumentList "-pm 1" -NoNewWindow -Wait
                    Start-Process "nvidia-smi" -ArgumentList "-pl 120" -NoNewWindow -Wait
                }
                
                # Reducir latencia habilitando modo de baja latencia en NVIDIA
                if (Test-Path "HKLM:\SOFTWARE\NVIDIA Corporation\Global\NVTweak") {
                    Set-ItemProperty -Path "HKLM:\SOFTWARE\NVIDIA Corporation\Global\NVTweak" -Name "Llm" -Value 1 -Type DWord -Force
                }
                
                # Ajustar prioridades del procesador para mejorar el rendimiento de juegos
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 26 -Type DWord -Force
                
                # Optimización específica para juegos como Tarkov, Valorant, New World
                Write-Host "Aplicando configuraciones específicas para juegos..." -ForegroundColor Cyan
                
                # Habilitar el modo de máximo rendimiento para procesos de juego
                $Games = @("EscapeFromTarkov.exe", "valorant.exe", "NewWorld.exe")
                foreach ($Game in $Games) {
                    $Process = Get-Process -Name $Game -ErrorAction SilentlyContinue
                    if ($Process) {
                        Start-Process -FilePath $Process.Path -ArgumentList "-high" -NoNewWindow
                        Write-Host "Prioridad alta establecida para $Game" -ForegroundColor Green
                    }
                }
                
                # Deshabilitar el Game DVR de Windows para reducir input lag
                Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -Type DWord -Force
                Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value 2 -Type DWord -Force
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\ApplicationManagement\AllowGameDVR" -Name "Value" -Value 0 -Type DWord -Force
                
                # Aplicar overclock a CPU Ryzen 7600X
                Write-Host "Aplicando overclock seguro a CPU..." -ForegroundColor Cyan
                Start-Process "RyzenMaster.exe" -ArgumentList "-OC 5400MHz -Vcore 1.19V" -NoNewWindow -Wait
                
                # Aplicar overclock a GPU RTX 4060
                Write-Host "Aplicando overclock seguro a GPU..." -ForegroundColor Cyan
                Start-Process "MSIAfterburner.exe" -ArgumentList "-core +150 -mem +500" -NoNewWindow -Wait
                
                Write-Host "Optimización de CPU AMD Ryzen 7600X y GPU RTX 4060 aplicada con overclock y configuraciones para juegos." -ForegroundColor Green
                Register-Operation -Action "Optimizar CPU" -Target "Ryzen 7600X" -Status "Success" -Details "Optimización específica aplicada"
            } catch {
                Write-Host "Error al optimizar: $_" -ForegroundColor Red
                Register-Operation -Action "Optimizar CPU" -Target "Ryzen 7600X" -Status "Error" -Details $_.Exception.Message
            }
        }
        # Optimización AMD Ryzen genérica
        elseif ($CPU -match "Ryzen") {
            try {
                $RyzenPlan = "e9a42b02-d5df-44b1-8c3f-7c0d4b0a2e4f"
                $ActivePlan = powercfg -getactivescheme
                if ($ActivePlan -notmatch $RyzenPlan) {
                    powercfg -duplicatescheme $RyzenPlan
                    powercfg -setactive $RyzenPlan
                
} catch {
    Write-Host "Error desconocido en bloque try."
}}
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\amdppm" -Name "Start" -Value 4
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "FeatureSettingsOverride" -Type DWord -Value 0
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "FeatureSettingsOverrideMask" -Type DWord -Value 3
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "GPU Priority" -Value 8
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Priority" -Value 6
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games" -Name "Scheduling Category" -Value "High"
                Register-Operation -Action "Optimizar CPU" -Target "AMD Ryzen" -Status "Success" -Details "Configuración aplicada"
            } catch {
                Register-Operation -Action "Optimizar CPU" -Target "AMD Ryzen" -Status "Error" -Details $_.Exception.Message
            }
        }
        elseif ($CPU -match "Intel") {
            try {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\bc5038f7-23e0-4960-96da-33abaf5935ec" -Name "Attributes" -Type DWord -Value 0
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\893dee8e-2bef-41e0-89c6-b55d0929964c" -Name "Attributes" -Type DWord -Value 0
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\94d3a615-a899-4ac5-ae2b-e4d8f634367f" -Name "Attributes" -Type DWord -Value 0
                Register-Operation -Action "Optimizar CPU" -Target "Intel" -Status "Success" -Details "Configuración aplicada"
            
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
                Register-Operation -Action "Optimizar CPU" -Target "Intel" -Status "Error" -Details $_.Exception.Message
            }
        }

        # Optimización NVIDIA
        if ($GPU -match "NVIDIA") {
            try {
                Set-ItemProperty -Path "HKLM:\SOFTWARE\NVIDIA Corporation\Global\NVTweak" -Name "Llm" -Value 1
                Set-ItemProperty -Path "HKLM:\SOFTWARE\NVIDIA Corporation\Global\NVTweak" -Name "LlmAllow" -Value 1
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\FTS" -Name "EnableGR535" -Value 1
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\FTS" -Name "PerfQuality" -Value 1
                Set-ItemProperty -Path "HKLM:\SOFTWARE\NVIDIA Corporation\Global\NvControlPanel2\Client" -Name "ShaderCache" -Value 1
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318
} catch {
    Write-Host "Error desconocido en bloque try."
}}\0000" -Name "EnableULPS" -Value 0
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "DisableUlps" -Value 1
                if (Test-Path "C:\Program Files\NVIDIA Corporation\NVSMI\nvapi.dll") {
                    & "C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe" -pm 1
                    & "C:\Program Files\NVIDIA Corporation\NVSMI\nvidia-smi.exe" -pl 300
                }
                Register-Operation -Action "Optimizar GPU" -Target "NVIDIA" -Status "Success" -Details "Configuración aplicada"
            } catch {
                Register-Operation -Action "Optimizar GPU" -Target "NVIDIA" -Status "Error" -Details $_.Exception.Message
            }
        }
        elseif ($GPU -match "AMD") {
            try {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318
} catch {
    Write-Host "Error desconocido en bloque try."
}}\0000" -Name "EnableUlps" -Type DWord -Value 0
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "EnableUlps_NA" -Type DWord -Value 0
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "PP_DisablePowerContainment" -Type DWord -Value 1
                Register-Operation -Action "Optimizar GPU" -Target "AMD" -Status "Success" -Details "Configuración aplicada"
            } catch {
                Register-Operation -Action "Optimizar GPU" -Target "AMD" -Status "Error" -Details $_.Exception.Message
            }
        }

        # Optimización RAM
        try {
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 1
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "DisablePagingExecutive" -Value 1
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "ClearPageFileAtShutdown" -Value 0
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "IOPageLockLimit" -Value 4194304
            Register-Operation -Action "Optimizar" -Target "Memoria RAM" -Status "Success" -Details "Configuración aplicada"
        
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
            Register-Operation -Action "Optimizar" -Target "Memoria RAM" -Status "Error" -Details $_.Exception.Message
        }

        # Optimizaciones generales
        try {
            bcdedit /deletevalue useplatformclock
            bcdedit /set disabledynamictick yes
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "LinkStatePowerManagement" -Type DWord -Value 0
            Register-Operation -Action "Optimizar" -Target "General" -Status "Success" -Details "Optimizaciones generales aplicadas"
        
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
            Register-Operation -Action "Optimizar" -Target "General" -Status "Error" -Details $_.Exception.Message
        }

        Write-Host "`n[!] HARDWARE OPTIMIZADO CORRECTAMENTE" -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Optimizar Hardware" -Status "Success" -Details "Optimización completada"
    } catch {
        Write-Host "`n[!] ERROR DURANTE LA OPTIMIZACIÓN DE HARDWARE: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Optimizar Hardware" -Status "Error" -Details $_.Exception.Message
    }
}

function Optimize-Storage {
    Write-Host "`n[6] Optimizando almacenamiento (SSD/HDD)..." -ForegroundColor Cyan
    Register-Operation -Action "Inicio" -Target "Optimizar Almacenamiento" -Status "Info" -Details "Iniciando optimización"

    try {
        $osDrive = Get-Partition | Where-Object { $_.DriveLetter -eq 'C' 
} catch {
    Write-Host "Error desconocido en bloque try."
}} | Get-Disk
        $isSSD = $false
        
        if ($osDrive) {
            if ($osDrive.MediaType -in @("SSD", "NVMe")) { $isSSD = $true }
            elseif ($osDrive.Model -match "SSD|NVMe|M.2") { $isSSD = $true }
            else {
                $counters = Get-StorageReliabilityCounter -PhysicalDisk $osDrive -ErrorAction SilentlyContinue
                if ($counters -and $counters.DeviceType -eq "SSD") { $isSSD = $true }
            }
            Write-Host "Información del disco del sistema:"
            $osDrive | Format-Table FriendlyName, MediaType, BusType, Model, Size -AutoSize | Out-Host
        }

        if (-not $isSSD) {
            $confirm = Read-Host "No se pudo confirmar si es SSD. ¿Deseas aplicar optimizaciones para SSD de todos modos? (S/N)"
            if ($confirm -eq "S" -or $confirm -eq "s") { $isSSD = $true }
        }

        if ($isSSD) {
            Write-Host "Aplicando optimizaciones para SSD..." -ForegroundColor Yellow
            try {
                $volumes = Get-Volume -ErrorAction SilentlyContinue | Where-Object { $_.FileSystem -eq "NTFS" 
} catch {
    Write-Host "Error desconocido en bloque try."
}}
                foreach ($vol in $volumes) {
                    if ($vol.DriveLetter) {
                        Optimize-Volume -DriveLetter $vol.DriveLetter -ReTrim -Verbose -ErrorAction SilentlyContinue
                    } elseif ($vol.Path) {
                        Optimize-Volume -FilePath $vol.Path -ReTrim -Verbose -ErrorAction SilentlyContinue
                    }
                }
                if (Get-Service -Name "WSearch" -ErrorAction SilentlyContinue) {
                    Stop-Service -Name "WSearch" -Force -ErrorAction SilentlyContinue
                    Set-Service -Name "WSearch" -StartupType Disabled -ErrorAction SilentlyContinue
                }
                Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Search" -Name "SetupCompletedSuccessfully" -Type DWord -Value 0 -ErrorAction SilentlyContinue
                Disable-ScheduledTask -TaskName "\Microsoft\Windows\Defrag\ScheduledDefrag" -ErrorAction SilentlyContinue
                $pageFile = Get-WmiObject Win32_PageFileSetting -ErrorAction SilentlyContinue | Where-Object { $_.Name -like "*pagefile.sys" } | Select-Object -First 1
                if ($pageFile) {
                    $pageFile.InitialSize = 4096
                    $pageFile.MaximumSize = 8192
                    $pageFile.Put() | Out-Null
                }
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Type DWord -Value 0
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnableSuperfetch" -Type DWord -Value 0
                Register-Operation -Action "Optimizar" -Target "SSD" -Status "Success" -Details "Configuración SSD aplicada"
            } catch {
                Register-Operation -Action "Optimizar" -Target "SSD" -Status "Error" -Details $_.Exception.Message
            }
        } else {
            Write-Host "Aplicando optimizaciones para HDD..." -ForegroundColor Yellow
            try {
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PreffetchParameters" -Name "EnablePrefetcher" -Type DWord -Value 3
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnableSuperfetch" -Type DWord -Value 3
                Enable-ScheduledTask -TaskName "\Microsoft\Windows\Defrag\ScheduledDefrag" -ErrorAction SilentlyContinue
                Register-Operation -Action "Optimizar" -Target "HDD" -Status "Success" -Details "Configuración HDD aplicada"
            
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
                Register-Operation -Action "Optimizar" -Target "HDD" -Status "Error" -Details $_.Exception.Message
            }
        }

        try {
            fsutil behavior set disablelastaccess 1 | Out-Null
            fsutil behavior set disable8dot3 1 | Out-Null
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem" -Name "NtfsMemoryUsage" -Type DWord -Value 2
            Register-Operation -Action "Configuración común" -Target "Almacenamiento" -Status "Success" -Details "Ajustes aplicados"
        
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
            Register-Operation -Action "Configuración común" -Target "Almacenamiento" -Status "Error" -Details $_.Exception.Message
        }

        Write-Host "Optimización de almacenamiento completada." -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Optimizar Almacenamiento" -Status "Success" -Details "Optimización completada"
    } catch {
        Write-Host "`n[!] ERROR DURANTE LA OPTIMIZACIÓN DE ALMACENAMIENTO: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Optimizar Almacenamiento" -Status "Error" -Details $_.Exception.Message
    }
}

function Optimize-NetworkDNS {
    Write-Host "`n[7] Optimizando DNS para gaming..." -ForegroundColor Cyan
    Register-Operation -Action "Inicio" -Target "Optimizar DNS" -Status "Info" -Details "Iniciando optimización"

    try {
        $dnsProviders = @(
            @{ Name = "Cloudflare"; Primary = "1.1.1.1"; Secondary = "1.0.0.1" 
} catch {
    Write-Host "Error desconocido en bloque try."
}},
            @{ Name = "Google"; Primary = "8.8.8.8"; Secondary = "8.8.4.4" },
            @{ Name = "OpenDNS"; Primary = "208.67.222.222"; Secondary = "208.67.220.220" },
            @{ Name = "Quad9"; Primary = "9.9.9.9"; Secondary = "149.112.112.112" }
        )

        $interfaces = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' }
        foreach ($interface in $interfaces) {
            $fastestDNS = $dnsProviders | ForEach-Object {
                $ping = Test-Connection $_.Primary -Count 2 -ErrorAction SilentlyContinue | 
                        Measure-Object -Property ResponseTime -Average | 
                        Select-Object -ExpandProperty Average
                if ($ping) { 
                    $_ | Add-Member -NotePropertyName Ping -NotePropertyValue $ping -PassThru
                }
            } | Sort-Object Ping | Select-Object -First 1

            if ($fastestDNS) {
                Set-DnsClientServerAddress -InterfaceIndex $interface.InterfaceIndex -ServerAddresses ($fastestDNS.Primary, $fastestDNS.Secondary)
                $registryPath = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces\$($interface.InterfaceGuid)"
                Set-ItemProperty -Path $registryPath -Name "NameServer" -Value "$($fastestDNS.Primary),$($fastestDNS.Secondary)" -ErrorAction Stop
                Set-ItemProperty -Path $registryPath -Name "DhcpNameServer" -Value "$($fastestDNS.Primary),$($fastestDNS.Secondary)" -ErrorAction Stop
                Register-Operation -Action "Configurar DNS" -Target $interface.Name -Status "Success" -Details "DNS: $($fastestDNS.Name) ($($fastestDNS.Primary), $($fastestDNS.Secondary))"
            }
        }

        try {
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "MaxCacheTtl" -Type DWord -Value 30 -ErrorAction Stop
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "MaxNegativeCacheTtl" -Type DWord -Value 15 -ErrorAction Stop
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters" -Name "MaxCacheEntryTtlLimit" -Type DWord -Value 30 -ErrorAction Stop
            Register-Operation -Action "Optimizar caché DNS" -Target "Sistema" -Status "Success" -Details "TTL configurado"
        
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
            Register-Operation -Action "Optimizar caché DNS" -Target "Sistema" -Status "Error" -Details $_.Exception.Message
        }

        Write-Host "`n[!] OPTIMIZACIÓN DE DNS COMPLETADA" -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Optimizar DNS" -Status "Success" -Details "Optimización completada"
    } catch {
        Write-Host "`n[!] ERROR DURANTE LA OPTIMIZACIÓN DE DNS: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Optimizar DNS" -Status "Error" -Details $_.Exception.Message
    }
}

function Install-Programs {
    Write-Host "`n[8] Instalando programas esenciales..." -ForegroundColor Cyan
    Register-Operation -Action "Inicio" -Target "Instalar Programas" -Status "Info" -Details "Iniciando instalación"

    $programs = @(
        "Google.Chrome", "Mozilla.Firefox", "VideoLAN.VLC", "7zip.7zip",
        "Discord.Discord", "Spotify.Spotify", "Valve.Steam",
        "EpicGames.EpicGamesLauncher", "OBSProject.OBSStudio",
        "Notepad++.Notepad++", "Microsoft.PowerToys", "RiotGames.Valorant.EU",
        "Ubisoft.Connect", "GOG.Galaxy", "Logitech.GHUB",
        "Nvidia.GeForceExperience", "Microsoft.VCRedist.2015+.x64",
        "Apple.iTunes", "Bitwarden.Bitwarden", "Telegram.TelegramDesktop",
        "9NBDXK71NK08", "RARLab.WinRAR", "QL-Win.QuickLook",
        "Ablaze.Floorp", "Guru3D.Afterburner", "Rem0o.FanControl",
        "Klocman.BulkCrapUninstaller", "TechPowerUp.NVCleanstall",
        "WinDirStat.WinDirStat", "Wagnardsoft.DDU", "Elgato.StreamDeck",
        "Elgato.CameraHub"
    )

    try {
        if (-not (Get-Command winget -ErrorAction SilentlyContinue)) {
            $hasPackageManager = Get-AppxPackage -Name "Microsoft.DesktopAppInstaller"
            if (-not $hasPackageManager) {
                $releases_url = "https://api.github.com/repos/microsoft/winget-cli/releases/latest"
                $releases = Invoke-RestMethod -Uri $releases_url
                $latestRelease = $releases.assets | Where-Object { $_.browser_download_url.EndsWith(".msixbundle") 
} catch {
    Write-Host "Error desconocido en bloque try."
}} | Select-Object -First 1
                $download_url = $latestRelease.browser_download_url
                $output = "$env:TEMP\winget-latest.msixbundle"
                Invoke-WebRequest -Uri $download_url -OutFile $output
                Add-AppxPackage -Path $output
                Register-Operation -Action "Instalar" -Target "Winget" -Status "Success" -Details "Winget instalado"
            }
        }

        foreach ($program in $programs) {
            try {
                winget install --id $program --silent --accept-package-agreements --accept-source-agreements
                Register-Operation -Action "Instalar" -Target $program -Status "Success" -Details "Programa instalado via winget"
            
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
                Register-Operation -Action "Instalar" -Target $program -Status "Error" -Details $_.Exception.Message
            }
        }

        Write-Host "`n[!] INSTALACIÓN DE PROGRAMAS COMPLETADA" -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Instalar Programas" -Status "Success" -Details "Instalación completada"
    } catch {
        Write-Host "`n[!] ERROR: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Instalar Programas" -Status "Error" -Details $_.Exception.Message
    }
}

function Perform-Cleanup {
    Write-Host "`n[9] Realizando limpieza y mantenimiento..." -ForegroundColor Cyan
    Register-Operation -Action "Inicio" -Target "Limpieza del Sistema" -Status "Info" -Details "Iniciando limpieza"

    try {
        $tempFolders = @(
            "$env:TEMP\*", "$env:WINDIR\Temp\*", "$env:LOCALAPPDATA\Temp\*",
            "$env:WINDIR\Prefetch\*", "$env:USERPROFILE\AppData\Local\Microsoft\Windows\INetCache\*",
            "$env:USERPROFILE\AppData\Local\Microsoft\Windows\INetCookies\*",
            "$env:USERPROFILE\AppData\Local\Microsoft\Windows\History\*",
            "$env:WINDIR\Logs\*", "$env:WINDIR\System32\LogFiles\*"
        )

        foreach ($folder in $tempFolders) {
            try {
                Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
                Register-Operation -Action "Limpieza" -Target "Archivos temporales" -Status "Success" -Details "Eliminados en: $folder"
            
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
                Register-Operation -Action "Limpieza" -Target "Archivos temporales" -Status "Error" -Details "Error en $folder: $($_.Exception.Message)"
            }
        }

        try {
            wevtutil el | ForEach-Object { wevtutil cl "$_" 
} catch {
    Write-Host "Error desconocido en bloque try."
}}
            Register-Operation -Action "Limpieza" -Target "Logs del sistema" -Status "Success" -Details "Logs limpiados"
        } catch {
            Register-Operation -Action "Limpieza" -Target "Logs del sistema" -Status "Error" -Details $_.Exception.Message
        }

        try {
            Dism.exe /online /Cleanup-Image /StartComponentCleanup /ResetBase
            Register-Operation -Action "Limpieza" -Target "Actualizaciones Windows" -Status "Success" -Details "Limpieza de componentes realizada"
        
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
            Register-Operation -Action "Limpieza" -Target "Actualizaciones Windows" -Status "Error" -Details $_.Exception.Message
        }

        try {
            Remove-Item -Path "$env:SYSTEMDRIVE\*.dmp" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:WINDIR\Minidump\*" -Force -ErrorAction SilentlyContinue
            Register-Operation -Action "Limpieza" -Target "Archivos dump" -Status "Success" -Details "Archivos de volcado eliminados"
        
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
            Register-Operation -Action "Limpieza" -Target "Archivos dump" -Status "Error" -Details $_.Exception.Message
        }

        try {
            Stop-Service -Name "wuauserv" -Force -ErrorAction SilentlyContinue
            Remove-Item -Path "$env:WINDIR\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
            Start-Service -Name "wuauserv" -ErrorAction SilentlyContinue
            Register-Operation -Action "Limpieza" -Target "Windows Update Cache" -Status "Success" -Details "Caché eliminada"
        
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
            Register-Operation -Action "Limpieza" -Target "Windows Update Cache" -Status "Error" -Details $_.Exception.Message
        }

        try {
            Get-Volume | Where-Object DriveType -eq "Fixed" | ForEach-Object {
                if ($_.DriveLetter) {
                    if ($_.FileSystemType -eq "NTFS") {
                        if ($_.MediaType -eq "HDD") {
                            Optimize-Volume -DriveLetter $_.DriveLetter -Defrag -Verbose
                        
} catch {
    Write-Host "Error desconocido en bloque try."
}} else {
                            Optimize-Volume -DriveLetter $_.DriveLetter -ReTrim -Verbose
                        }
                    }
                }
            }
            Register-Operation -Action "Optimización" -Target "Unidades" -Status "Success" -Details "Optimización de unidades completada"
        } catch {
            Register-Operation -Action "Optimización" -Target "Unidades" -Status "Error" -Details $_.Exception.Message
        }

        Write-Host "Limpieza y mantenimiento completados." -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Limpieza del Sistema" -Status "Success" -Details "Proceso completado"
    } catch {
        Write-Host "`n[!] ERROR DURANTE LA LIMPIEZA: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Limpieza del Sistema" -Status "Error" -Details $_.Exception.Message
    }
}

function Disable-TelemetryAndDefender {
    Write-Host "`n[10] Deshabilitando telemetría y Windows Defender..." -ForegroundColor Cyan
    Register-Operation -Action "Inicio" -Target "Deshabilitar Telemetría/Defender" -Status "Info" -Details "Iniciando deshabilitación"

    try {
        $telemetryServices = @(
            "DiagTrack", "diagnosticshub.standardcollector.service", "dmwappushservice",
            "DPS", "WpcMonSvc", "WdiServiceHost"
        )

        foreach ($service in $telemetryServices) {
            try {
                Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
                sc.exe sdset $service "D:(D;;DCLCWPDTSD;;;IU)(D;;DCLCWPDTSD;;;SU)(D;;DCLCWPDTSD;;;BA)(D;;DCLCWPDTSD;;;S-1-5-80)" | Out-Null
                Register-Operation -Action "Deshabilitar servicio" -Target $service -Status "Success" -Details "Servicio deshabilitado"
            
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
                Register-Operation -Action "Deshabilitar servicio" -Target $service -Status "Error" -Details $_.Exception.Message
            }
        }

        try {
            $defenderServices = @("WinDefend", "WdNisSvc", "Sense", "SecurityHealthService")
            foreach ($service in $defenderServices) {
                Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
            
} catch {
    Write-Host "Error desconocido en bloque try."
}}
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableAntiSpyware" -Type DWord -Value 1
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender" -Name "DisableRoutinelyTakingAction" -Type DWord -Value 1
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Real-Time Protection" -Name "DisableRealtimeMonitoring" -Type DWord -Value 1
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -Name "SpynetReporting" -Type DWord -Value 0
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows Defender\Spynet" -Name "SubmitSamplesConsent" -Type DWord -Value 2
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows Defender\Features" -Name "TamperProtection" -Type DWord -Value 0
            Register-Operation -Action "Deshabilitar" -Target "Windows Defender" -Status "Success" -Details "Defender deshabilitado"
        } catch {
            Register-Operation -Action "Deshabilitar" -Target "Windows Defender" -Status "Error" -Details $_.Exception.Message
        }

        Write-Host "Telemetría y Windows Defender deshabilitados." -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Deshabilitar Telemetría/Defender" -Status "Success" -Details "Proceso completado"
    } catch {
        Write-Host "`n[!] ERROR: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Deshabilitar Telemetría/Defender" -Status "Error" -Details $_.Exception.Message
    }
}

function Disable-WindowsUpdate {
    Write-Host "`n[11] Deshabilitando Windows Update..." -ForegroundColor Cyan
    Register-Operation -Action "Inicio" -Target "Deshabilitar Windows Update" -Status "Info" -Details "Iniciando deshabilitación"

    try {
        $updateServices = @("wuauserv", "UsoSvc", "WaaSMedicSvc", "BITS")
        foreach ($service in $updateServices) {
            try {
                Stop-Service -Name $service -Force -ErrorAction SilentlyContinue
                Set-Service -Name $service -StartupType Disabled -ErrorAction SilentlyContinue
                Register-Operation -Action "Deshabilitar servicio" -Target $service -Status "Success" -Details "Servicio deshabilitado"
            
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
                Register-Operation -Action "Deshabilitar servicio" -Target $service -Status "Error" -Details $_.Exception.Message
            }
        }

        $updatePaths = @(
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
        )

        foreach ($path in $updatePaths) {
            try {
                if (-not (Test-Path $path)) { New-Item -Path $path -Force | Out-Null 
} catch {
    Write-Host "Error desconocido en bloque try."
}}
                Set-ItemProperty -Path $path -Name "NoAutoUpdate" -Type DWord -Value 1
                Set-ItemProperty -Path $path -Name "DisableOSUpgrade" -Type DWord -Value 1
                Set-ItemProperty -Path $path -Name "DeferFeatureUpdates" -Type DWord -Value 1
                Set-ItemProperty -Path $path -Name "DeferFeatureUpdatesPeriodInDays" -Type DWord -Value 365
                Set-ItemProperty -Path $path -Name "DeferQualityUpdates" -Type DWord -Value 1
                Set-ItemProperty -Path $path -Name "DeferQualityUpdatesPeriodInDays" -Type DWord -Value 365
                Register-Operation -Action "Configurar" -Target "Windows Update" -Status "Success" -Details "Configuración aplicada en $path"
            } catch {
                Register-Operation -Action "Configurar" -Target "Windows Update" -Status "Error" -Details $_.Exception.Message
            }
        }

        try {
            $null = netsh advfirewall firewall add rule name="Block Windows Update" dir=out action=block service=wuauserv enable=yes
            Register-Operation -Action "Bloquear" -Target "Windows Update" -Status "Success" -Details "Regla de firewall agregada"
        
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
            Register-Operation -Action "Bloquear" -Target "Windows Update" -Status "Error" -Details $_.Exception.Message
        }

        Write-Host "Windows Update deshabilitado." -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Deshabilitar Windows Update" -Status "Success" -Details "Proceso completado"
    } catch {
        Write-Host "`n[!] ERROR: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Deshabilitar Windows Update" -Status "Error" -Details $_.Exception.Message
    }
}

function Enable-AdminAccountAndBackup {
    Write-Host "`n[12] Configurando cuenta de administrador y copias de seguridad..." -ForegroundColor Cyan
    Register-Operation -Action "Inicio" -Target "Configurar Admin/Backups" -Status "Info" -Details "Iniciando configuración"

    try {
        $adminName = "Administrador"
        $password = Read-Host "Ingrese la contraseña para la cuenta de administrador" -AsSecureString
        $adminAccount = Get-LocalUser -Name $adminName -ErrorAction SilentlyContinue
        
        if ($adminAccount) {
            Set-LocalUser -Name $adminName -Password $password -AccountNeverExpires -PasswordNeverExpires:$true
            Enable-LocalUser -Name $adminName
        
} catch {
    Write-Host "Error desconocido en bloque try."
}} else {
            New-LocalUser -Name $adminName -Password $password -AccountNeverExpires -PasswordNeverExpires:$true
            Add-LocalGroupMember -Group "Administrators" -Member $adminName
        }
        Register-Operation -Action "Configurar" -Target "Cuenta de administrador" -Status "Success" -Details "Cuenta configurada"

        try {
            $taskAction = New-ScheduledTaskAction -Execute "reg.exe" -Argument "export HKLM\SOFTWARE $env:SystemDrive\RegBackup\Software_Backup.reg /y"
            $taskTrigger = New-ScheduledTaskTrigger -Daily -At 3am
            $taskSettings = New-ScheduledTaskSettingsSet -StartWhenAvailable -DontStopOnIdleEnd -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries
            Register-ScheduledTask -TaskName "RegistryBackup" -Action $taskAction -Trigger $taskTrigger -Settings $taskSettings -RunLevel Highest -Force | Out-Null
            Register-Operation -Action "Configurar" -Target "Copia de seguridad registro" -Status "Success" -Details "Tarea programada creada"
        
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
            Register-Operation -Action "Configurar" -Target "Copia de seguridad registro" -Status "Error" -Details $_.Exception.Message
        }

        try {
            Checkpoint-Computer -Description "Punto de restauración creado por Optimizer" -RestorePointType "MODIFY_SETTINGS"
            Register-Operation -Action "Crear" -Target "Punto de restauración" -Status "Success" -Details "Punto de restauración creado"
        
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
            Register-Operation -Action "Crear" -Target "Punto de restauración" -Status "Error" -Details $_.Exception.Message
        }

        Write-Host "Configuración de administrador y copias de seguridad completada." -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Configurar Admin/Backups" -Status "Success" -Details "Proceso completado"
    } catch {
        Write-Host "`n[!] ERROR: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Configurar Admin/Backups" -Status "Error" -Details $_.Exception.Message
    }
}

function Optimize-UIAndExperience {
    Write-Host "`n[13] Optimizando interfaz de usuario y experiencia..." -ForegroundColor Cyan
    Register-Operation -Action "Inicio" -Target "Optimizar UI/Experiencia" -Status "Info" -Details "Iniciando optimización"

    try {
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Policies\Microsoft\Windows\Explorer" -Name "DisableNotificationCenter" -Type DWord -Value 1
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\PushNotifications" -Name "ToastEnabled" -Type DWord -Value 0
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "DragHeight" -Type DWord -Value 20
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "DragWidth" -Type DWord -Value 20
        Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:LOCALAPPDATA\IconCache.db" -Force -ErrorAction SilentlyContinue
        Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\iconcache*" -Force -ErrorAction SilentlyContinue
        Start-Process explorer
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "ContentDeliveryAllowed" -Type DWord -Value 0
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "OemPreInstalledAppsEnabled" -Type DWord -Value 0
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "PreInstalledAppsEnabled" -Type DWord -Value 0
        Set-ItemProperty -Path "HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\ContentDeliveryManager" -Name "SilentInstalledAppsEnabled" -Type DWord -Value 0
        Invoke-WinutilThemeChange -theme "Dark"
        Register-Operation -Action "Optimizar" -Target "Interfaz de usuario" -Status "Success" -Details "Configuración aplicada"
        
        Write-Host "Interfaz de usuario y experiencia optimizadas." -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Optimizar UI/Experiencia" -Status "Success" -Details "Optimización completada"
    
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
        Write-Host "`n[!] ERROR: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Optimizar UI/Experiencia" -Status "Error" -Details $_.Exception.Message
    }
}

function Optimize-NetworkAndRemoteAccess {
    Write-Host "`n[14] Optimizando configuración de red y acceso remoto..." -ForegroundColor Cyan
    Register-Operation -Action "Inicio" -Target "Optimizar Red/RDP" -Status "Info" -Details "Iniciando optimización"

    try {
        $newRDPPort = Read-Host "Ingrese el nuevo puerto para RDP (default: 3389)"
        if (-not $newRDPPort) { $newRDPPort = 3389 
} catch {
    Write-Host "Error desconocido en bloque try."
}}
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server\WinStations\RDP-Tcp" -Name "PortNumber" -Type DWord -Value $newRDPPort
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Terminal Server" -Name "fDenyTSConnections" -Type DWord -Value 0
        netsh advfirewall firewall add rule name="RDP Port $newRDPPort" dir=in action=allow protocol=TCP localport=$newRDPPort
        netsh advfirewall firewall set rule group="remote desktop" new enable=Yes
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System" -Name "EnableLinkedConnections" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "DisableBandwidthThrottling" -Type DWord -Value 1
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanWorkstation\Parameters" -Name "FileInfoCacheEntriesMax" -Type DWord -Value 1024
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters" -Name "IRPStackSize" -Type DWord -Value 30
        Register-Operation -Action "Optimizar" -Target "Red/RDP" -Status "Success" -Details "Configuración aplicada"
        
        Write-Host "Configuración de red y acceso remoto optimizada." -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Optimizar Red/RDP" -Status "Success" -Details "Optimización completada"
    } catch {
        Write-Host "`n[!] ERROR: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Optimizar Red/RDP" -Status "Error" -Details $_.Exception.Message
    }
}

function Reset-GroupPolicy {
    Write-Host "`n[15] Restableciendo políticas de grupo..." -ForegroundColor Cyan
    Register-Operation -Action "Inicio" -Target "Resetear Políticas" -Status "Info" -Details "Iniciando restablecimiento"

    try {
        Remove-Item -Path "$env:WINDIR\System32\GroupPolicy\Machine" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:WINDIR\System32\GroupPolicy\User" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item -Path "$env:WINDIR\System32\GroupPolicy\gpt.ini" -Force -ErrorAction SilentlyContinue
        gpupdate /force | Out-Null
        secedit /configure /cfg "$env:WINDIR\inf\defltbase.inf" /db defltbase.sdb /verbose | Out-Null
        Remove-Item -Path "$env:LOCALAPPDATA\Microsoft\Group Policy\History\*" -Recurse -Force -ErrorAction SilentlyContinue
        Register-Operation -Action "Resetear" -Target "Políticas de grupo" -Status "Success" -Details "Políticas restablecidas"
        
        Write-Host "Políticas de grupo restablecidas." -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Resetear Políticas" -Status "Success" -Details "Proceso completado"
    
} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
        Write-Host "`n[!] ERROR: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Resetear Políticas" -Status "Error" -Details $_.Exception.Message
    }
}

function Set-FullscreenOptimizations {
    Write-Host "`n[16] Configurando pantalla completa para juegos..." -ForegroundColor Cyan
    Register-Operation -Action "Inicio" -Target "Optimizar Pantalla Completa" -Status "Info" -Details "Iniciando configuración"

    try {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Type DWord -Value 2
        Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Type DWord -Value 2
        foreach ($path in $global:ExecutionHistory.GamePaths.CommonPaths) {
            if (Test-Path $path) {
                $configs = Get-ChildItem -Path $path -Recurse -Include ("*.ini","*.cfg") -ErrorAction SilentlyContinue
                foreach ($file in $configs) {
                    try {
                        $content = Get-Content $file.FullName -Raw
                        $newContent = $content -replace "(?i)(Fullscreen|WindowMode)\s*=\s*\w+", "Fullscreen=True"
                        if ($newContent -ne $content) {
                            $backupPath = "$($file.FullName).bak"
                            if (-not (Test-Path $backupPath)) {
                                Copy-Item $file.FullName -Destination $backupPath -Force
                            
} catch {
    Write-Host "Error desconocido en bloque try."
}}
                            Set-Content -Path $file.FullName -Value $newContent -Force
                        }
                    } catch {
                        Register-Operation -Action "Modificar" -Target $file.Name -Status "Error" -Details $_.Exception.Message
                    }
                }
            }
        }
        Register-Operation -Action "Optimizar" -Target "Pantalla Completa" -Status "Success" -Details "Configuración aplicada"
        
        Write-Host "Configuración de pantalla completa completada." -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Optimizar Pantalla Completa" -Status "Success" -Details "Proceso completado"
    } catch {
        Write-Host "`n[!] ERROR: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Optimizar Pantalla Completa" -Status "Error" -Details $_.Exception.Message
    }
}

# Function to completely remove Microsoft Copilot
function Remove-MicrosoftCopilot {
    Write-Host "[+] Starting Microsoft Copilot removal..." -ForegroundColor Cyan
    
    try {
        # 1. Stop and disable Copilot services
        $copilotServices = @(
            "CopilotService",
            "WindowsAIService"
        )

        foreach ($service in $copilotServices) {
            if (Get-Service -Name $service -ErrorAction SilentlyContinue) {
                Stop-Service -Name $service -Force
                Set-Service -Name $service -StartupType Disabled
                Write-Host "Service disabled: $service" -ForegroundColor Green
            
} catch {
    Write-Host "Error desconocido en bloque try."
}}
        }

        # 2. Remove Registry entries
        $registryPaths = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Copilot",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot",
            "HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WindowsCopilot",
            "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ShowCopilotButton",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat",
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Advanced\ShowCopilotButton"
        )

        foreach ($path in $registryPaths) {
            if (Test-Path $path) {
                Remove-Item -Path $path -Recurse -Force
                Write-Host "Registry key removed: $path" -ForegroundColor Green
            }
        }

        # 3. Disable Copilot through Group Policy
        $policyPaths = @{
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsCopilot" = @{
                "TurnOffWindowsCopilot" = 1
                "DisableCopilot" = 1
            }
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat" = @{
                "ChatIcon" = 3
                "DisableWindowsCopilotWorkspace" = 1
            }
        }

        foreach ($path in $policyPaths.Keys) {
            if (-not (Test-Path $path)) {
                New-Item -Path $path -Force | Out-Null
            }
            foreach ($name in $policyPaths[$path].Keys) {
                Set-ItemProperty -Path $path -Name $name -Value $policyPaths[$path][$name] -Type DWord -Force
            }
        }

        # 4. Remove Copilot executables
        $copilotPaths = @(
            "$env:ProgramFiles\WindowsApps\Microsoft.Windows.Copilot*",
            "$env:LocalAppData\Microsoft\WindowsApps\Copilot*",
            "$env:ProgramFiles\Microsoft\Windows\Copilot",
            "$env:SystemRoot\System32\Copilot"
        )

        foreach ($path in $copilotPaths) {
            if (Test-Path $path) {
                Remove-Item -Path $path -Recurse -Force
                Write-Host "Files removed: $path" -ForegroundColor Green
            }
        }

        # 5. Remove Copilot from taskbar
        $explorerSettings = @{
            "ShowCopilotButton" = 0
            "TaskbarAl" = 0
        }

        foreach ($setting in $explorerSettings.Keys) {
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name $setting -Value $explorerSettings[$setting] -Type DWord -Force
        }

        # 6. Block Copilot in firewall
        $firewallRules = @(
            "Block-Copilot-Outbound",
            "Block-Copilot-Inbound"
        )

        foreach ($rule in $firewallRules) {
            Remove-NetFirewallRule -Name $rule -ErrorAction SilentlyContinue
            New-NetFirewallRule -Name $rule -Direction Outbound -Action Block -Program "%ProgramFiles%\WindowsApps\Microsoft.Windows.Copilot*\*.exe" -DisplayName $rule
        }

        # 7. Restart Explorer to apply changes
        Stop-Process -Name explorer -Force
        Start-Process explorer

        Write-Host "`n[✓] Microsoft Copilot has been completely removed!" -ForegroundColor Green
        Write-Host "Please restart your computer to apply all changes." -ForegroundColor Yellow
        
    } catch {
        Write-Host "[!] Error removing Copilot: $_" -ForegroundColor Red
    }
}

# endregion

# region Menu Functions

function Show-History {
    Show-Header
    Write-Host "  HISTORIAL DE EJECUCIÓN" -ForegroundColor Cyan
    Write-Host "  ────────────────────────────────────────────────────" -ForegroundColor DarkGray
    
    if ($global:ExecutionHistory.Operations.Count -eq 0) {
        Write-Host "  No hay operaciones registradas." -ForegroundColor Yellow
        Pause
        return
    }

    $lastOperations = $global:ExecutionHistory.Operations | Select-Object -Last 20
    
    foreach ($op in $lastOperations) {
        $color = switch ($op.Status) {
            "Error" { "Red" }
            "Warning" { "Yellow" }
            default { "Green" }
        }
        Write-Host "  [${mm:ss'})] [$($op.Status)] $($op.Action) - $($op.Target)" -ForegroundColor $color
        if ($op.Details) {
            Write-Host "    ↳ $($op.Details)" -ForegroundColor DarkGray
        }
    }

    Write-Host "`n  ESTADÍSTICAS:" -ForegroundColor Cyan
    Write-Host "  ────────────────────────────────────────────────────" -ForegroundColor DarkGray
    Write-Host "  Configuraciones modificadas: ${ExecutionHistory.Stats.SettingsChanged}" -ForegroundColor Gray
    Write-Host "  Archivos modificados: ${ExecutionHistory.Stats.FilesModified}" -ForegroundColor Gray
    Write-Host "  Elementos eliminados: ${ExecutionHistory.Stats.ItemsRemoved}" -ForegroundColor Gray
    Write-Host "  Drivers instalados: ${ExecutionHistory.Stats.DriversInstalled}" -ForegroundColor Gray
    Write-Host "  Programas instalados: ${ExecutionHistory.Stats.ProgramsInstalled}" -ForegroundColor Gray
    Write-Host "  Servicios deshabilitados: ${ExecutionHistory.Stats.ServicesDisabled}" -ForegroundColor Gray
    Write-Host "  Juegos optimizados: ${ExecutionHistory.Stats.GameOptimizations}" -ForegroundColor Gray
    Write-Host "  DNS optimizados: ${ExecutionHistory.Stats.DNSOptimized}" -ForegroundColor Gray
    Write-Host ""
    Write-Host "  Archivo de registro completo: ${LogFile}" -ForegroundColor DarkGray
    Pause
}

function Show-MainMenu {
    Show-Header
    Write-Host "  MENÚ PRINCIPAL" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] OPTIMIZACIÓN COMPLETA DEL SISTEMA" -ForegroundColor Green
    Write-Host "  [2] OPTIMIZAR CONFIGURACIÓN DEL SISTEMA" -ForegroundColor Blue
    Write-Host "  [3] ELIMINAR BLOATWARE" -ForegroundColor Magenta
    Write-Host "  [4] OPTIMIZAR PARA JUEGOS" -ForegroundColor Yellow
    Write-Host "  [5] INSTALAR DRIVERS X670E-F" -ForegroundColor Cyan
    Write-Host "  [6] OPTIMIZAR HARDWARE" -ForegroundColor DarkCyan
    Write-Host "  [7] OPTIMIZAR ALMACENAMIENTO" -ForegroundColor White
    Write-Host "  [8] OPTIMIZAR DNS" -ForegroundColor Gray
    Write-Host "  [9] INSTALAR PROGRAMAS ESENCIALES" -ForegroundColor DarkYellow
    Write-Host "  [10] LIMPIEZA Y MANTENIMIENTO" -ForegroundColor DarkGreen
    Write-Host "  [11] HERRAMIENTAS AVANZADAS" -ForegroundColor DarkMagenta
    Write-Host "  [12] MOSTRAR HISTORIAL" -ForegroundColor DarkRed
    Write-Host "  [13] SALIR" -ForegroundColor Red
    Write-Host ""
    Write-Host "  ────────────────────────────────────────────────────" -ForegroundColor DarkGray
    $selection = Read-Host "  SELECCIONE UNA OPCIÓN (1-13)"
    return $selection
}

function Show-GamesMenu {
    Show-Header
    Write-Host "  MENÚ DE JUEGOS" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] OPTIMIZAR VALORANT" -ForegroundColor Green
    Write-Host "  [2] OPTIMIZAR NEW WORLD" -ForegroundColor Blue
    Write-Host "  [3] OPTIMIZAR ESCAPE FROM TARKOV" -ForegroundColor Magenta
    Write-Host "  [4] OPTIMIZAR TODOS LOS JUEGOS" -ForegroundColor Yellow
    Write-Host "  [5] FORZAR PANTALLA COMPLETA" -ForegroundColor DarkYellow
    Write-Host "  [6] VOLVER AL MENÚ PRINCIPAL" -ForegroundColor Red
    Write-Host ""
    Write-Host "  ────────────────────────────────────────────────────" -ForegroundColor DarkGray
    $selection = Read-Host "  SELECCIONE UNA OPCIÓN (1-6)"
    return $selection
}

function Show-DriversMenu {
    Show-Header
    Write-Host "  MENÚ DE DRIVERS" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "  [1] INSTALAR TODOS LOS DRIVERS" -ForegroundColor Green
    Write-Host "  [2] INSTALAR SOLO CHIPSET" -ForegroundColor Blue
    Write-Host "  [3] INSTALAR CONTROLADORES DE RED" -ForegroundColor Magenta
    Write-Host "  [4] INSTALAR CONTROLADORES DE AUDIO" -ForegroundColor Yellow
    Write-Host "  [5] INSTALAR UTILIDADES" -ForegroundColor DarkCyan
    Write-Host "  [6] VOLVER AL MENÚ PRINCIPAL" -ForegroundColor Red
    Write-Host ""
    Write-Host "  ────────────────────────────────────────────────────" -ForegroundColor DarkGray
    $selection = Read-Host "  SELECCIONE UNA OPCIÓN (1-6)"
    return $selection
}

function Show-AdvancedToolsMenu {
    Clear-Host
    Write-Host "  OPTIMIZADOR WINDOWS - HERRAMIENTAS AVANZADAS" -ForegroundColor Cyan
    Write-Host "  ============================================" -ForegroundColor DarkGray
    Write-Host ""
    Write-Host "  [1] DESHABILITAR TELEMETRÍA Y DEFENDER" -ForegroundColor Green
    Write-Host "  [2] BLOQUEAR WINDOWS UPDATE" -ForegroundColor Blue
    Write-Host "  [3] CONFIGURAR ADMIN Y BACKUPS" -ForegroundColor Magenta
    Write-Host "  [4] OPTIMIZAR UI Y EXPERIENCIA" -ForegroundColor Yellow
    Write-Host "  [5] OPTIMIZAR RED Y RDP" -ForegroundColor Cyan
    Write-Host "  [6] RESETEAR POLÍTICAS DE GRUPO" -ForegroundColor DarkYellow
    Write-Host "  [7] ELIMINAR MICROSOFT COPILOT" -ForegroundColor DarkMagenta
    Write-Host "  [8] VOLVER AL MENÚ PRINCIPAL" -ForegroundColor Red
    Write-Host ""
    Write-Host "  ────────────────────────────────────────────" -ForegroundColor DarkGray
    $selection = Read-Host "  SELECCIONE UNA OPCIÓN (1-8)"
    return $selection
}

# Función para verificar si el script se ejecuta como administrador
function Test-Admin {
    $currentUser = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($currentUser)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# Lógica principal del optimizador
function Start-Optimizer {
    if (-not (Test-Admin)) {
        Write-Host "  [!] Este script debe ejecutarse como administrador." -ForegroundColor Red
        Write-Host "  Por favor, ejecute PowerShell como administrador e intente de nuevo." -ForegroundColor Yellow
        Pause
        exit
    }

    # Variable global para rastrear la ejecución (inicio del script)
    $global:ExecutionHistory = [PSCustomObject]@{
        StartTime  = Get-Date
        Operations = @()
        Errors     = @()
        Warnings   = @()
    }

    while ($true) {
        $selection = Show-MainMenu
        switch ($selection) {
            "1" { Optimize-SystemFull }
            "2" { Optimize-SystemSettings }
            "3" { Remove-Bloatware }
            "4" { 
                while ($true) {
                    $gameSelection = Show-GamesMenu
                    switch ($gameSelection) {
                        "1" { Optimize-Games -GameName "VALORANT" }
                        "2" { Optimize-Games -GameName "NewWorld" }
                        "3" { Optimize-Games -GameName "Tarkov" }
                        "4" { Optimize-Games -GameName "All" }
                        "5" { Set-FullscreenOptimizations }
                        "6" { break }
                        default { Write-Host "  [!] Opción inválida." -ForegroundColor Red }
                    }
                }
            }
            "5" { 
                while ($true) {
                    $driverSelection = Show-DriversMenu
                    switch ($driverSelection) {
                        "1" { Install-X670E-Drivers -installAll $true }
                        "2" { Install-X670E-Drivers -installChipset $true }
                        "3" { Install-X670E-Drivers -installLan $true }
                        "4" { Install-X670E-Drivers -installUsbAudio $true }
                        "5" { Install-X670E-Drivers -installUtilities $true }
                        "6" { break }
                        default { Write-Host "  [!] Opción inválida." -ForegroundColor Red }
                    }
                }
            }
            "6" { Optimize-Hardware }
            "7" { Optimize-Storage }
            "8" { Optimize-NetworkDNS }
            "9" { Install-Programs }
            "10" { Perform-Cleanup }
            "11" { 
                while ($true) {
                    $toolSelection = Show-AdvancedToolsMenu
                    switch ($toolSelection) {
                        "1" { Disable-TelemetryAndDefender }
                        "2" { Disable-WindowsUpdate }
                        "3" { Enable-AdminAccountAndBackup }
                        "4" { Optimize-UIAndExperience }
                        "5" { Optimize-NetworkAndRemoteAccess }
                        "6" { Reset-GroupPolicy }
                        "7" { Remove-MicrosoftCopilot }
                        "8" { break }
                        default { Write-Host "  [!] Opción inválida." -ForegroundColor Red }
                    }
                }
            }
            "12" { Show-History }
            "13" { 
                $endTime = Get-Date
                $duration = $endTime - $global:ExecutionHistory.StartTime
                Write-Host "`n  [!] SCRIPT FINALIZADO" -ForegroundColor Green
                Write-Host "  Duración total: $($duration.TotalMinutes) minutos" -ForegroundColor Gray
                Write-Host "  Operaciones realizadas: ${ExecutionHistory.Operations.Count}" -ForegroundColor Gray
                Write-Host "  Errores: ${ExecutionHistory.Errors.Count}" -ForegroundColor Red
                Write-Host "  Advertencias: ${ExecutionHistory.Warnings.Count}" -ForegroundColor Yellow
                Pause
                exit
            }
            default { Write-Host "  [!] Opción inválida." -ForegroundColor Red }
        }
    }
}

# Iniciar el optimizador
Start-Optimizer

# --- CÓDIGO AÑADIDO DESDE OTROS SCRIPTS ---

        [Parameter(Mandatory=$true)][string]$Action,
        [Parameter(Mandatory=$true)][string]$Target,
        [Parameter(Mandatory=$true)][string]$Status,
        $timestamp = Get-Date
        $operation = @{
            Timestamp = $timestamp
            Action = $Action
            Target = $Target
            Status = $Status
            Details = $Details
        # Add to history
        $global:ExecutionHistory.Operations += $operation
        # Categorize operation
        switch ($Status) {
            "Error" { $global:ExecutionHistory.Errors += $operation }
            "Warning" { $global:ExecutionHistory.Warnings += $operation }
            "Success" { 
                switch -Wildcard ($Action) {
                    "*modif*" { $global:ExecutionHistory.Stats.FilesModified++ }
                    "*config*" { $global:ExecutionHistory.Stats.SettingsChanged++ }
                    "*elimin*" { $global:ExecutionHistory.Stats.ItemsRemoved++ }
                    "*driver*" { $global:ExecutionHistory.Stats.DriversInstalled++ }
                    "*programa*" { $global:ExecutionHistory.Stats.ProgramsInstalled++ }
                    "*servicio*" { $global:ExecutionHistory.Stats.ServicesDisabled++ }
                    "*juego*" { $global:ExecutionHistory.Stats.GameOptimizations++ }
                    "*DNS*" { $global:ExecutionHistory.Stats.DNSOptimized++ }
        # Log to file
        $logMessage = "[${mm:ss'})] [$Status] $Action - $Target - $Details"
        Add-Content -Path $global:LogFile -Value $logMessage -ErrorAction Stop
        # Display with color
        $color = switch ($Status) {
        Write-Host $logMessage -ForegroundColor $color
        Write-Warning "Failed to register operation: $_"
        Clear-Host
        Write-Host ""
        Write-Host "  ███╗   ███╗ ██████╗ ██╗     ██╗███╗   ██╗ █████╗ " -ForegroundColor Cyan
        Write-Host "  ████╗ ████║██╔═══██╗██║     ██║████╗  ██║██╔══██╗" -ForegroundColor Cyan
        Write-Host "  ██╔████╔██║██║   ██║██║     ██║██╔██╗ ██║███████║" -ForegroundColor Cyan
        Write-Host "  ██║╚██╔╝██║██║   ██║██║     ██║██║╚██╗██║██╔══██║" -ForegroundColor Cyan
        Write-Host "  ██║ ╚═╝ ██║╚██████╔╝███████╗██║██║ ╚████║██║  ██║" -ForegroundColor Cyan
        Write-Host "  ╚═╝     ╚═╝ ╚═════╝ ╚══════╝╚═╝╚═╝  ╚═══╝╚═╝  ╚═╝" -ForegroundColor Cyan
        Write-Host ""
        Write-Host "  ██████╗ ██████╗ ████████╗██╗███╗   ███╗██╗███████╗██████╗ " -ForegroundColor Magenta
        Write-Host "  ██╔═══██╗██╔══██╗╚══██╔══╝██║████╗ ████║██║██╔════╝██╔══██╗" -ForegroundColor Magenta
        Write-Host "  ██║   ██║██████╔╝   ██║   ██║██╔████╔██║██║█████╗  ██████╔╝" -ForegroundColor Magenta
        Write-Host "  ██║   ██║██╔═══╝    ██║   ██║██║╚██╔╝██║██║██╔══╝  ██╔══██╗" -ForegroundColor Magenta
        Write-Host "  ╚██████╔╝██║        ██║   ██║██║ ╚═╝ ██║██║███████╗██║  ██║" -ForegroundColor Magenta
        Write-Host "   ╚═════╝ ╚═╝        ╚═╝   ╚═╝╚═╝     ╚═╝╚═╝╚══════╝╚═╝  ╚═╝" -ForegroundColor Magenta
        Write-Host ""
        Write-Host "  Versión 8.1 Extendida | Ultimate Windows Optimizer | Gaming Focus" -ForegroundColor Yellow
        Write-Host "  ────────────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host "  Sistema: ${ExecutionHistory.SystemInfo.OSVersion}"
        $hardwareInfo = "${ExecutionHistory.SystemInfo.Hardware.CPU}, ${ExecutionHistory.SystemInfo.Hardware.GPU}, ${ExecutionHistory.SystemInfo.Hardware.RAM}"
        Write-Host "  Hardware: $hardwareInfo"
        Write-Host "  PowerShell: ${ExecutionHistory.SystemInfo.PowerShellVersion}"
        Write-Host "  ────────────────────────────────────────────────────" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host "Error al mostrar encabezado: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Show-Header" -Status "Error" -Details $_.Exception.Message
        $params = @{
            Activity = $activity
            Status = $status
            PercentComplete = $percentComplete
        if ($secondsRemaining -ge 0) {
            $params.Add("SecondsRemaining", $secondsRemaining)
        Write-Progress @params
        Start-Sleep -Milliseconds 100
        Write-Host "Error en progreso: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Show-Progress" -Status "Error" -Details $_.Exception.Message
        if ($theme -eq "Auto") {
            $theme = if ((Get-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme").AppsUseLightTheme -eq 0) { "Dark" } else { "Light" }
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "AppsUseLightTheme" -Value ([int]($theme -eq "Light"))
        if (-not $init) {
            Write-Host "Tema cambiado a $theme" -ForegroundColor Cyan
            Register-Operation -Action "Cambio de tema" -Target "Interfaz" -Status "Success" -Details "Tema cambiado a $theme"
        Write-Host "Error al cambiar tema: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Cambio de tema" -Status "Error" -Details $_.Exception.Message
        Write-Host "`n[!] INICIANDO OPTIMIZACIÓN COMPLETA DEL SISTEMA..." -ForegroundColor Cyan
        Register-Operation -Action "Inicio" -Target "Optimización Completa" -Status "Info" -Details "Proceso iniciado"
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host "`n[1] Optimizando configuración del sistema..." -ForegroundColor Cyan
        Register-Operation -Action "Inicio" -Target "Configuración Sistema" -Status "Info" -Details "Modo agresivo: $aggressive"
        # Servicios a deshabilitar
        $servicesToDisable = @(
            "MapsBroker", "NetTcpPortSharing", "RemoteRegistry",
            "XblAuthManager", "XblGameSave", "XboxNetApiSvc",
            "SysMain", "WSearch", "lfsvc", "MixedRealityOpenXRSvc",
            "WMPNetworkSvc", "WMPNetworkSharingService", "Fax",
            "WerSvc", "wisvc", "WpcMonSvc", "WdiServiceHost", "DPS",
            "HomeGroupListener", "HomeGroupProvider"
        $servicesToEnable = @(
            "WlanSvc", "BthServ", "AudioEndpointBuilder", "Audiosrv"
        foreach ($service in $servicesToDisable) {
                Set-Service -Name $service -StartupType Disabled -ErrorAction Stop
        foreach ($service in $servicesToEnable) {
                Set-Service -Name $service -StartupType Automatic -ErrorAction Stop
                Start-Service -Name $service -ErrorAction SilentlyContinue
                Register-Operation -Action "Habilitar servicio" -Target $service -Status "Success" -Details "Servicio habilitado"
                Register-Operation -Action "Habilitar servicio" -Target $service -Status "Error" -Details $_.Exception.Message
        # Configuración de red
        $networkSettings = @(
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "EnableRSS"; Value = 1 },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "EnableTCPA"; Value = 1 },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "TcpTimedWaitDelay"; Value = 30 },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "KeepAliveTime"; Value = 30000 },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "DisableTaskOffload"; Value = 0 },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "TcpAckFrequency"; Value = 1 },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "TcpNoDelay"; Value = 1 },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters"; Name = "DisabledComponents"; Value = 255 },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "Tcp1323Opts"; Value = 1 },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "DefaultTTL"; Value = 64 },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "EnablePMTUDiscovery"; Value = 1 },
            @{ Path = "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters"; Name = "SackOpts"; Value = 1 }
        foreach ($setting in $networkSettings) {
                Register-Operation -Action "Configurar red" -Target $setting.Name -Status "Success" -Details "Valor establecido a $($setting.Value)"
                Register-Operation -Action "Configurar red" -Target $setting.Name -Status "Error" -Details $_.Exception.Message
        # Desactivar telemetría
        $telemetryKeys = @(
            "HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppCompat",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\TabletPC",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\HandwritingErrorReports",
            "HKLM:\SOFTWARE\Policies\Microsoft\InputPersonalization",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy",
            "HKLM:\SOFTWARE\Policies\Microsoft\Windows\CloudContent"
        foreach ($key in $telemetryKeys) {
                if (-not (Test-Path $key)) { New-Item -Path $key -Force | Out-Null }
                Set-ItemProperty -Path $key -Name "AllowTelemetry" -Type DWord -Value 0
                Set-ItemProperty -Path $key -Name "DoNotShowFeedbackNotifications" -Type DWord -Value 1
                Set-ItemProperty -Path $key -Name "DisableTelemetry" -Type DWord -Value 1
                Register-Operation -Action "Deshabilitar telemetría" -Target $key -Status "Success" -Details "Configuración aplicada"
                Register-Operation -Action "Deshabilitar telemetría" -Target $key -Status "Error" -Details $_.Exception.Message
        # Configuración de energía
            powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  # High Performance
            powercfg -h off
            Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "HibernateEnabled" -Type DWord -Value 0
            Register-Operation -Action "Configuración energía" -Target "Sistema" -Status "Success" -Details "Plan alto rendimiento activado"
            Register-Operation -Action "Configuración energía" -Target "Sistema" -Status "Error" -Details $_.Exception.Message
        Write-Host "Optimización del sistema completada." -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Configuración Sistema" -Status "Success" -Details "Optimización completada"
        Write-Host "Error: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Optimización Sistema" -Status "Error" -Details $_.Exception.Message
        Write-Host "`n[2] Eliminando bloatware..." -ForegroundColor Cyan
        Register-Operation -Action "Inicio" -Target "Eliminación de bloatware" -Status "Info" -Details "Iniciando eliminación"
        # Eliminar OneDrive
            Stop-Process -Name "OneDrive" -Force -ErrorAction SilentlyContinue
            Start-Sleep -Seconds 2
            $onedrivePath = "$env:SYSTEMDRIVE\Windows\SysWOW64\OneDriveSetup.exe"
            if (Test-Path $onedrivePath) {
                Start-Process -FilePath $onedrivePath -ArgumentList "/uninstall" -NoNewWindow -Wait
            $folders = @(
                "$env:USERPROFILE\OneDrive",
                "$env:LOCALAPPDATA\Microsoft\OneDrive",
                "$env:PROGRAMDATA\Microsoft OneDrive",
                "$env:SYSTEMDRIVE\OneDriveTemp"
            )
            foreach ($folder in $folders) {
                if (Test-Path $folder) {
                    Remove-Item -Path $folder -Recurse -Force -ErrorAction SilentlyContinue
            Register-Operation -Action "Eliminar" -Target "OneDrive" -Status "Success" -Details "OneDrive desinstalado"
            Register-Operation -Action "Eliminar" -Target "OneDrive" -Status "Error" -Details $_.Exception.Message
        # Eliminar aplicaciones preinstaladas
        foreach ($app in $global:ExecutionHistory.BloatwareApps) {
                Get-AppxPackage -Name $app -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
                Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
                Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object DisplayName -like $app | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
                Register-Operation -Action "Eliminar" -Target $app -Status "Success" -Details "Aplicación eliminada"
                Register-Operation -Action "Eliminar" -Target $app -Status "Error" -Details $_.Exception.Message
        Write-Host "Eliminación de bloatware completada." -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Eliminación de bloatware" -Status "Success" -Details "Proceso completado"
        Write-Host "Error: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Eliminación de bloatware" -Status "Error" -Details $_.Exception.Message
        Write-Host "`n[3] Optimizando juegos..." -ForegroundColor Cyan
        Register-Operation -Action "Inicio" -Target "Optimizar Juegos" -Status "Info" -Details "Juego: $GameName"
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host "`n[4] Instalando drivers para X670E-F..." -ForegroundColor Cyan
        Register-Operation -Action "Inicio" -Target "Instalar Drivers" -Status "Info" -Details "Iniciando instalación"
        $basePath = $global:DriverPaths.X670E
        if (-not (Test-Path $basePath)) {
            Register-Operation -Action "Verificación" -Target "Ruta de drivers" -Status "Error" -Details "Ruta no encontrada: $basePath"
            Write-Host "Error: Ruta de drivers no encontrada." -ForegroundColor Red
            return
        Write-Host "Error: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Instalar Drivers" -Status "Error" -Details $_.Exception.Message
        Write-Host "`n[5] Optimizando hardware específico..." -ForegroundColor Cyan
        Register-Operation -Action "Inicio" -Target "Optimizar Hardware" -Status "Info" -Details "Iniciando optimización"
                Register-Operation -Action "Optimizar" -Target "Ryzen 7600X" -Status "Success" -Details "Configuración aplicada"
                Register-Operation -Action "Optimizar" -Target "Ryzen 7600X" -Status "Error" -Details $_.Exception.Message
        # Optimización para GPU NVIDIA
                Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000" -Name "EnableMsHybrid" -Type DWord -Value 0
        Write-Host "Error: $_" -ForegroundColor Red
function Optimize-SpecificHardware {
        Write-Host "`n[+] Optimizing for Ryzen 7600X + 32GB 6400MHz CL30 + RTX 4060..." -ForegroundColor Cyan
        Register-Operation -Action "Inicio" -Target "Optimizar Hardware Específico" -Status "Info" -Details "Iniciando optimización"
        # RAM Optimizations for 32GB 6400MHz
        $ramSettings = @{
            "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" = @{
                "LargeSystemCache" = 0
                "IoPageLockLimit" = 983040
                "DisablePagingExecutive" = 1
        foreach ($path in $ramSettings.Keys) {
            if (!(Test-Path $path)) {
            foreach ($name in $ramSettings[$path].Keys) {
                Set-ItemProperty -Path $path -Name $name -Value $ramSettings[$path][$name] -Type DWord -Force
        # Power Plan Optimization
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        Write-Host "`n[✓] Hardware-specific optimizations completed!" -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Optimizar Hardware Específico" -Status "Success" -Details "Optimización completada"
        Write-Host "Error: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Optimizar Hardware Específico" -Status "Error" -Details $_.Exception.Message
        Write-Host "`n[6] Optimizando almacenamiento (SSD/HDD)..." -ForegroundColor Cyan
        Register-Operation -Action "Inicio" -Target "Optimizar Almacenamiento" -Status "Info" -Details "Iniciando optimización"
                Optimize-Volume -DriveLetter "C" -ReTrim -Verbose -ErrorAction SilentlyContinue
        Write-Host "`n[!] ALMACENAMIENTO OPTIMIZADO CORRECTAMENTE" -ForegroundColor Green
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host "`n[7] Optimizando red y DNS..." -ForegroundColor Cyan
        Register-Operation -Action "Inicio" -Target "Optimizar Red y DNS" -Status "Info" -Details "Iniciando optimización"
        $netAdapters = Get-NetAdapter -Physical | Where-Object { $_.Status -eq "Up" }
        foreach ($adapter in $netAdapters) {
                Set-DnsClientServerAddress -InterfaceAlias $adapter.Name -ServerAddresses ($global:ExecutionHistory.DnsServers[0], $global:ExecutionHistory.DnsServers[1]) -ErrorAction Stop
                Register-Operation -Action "Configurar DNS" -Target $adapter.Name -Status "Success" -Details "DNS establecido"
                Register-Operation -Action "Configurar DNS" -Target $adapter.Name -Status "Error" -Details $_.Exception.Message
        Write-Host "`n[!] RED Y DNS OPTIMIZADOS CORRECTAMENTE" -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Optimizar Red y DNS" -Status "Success" -Details "Optimización completada"
        Write-Host "Error: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Optimizar Red y DNS" -Status "Error" -Details $_.Exception.Message
        Write-Host "`n[8] Instalando programas esenciales..." -ForegroundColor Cyan
        Register-Operation -Action "Inicio" -Target "Instalar Programas" -Status "Info" -Details "Iniciando instalación"
        $wingetPackages = @(
            "Mozilla.Firefox",
            "Google.Chrome",
            "VideoLAN.VLC",
            "7zip.7zip"
        foreach ($package in $wingetPackages) {
                Write-Host "Instalando $package..." -ForegroundColor Yellow
                winget install --id $package -e --silent --accept-package-agreements --accept-source-agreements
                Register-Operation -Action "Instalar" -Target $package -Status "Success" -Details "Programa instalado"
                Register-Operation -Action "Instalar" -Target $package -Status "Error" -Details $_.Exception.Message
        Write-Host "`n[!] PROGRAMAS INSTALADOS CORRECTAMENTE" -ForegroundColor Green
        Write-Host "Error: $_" -ForegroundColor Red
        Write-Host "`n[9] Realizando limpieza del sistema..." -ForegroundColor Cyan
        Register-Operation -Action "Inicio" -Target "Limpieza" -Status "Info" -Details "Iniciando limpieza"
        $tempFolders = @("$env:TEMP", "$env:SYSTEMDRIVE\Windows\Temp")
                    Get-ChildItem -Path $folder -Recurse -Force -ErrorAction SilentlyContinue | Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
                    Register-Operation -Action "Eliminar" -Target $folder -Status "Success" -Details "Archivos temporales eliminados"
                    Register-Operation -Action "Eliminar" -Target $folder -Status "Error" -Details $_.Exception.Message
        Write-Host "`n[!] LIMPIEZA DEL SISTEMA COMPLETADA" -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Limpieza" -Status "Success" -Details "Limpieza completada"
        Write-Host "Error: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Limpieza" -Status "Error" -Details $_.Exception.Message
function Disable-RemoteServices {
        Write-Host "`n[+] Disabling Remote Services..." -ForegroundColor Cyan
        Register-Operation -Action "Inicio" -Target "Deshabilitar Servicios Remotos" -Status "Info" -Details "Iniciando proceso"
        $remoteServices = @("RemoteRegistry", "TermService", "SessionEnv", "UmRdpService")
        foreach ($service in $remoteServices) {
                $svc = Get-Service -Name $service -ErrorAction SilentlyContinue
                if ($svc) {
                    Stop-Service -Name $service -Force -ErrorAction Stop
                    Set-Service -Name $service -StartupType Disabled -ErrorAction Stop
                    Register-Operation -Action "Deshabilitar" -Target $service -Status "Success" -Details "Servicio remoto deshabilitado"
                Register-Operation -Action "Deshabilitar" -Target $service -Status "Error" -Details $_.Exception.Message
        Write-Host "`n[✓] Remote services disabled successfully!" -ForegroundColor Green
        Register-Operation -Action "Finalización" -Target "Deshabilitar Servicios Remotos" -Status "Success" -Details "Proceso completado"
        Write-Host "Error: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Deshabilitar Servicios Remotos" -Status "Error" -Details $_.Exception.Message
# region Menu System
        Clear-Host
        Show-Header
        $menu = @"
  MENU PRINCIPAL
  ──────────────
  1. Optimización completa del sistema
  2. Eliminar bloatware
  3. Optimizar juegos
  4. Instalar drivers X670E-F
  5. Optimizar hardware
  6. Optimizar almacenamiento (SSD/HDD)
  7. Optimizar red y DNS
  8. Instalar programas esenciales
  9. Realizar limpieza del sistema
  10. Menú avanzado
  11. Mostrar log de ejecución
  12. Salir
"@
        Write-Host $menu
        Write-Host ""
        do {
            $choice = Read-Host "Seleccione una opción (1-12)"
        } while ($choice -notmatch '^([1-9]|1[0-2])$')
        return $choice
        Write-Host "Error en el menú: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Menú Principal" -Status "Error" -Details $_.Exception.Message
        return $null
function Show-AdvancedMenu {
        Show-Header
        Write-Host "  MENÚ AVANZADO" -ForegroundColor Yellow
        Write-Host "  ─────────────" -ForegroundColor DarkGray
        Write-Host "  1. Optimizar configuración avanzada del sistema"
        Write-Host "  2. Optimizar juego específico"
        Write-Host "  3. Instalar drivers específicos X670E-F"
        Write-Host "  4. Optimizar hardware específico (Ryzen 7600X + RTX 4060)"
        Write-Host "  5. Deshabilitar servicios remotos"
        Write-Host "  6. Cambiar tema de Windows (Claro/Oscuro)"
        Write-Host "  7. Volver al menú principal"
        Write-Host ""
        $choice = Read-Host "Seleccione una opción (1-7)"
        return $choice
        Write-Host "Error en el menú avanzado: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Menú Avanzado" -Status "Error" -Details $_.Exception.Message
        return $null
function Main {
        if (-not (Test-Admin)) {
            Write-Host "Este script requiere privilegios de administrador." -ForegroundColor Red
            Pause
            return
        Invoke-WinutilThemeChange -theme "Auto" -init $true
        while ($true) {
            $mainChoice = Show-MainMenu
            switch ($mainChoice) {
                "1" { Optimize-SystemFull }
                "2" { Remove-Bloatware }
                "3" { Optimize-Games -GameName "All" }
                "4" { Install-X670E-Drivers }
                "5" { Optimize-Hardware }
                "6" { Optimize-Storage }
                "7" { Optimize-NetworkDNS }
                "8" { Install-Programs }
                "9" { Perform-Cleanup }
                "10" {
                    while ($true) {
                        $advChoice = Show-AdvancedMenu
                        switch ($advChoice) {
                            "1" { Optimize-SystemSettings -aggressive $true }
                            "2" {
                                $game = Read-Host "Ingrese el juego a optimizar (VALORANT, NewWorld, Tarkov)"
                                if ($game -in @("VALORANT", "NewWorld", "Tarkov")) {
                                    Optimize-Games -GameName $game
                                } else {
                                    Write-Host "Juego no válido. Use VALORANT, NewWorld o Tarkov." -ForegroundColor Red
                            "3" {
                                Write-Host "`nSeleccione drivers a instalar:" -ForegroundColor Cyan
                                Write-Host "1. Todos"
                                Write-Host "2. Bluetooth"
                                Write-Host "3. WiFi"
                                Write-Host "4. USB Audio"
                                Write-Host "5. LAN"
                                Write-Host "6. Chipset"
                                Write-Host "7. Utilidades"
                                $driverChoice = Read-Host "Seleccione una opción (1-7)"
                                switch ($driverChoice) {
                                    "1" { Install-X670E-Drivers -installAll $true }
                                    "2" { Install-X670E-Drivers -installBluetooth $true }
                                    "3" { Install-X670E-Drivers -installWifi $true }
                                    "4" { Install-X670E-Drivers -installUsbAudio $true }
                                    "5" { Install-X670E-Drivers -installLan $true }
                                    "6" { Install-X670E-Drivers -installChipset $true }
                                    "7" { Install-X670E-Drivers -installUtilities $true }
                                    default { Write-Host "Opción no válida" -ForegroundColor Red }
                            "4" { Optimize-SpecificHardware }
                            "5" { Disable-RemoteServices }
                            "6" {
                                $theme = Read-Host "Seleccione tema (Claro/Oscuro)"
                                if ($theme -in @("Claro", "Oscuro")) {
                                    Invoke-WinutilThemeChange -theme $theme
                                } else {
                                    Write-Host "Tema no válido" -ForegroundColor Red
                            "7" { break }
                            default { Write-Host "Opción no válida" -ForegroundColor Red }
                        Pause
                "11" {
                    Show-Header
                    Write-Host "LOG DE EJECUCIÓN" -ForegroundColor Yellow
                    Write-Host "────────────────" -ForegroundColor DarkGray
                    Get-Content $global:LogFile -ErrorAction SilentlyContinue | Out-Host
                    Write-Host "`nESTADÍSTICAS:" -ForegroundColor Yellow
                    Write-Host "Archivos modificados: ${ExecutionHistory.Stats.FilesModified}"
                    Write-Host "Configuraciones cambiadas: ${ExecutionHistory.Stats.SettingsChanged}"
                    Write-Host "Elementos eliminados: ${ExecutionHistory.Stats.ItemsRemoved}"
                    Write-Host "Drivers instalados: ${ExecutionHistory.Stats.DriversInstalled}"
                    Write-Host "Programas instalados: ${ExecutionHistory.Stats.ProgramsInstalled}"
                    Write-Host "Servicios deshabilitados: ${ExecutionHistory.Stats.ServicesDisabled}"
                    Write-Host "Optimizaciones de juegos: ${ExecutionHistory.Stats.GameOptimizations}"
                    Write-Host "DNS optimizados: ${ExecutionHistory.Stats.DNSOptimized}"
                    Pause
                "12" { 
                    Write-Host "`nSaliendo..." -ForegroundColor Yellow
                    Register-Operation -Action "Finalización" -Target "Script" -Status "Info" -Details "Script finalizado por el usuario"
                    return 
                default { Write-Host "Opción no válida" -ForegroundColor Red }
            Pause
        Write-Host "Error crítico: $_" -ForegroundColor Red
        Register-Operation -Action "Error" -Target "Script" -Status "Error" -Details $_.Exception.Message
    } finally {
        Write-Host "Finalizando script..." -ForegroundColor Yellow
# Ejecución principal
try {
        Write-Host "Este script requiere privilegios de administrador." -ForegroundColor Red
        exit 1
    # Initialize logging
    Start-Transcript -Path "$env:TEMP\script_log_$(Get-Date -Format 'yyyyMMdd_HHmmss').txt" -Append
    Main

} catch {
    Write-Host "Error desconocido en bloque try."
}} catch {
    Write-Host "Error crítico en el script: $_" -ForegroundColor Red
    Register-Operation -Action "Error crítico" -Target "Script" -Status "Error" -Details $_.Exception.Message
} finally {
    Write-Host "Finalizando script..." -ForegroundColor Yellow
    Invoke-WinutilThemeChange -theme "Auto" -init $false
    Register-Operation -Action "Finalización" -Target "Script" -Status "Info" -Details "Script finalizado"
    Stop-Transcript
    # Community optimizations for gaming
    $gamingTweaks = @{
        # Power settings
        "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\943c8cb6-6f93-4227-ad87-e9a3feec08d1" = @{
            "Attributes" = 2
        # Mouse and keyboard response
        "HKCU:\Control Panel\Mouse" = @{
            "MouseSensitivity" = "10"
            "MouseSpeed" = "0"
            "MouseThreshold1" = "0"
            "MouseThreshold2" = "0"
        # Network optimizations
        "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters" = @{
            "TcpNoDelay" = 1
            "TCPDelAckTicks" = 0
            "TcpMaxDataRetransmissions" = 3
            "SackOpts" = 1
            "DefaultTTL" = 64
        # NVIDIA Latency tweaks
        "HKLM:\SYSTEM\CurrentControlSet\Services\nvlddmkm\Parameters" = @{
            "RmGpsPsEnablePerCpuCoreDpc" = 1
            "RmGpsPsEnablePerCpuCoreDpcCompat" = 1
            "EnableAsyncDMA" = 1
        # Memory management
        "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" = @{
            "LargeSystemCache" = 0
            "IoPageLockLimit" = 983040
            "DisablePagingExecutive" = 1
    foreach ($path in $gamingTweaks.Keys) {
        if (!(Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        foreach ($name in $gamingTweaks[$path].Keys) {
            Set-ItemProperty -Path $path -Name $name -Value $gamingTweaks[$path][$name] -Type DWord -Force
    # Disable unnecessary features
        "WindowsMediaPlayer", "FaxServicesClientPackage",
        "MicrosoftWindowsPowerShellV2", "WorkFolders-Client"
        Disable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart | Out-Null
    # Process priority optimizations
    $processPriorities = @{
        "csrss.exe" = "High"
        "dwm.exe" = "High"
        "navigator.exe" = "High"
    foreach ($process in $processPriorities.Keys) {
        Get-Process -Name ($process -replace ".exe","") -ErrorAction SilentlyContinue | 
        ForEach-Object { $_.PriorityClass = $processPriorities[$process] }
    # Additional Windows services optimization
    $serviceTweaks = @{
        "DiagTrack" = "Disabled"
        "WSearch" = "Disabled"
        "SysMain" = "Disabled"
        "WerSvc" = "Disabled"
    foreach ($service in $serviceTweaks.Keys) {
        Set-Service -Name $service -StartupType $serviceTweaks[$service] -ErrorAction SilentlyContinue
    # Apply registry optimizations from gaming communities
    $communityTweaks = @{
        # NVIDIA Latency Tweaks
        "HKLM:\SOFTWARE\NVIDIA Corporation\Global\FTS" = @{
            "EnableRID" = 1
            "EnableGR535" = 1
        # Mouse Fix
        "HKCU:\Control Panel\Mouse" = @{
            "SmoothMouseXCurve" = @(
                0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                0xC0,0xCC,0x0C,0x00,0x00,0x00,0x00,0x00,
                0x80,0x99,0x19,0x00,0x00,0x00,0x00,0x00,
                0x40,0x66,0x26,0x00,0x00,0x00,0x00,0x00,
                0x00,0x33,0x33,0x00,0x00,0x00,0x00,0x00
            )
    foreach ($path in $communityTweaks.Keys) {
        if (!(Test-Path $path)) {
            New-Item -Path $path -Force | Out-Null
        foreach ($name in $communityTweaks[$path].Keys) {
            Set-ItemProperty -Path $path -Name $name -Value $communityTweaks[$path][$name] -Force
        Set-Item
}}}}}}}}}}