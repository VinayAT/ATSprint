start-transcript

$AllServers=Get-ADComputer -Filter 'operatingsystem -like "*server*" -and enabled -eq "true"' -Properties ServerName,Operatingsystem,OperatingSystemVersion,IPv4Address |Sort-Object -Property Operatingsystem |Select-Object -Property Name,Operatingsystem,IPv4Address

$printservers= @()
$spoolDisabled = @()
$rdshost = @()

foreach ($server in $allServers.name)
{
    If (Test-Connection -BufferSize 32 -Count 1 -ComputerName $server -Quiet)
    {
        #$sharedprinters = get-printer -ComputerName $server | where {$_.shared}
        $sharedprinters = Get-CimInstance Win32_Printer -ComputerName $server | where {$_.ShareName -ne $Null}
        if ($sharedprinters.Count -ge 1)
        {
            Write-Host "$($Server) is a Print Server. Patch it."
            $printservers += $Server
        } elseif (get-windowsfeature -Name RDS-Connection-Broker -ComputerName $server|Where Installed) {
            Write-Host "$($Server) is a Terminal Server. Patch it."
            $rdshost += $Server
        } 
        
        else {
            try{
                Invoke-Command -ComputerName $server -ScriptBlock { (Stop-Service -Name Spooler -Force), (Set-Service -Name Spooler -StartupType Disabled) }
                Write-Host "$($Server) spooler service has been stopped and disabled."
                $spoolDisabled += $Server
            } catch {
                Write-Host "$($Server) Error: unable to stop/disable spooler service."
            }
        }   
        
    } else {
            write-host "$Server is Offline"
        }
}

write-host "Print Server(s). Patch these:-"  -ForegroundColor black -backgroundcolor yellow
foreach ($pserver in $printservers)
    {
        $OS = $(((gcim Win32_OperatingSystem -ComputerName $pserver).Name).split(‘|’)[0])
        Write-Host "$($pserver) OS: $($OS)"
     }
write-host "Terminal Server(s). Patch these:-" -ForegroundColor black -backgroundcolor yellow
foreach ($RDH in $rdshost)
    {
        $OS = $(((gcim Win32_OperatingSystem -ComputerName $RDH).Name).split(‘|’)[0])
        Write-Host "$($RDH) OS: $($OS)" 
     }
write-host "Print Spools Disabled: $($spoolDisabled)." -ForegroundColor black -backgroundcolor yellow

Stop-transcript
