<#
    .SYNOPSIS
    This script shows the amount of remaining hard drive space on servers, remotely pulled.

    .DESCRIPTION
    This script pulls the percentage free and the amount free in MB of remote servers.  It accepts a list or a single.

    When run, it will ask for a regular user account and a domain admin account (called "-a" in this script).  It will try the regular user account first, then the domain admin account if the regular account fails.

    .EXAMPLE
    Get-HardDiskSpace -ServerList comp1,comp2,comp3
#>
Function Get-HardDiskSpace()
{
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$true)]
        [array]$ServerList
        )

    $Creds = Get-Credential -Message "Enter basic account"
    $AdminCreds = Get-Credential -Message "Enter -a account"
    $List = $ServerList.split(",").Trim(" ")

    foreach ($Server in $List)
    {
        $disk = $null
        $PercentageFree = $null
        try {
            $Session = new-pssession -ComputerName $Server -Credential $Creds -ErrorAction SilentlyContinue
            $disk = Invoke-Command -Session $Session {Get-WmiObject Win32_LogicalDisk -Filter "DriveType = 3"} -ErrorAction SilentlyContinue  | Select-Object Size,FreeSpace
        }
        catch {
            try {
                $Session = new-pssession -ComputerName $Server -Credential $AdminCreds -ErrorAction SilentlyContinue
                $disk = Invoke-Command -Session $Session {Get-WmiObject Win32_LogicalDisk -Filter "DriveType = 3"} -ErrorAction SilentlyContinue  | Select-Object Size,FreeSpace
            }
            catch {
                $Server
            }
        }


        if ($disk -ne $null)
        {
            $FreeSpaceMB = ($disk.FreeSpace/1024)/1024
            $PercentageFree = ($disk.FreeSpace / $disk.Size) * 100
            $PercentageFreeRound = [math]::Round($PercentageFree)

            Write-Output "$Server   -   Free Space %: $PercentageFreeRound%    -   Free Space (MB): $FreeSpaceMB"
        }
    }
}
