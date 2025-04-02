# Verificar si el procesador es AMD Ryzen 7600X
$CPU = (Get-CimInstance Win32_Processor).Name
if ($CPU -match "7600X") {
    Write-Host "Optimizando CPU AMD Ryzen 7600X..." -ForegroundColor Cyan
    
    try {
        # Activar plan de energía Ryzen High Performance si no está activo
        $RyzenPlan = "e9a42b02-d5df-44b1-8c3f-7c0d4b0a2e4f"
        $ActivePlan = powercfg -getactivescheme
        if ($ActivePlan -notmatch $RyzenPlan) {
            powercfg -duplicatescheme $RyzenPlan
            powercfg -setactive $RyzenPlan
        }
        
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
        $global:historial += "Optimización aplicada con overclock y configuraciones para juegos."
    } catch {
        Write-Host "Error al optimizar: $_" -ForegroundColor Red
        $global:historial += "Error: $_"
    }
} else {
    Write-Host "Este script está diseñado para AMD Ryzen 7600X. CPU detectado: $CPU" -ForegroundColor Yellow
}
