# Lester Artis 03/21/2025

# SQL Server Monitoring and Job Status Script

# This script monitors SQL Server instances for job status, backups, disk space, and more

# Network paths and settings
$serverListPath = ""
$logFolderPath = ""
$backupRetentionDays = 30

# Function to get SQL Server job statuses from a remote server
function Get-SQLServerJobStatus {
    param(
        [string]$ComputerName,
        [System.Management.Automation.PSCredential]$Credential = $null
    )
   
    Write-Host "Getting SQL Server job statuses from $ComputerName..."
   
    try {
        # Use Invoke-Command to run the SQL query remotely
        $jobStatuses = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            # Load SQL Server module if available
            if (Get-Module -ListAvailable -Name SQLPS) {
                Import-Module SQLPS -DisableNameChecking
            }
            elseif (Get-Module -ListAvailable -Name SqlServer) {
                Import-Module SqlServer
            }
            else {
                throw "SQL Server PowerShell modules not found on $using:ComputerName"
            }
           
            # Get all SQL instances on the server
            $instances = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL" |
                Select-Object -Property * -ExcludeProperty PSPath, PSParentPath, PSChildName, PSProvider |
                Get-Member -MemberType NoteProperty |
                Select-Object -ExpandProperty Name
           
            if (-not $instances) {
                $instances = @("MSSQLSERVER") # Default instance if none found
            }
           
            $allJobStatuses = @()
           
            foreach ($instance in $instances) {
                $instanceName = if ($instance -eq "MSSQLSERVER") { $env:COMPUTERNAME } else { "$($env:COMPUTERNAME)\$instance" }
               
                try {
                    # Get job information using SMO
                    $server = New-Object Microsoft.SqlServer.Management.Smo.Server($instanceName)
                    $jobs = $server.JobServer.Jobs
                   
                    foreach ($job in $jobs) {
                        $lastRunOutcome = $job.LastRunOutcome
                        $lastRunStatus = switch ($lastRunOutcome) {
                            "Succeeded" { "Success" }
                            "Failed" { "Failed" }
                            "Canceled" { "Canceled" }
                            "Unknown" { "Unknown" }
                            default { $lastRunOutcome }
                        }
                       
                        # Get job failure details if job failed
                        $failureMessage = ""
                        if ($lastRunStatus -eq "Failed") {
                            try {
                                $jobHistory = $job.JobSteps | ForEach-Object {
                                    $stepHistory = $_.EnumLogs()
                                    if ($stepHistory) {
                                        foreach ($hist in $stepHistory) {
                                            if ($hist.Outcome -ne "Succeeded") {
                                                [PSCustomObject]@{
                                                    StepName = $_.Name
                                                    Message = $hist.Message
                                                    RunStatus = $hist.Outcome
                                                    RunDate = $hist.RunDate
                                                }
                                            }
                                        }
                                    }
                                }
                               
                                if ($jobHistory) {
                                    $failureMessage = ($jobHistory | ForEach-Object { "Step '$($_.StepName)': $($_.Message)" }) -join " | "
                                }
                            }
                            catch {
                                $failureMessage = "Could not retrieve detailed failure info: ${_}"
                            }
                        }
                       
                        $allJobStatuses += [PSCustomObject]@{
                            ServerName = $env:COMPUTERNAME
                            InstanceName = $instanceName
                            JobName = $job.Name
                            Enabled = $job.IsEnabled
                            Category = $job.Category
                            LastRunDate = $job.LastRunDate
                            LastRunOutcome = $lastRunStatus
                            NextRunDate = $job.NextRunDate
                            CurrentRunStatus = $job.CurrentRunStatus
                            LastRunDuration = $job.LastRunDuration
                            Description = $job.Description
                            FailureDetails = $failureMessage
                        }
                    }
                }
                catch {
                    Write-Warning "Failed to get job status for instance $instanceName on $($env:COMPUTERNAME): ${_}"
                }
            }
           
            return $allJobStatuses
        } -ErrorAction Stop
       
        return $jobStatuses
    }
    catch {
        Write-Host "Failed to retrieve SQL job statuses from ${ComputerName}: ${_}" -ForegroundColor Red
        return $null
    }
}

# Function to get backup information
function Get-SQLServerBackupInfo {
    param(
        [string]$ComputerName,
        [System.Management.Automation.PSCredential]$Credential = $null
    )
   
    Write-Host "Getting SQL Server backup information from $ComputerName..."
   
    try {
        # Use Invoke-Command to run the SQL query remotely
        $backupInfo = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            # Load SQL Server module if available
            if (Get-Module -ListAvailable -Name SQLPS) {
                Import-Module SQLPS -DisableNameChecking
            }
            elseif (Get-Module -ListAvailable -Name SqlServer) {
                Import-Module SqlServer
            }
            else {
                throw "SQL Server PowerShell modules not found on $using:ComputerName"
            }
           
            # Get all SQL instances on the server
            $instances = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL" |
                Select-Object -Property * -ExcludeProperty PSPath, PSParentPath, PSChildName, PSProvider |
                Get-Member -MemberType NoteProperty |
                Select-Object -ExpandProperty Name
           
            if (-not $instances) {
                $instances = @("MSSQLSERVER") # Default instance if none found
            }
           
            $allBackupInfo = @()
           
            foreach ($instance in $instances) {
                $instanceName = if ($instance -eq "MSSQLSERVER") { $env:COMPUTERNAME } else { "$($env:COMPUTERNAME)\$instance" }
               
                try {
                    # Get backup information using T-SQL
                    $server = New-Object Microsoft.SqlServer.Management.Smo.Server($instanceName)
                   
                    # Get backup directory configurations
                    $backupDirectories = @()
                    $backupDirectories += $server.BackupDirectory
                   
                    # Query for recent backups
                    $query = @"
                    SELECT
                        bs.database_name,
                        bs.backup_start_date,
                        bs.backup_finish_date,
                        bs.backup_size,
                        bmf.physical_device_name,
                        CASE bs.type
                            WHEN 'D' THEN 'Full'
                            WHEN 'I' THEN 'Differential'
                            WHEN 'L' THEN 'Log'
                            ELSE 'Unknown'
                        END AS backup_type,
                        CASE bs.is_copy_only
                            WHEN 1 THEN 'Copy Only'
                            ELSE 'Normal'
                        END AS is_copy_only,
                        bs.is_damaged,
                        bs.is_password_protected
                    FROM msdb.dbo.backupset bs
                    INNER JOIN msdb.dbo.backupmediafamily bmf ON bs.media_set_id = bmf.media_set_id
                    WHERE bs.backup_start_date >= DATEADD(day, -30, GETDATE())
                    ORDER BY bs.backup_start_date DESC
"@
                   
                    $backups = $server.ConnectionContext.ExecuteWithResults($query).Tables[0]
                   
                    foreach ($backup in $backups) {
                        $allBackupInfo += [PSCustomObject]@{
                            ServerName = $env:COMPUTERNAME
                            InstanceName = $instanceName
                            DatabaseName = $backup.database_name
                            BackupStartDate = $backup.backup_start_date
                            BackupFinishDate = $backup.backup_finish_date
                            BackupType = $backup.backup_type
                            BackupSize = [math]::Round($backup.backup_size / 1024 / 1024, 2)  # Convert to MB
                            PhysicalDeviceName = $backup.physical_device_name
                            IsCopyOnly = $backup.is_copy_only
                            IsDamaged = $backup.is_damaged
                            IsPasswordProtected = $backup.is_password_protected
                        }
                    }
                   
                    # Get databases without recent backups
                    $query2 = @"
                    SELECT
                        d.name AS database_name,
                        COALESCE(MAX(bs.backup_finish_date), '1900-01-01') AS last_backup_date,
                        DATEDIFF(day, COALESCE(MAX(bs.backup_finish_date), '1900-01-01'), GETDATE()) AS days_since_last_backup
                    FROM sys.databases d
                    LEFT JOIN msdb.dbo.backupset bs ON bs.database_name = d.name
                    WHERE d.name NOT IN ('tempdb')
                    GROUP BY d.name
                    HAVING DATEDIFF(day, COALESCE(MAX(bs.backup_finish_date), '1900-01-01'), GETDATE()) > 1
                    ORDER BY days_since_last_backup DESC
"@
                   
                    $missingBackups = $server.ConnectionContext.ExecuteWithResults($query2).Tables[0]
                   
                    # Add backup directory info
                    $allBackupInfo += [PSCustomObject]@{
                        ServerName = $env:COMPUTERNAME
                        InstanceName = $instanceName
                        DatabaseName = "SYSTEM_INFO"
                        BackupStartDate = Get-Date
                        BackupFinishDate = Get-Date
                        BackupType = "INFO"
                        BackupSize = 0
                        PhysicalDeviceName = "Default backup directory: $($server.BackupDirectory)"
                        IsCopyOnly = "N/A"
                        IsDamaged = $false
                        IsPasswordProtected = $false
                    }
                   
                    # Add missing backup info
                    foreach ($miss in $missingBackups) {
                        $allBackupInfo += [PSCustomObject]@{
                            ServerName = $env:COMPUTERNAME
                            InstanceName = $instanceName
                            DatabaseName = $miss.database_name
                            BackupStartDate = $miss.last_backup_date
                            BackupFinishDate = $miss.last_backup_date
                            BackupType = "MISSING"
                            BackupSize = 0
                            PhysicalDeviceName = "N/A"
                            IsCopyOnly = "N/A"
                            IsDamaged = $false
                            IsPasswordProtected = $false
                            DaysSinceLastBackup = $miss.days_since_last_backup
                        }
                    }
                }
                catch {
                    Write-Warning "Failed to get backup info for instance $instanceName on $($env:COMPUTERNAME): ${_}"
                }
            }
           
            return $allBackupInfo
        } -ErrorAction Stop
       
        return $backupInfo
    }
    catch {
        Write-Host "Failed to retrieve SQL backup information from ${ComputerName}: ${_}" -ForegroundColor Red
        return $null
    }
}

# Function to get disk space information
function Get-ServerDiskSpace {
    param(
        [string]$ComputerName,
        [System.Management.Automation.PSCredential]$Credential = $null
    )
   
    Write-Host "Getting disk space information from $ComputerName..."
   
    try {
        # Use Invoke-Command to get disk space information remotely
        $diskSpace = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            Get-WmiObject -Class Win32_LogicalDisk -Filter "DriveType = 3" |
            Select-Object -Property DeviceID,
                @{Name="Size(GB)"; Expression={[math]::Round($_.Size / 1GB, 2)}},
                @{Name="FreeSpace(GB)"; Expression={[math]::Round($_.FreeSpace / 1GB, 2)}},
                @{Name="Used(GB)"; Expression={[math]::Round(($_.Size - $_.FreeSpace) / 1GB, 2)}},
                @{Name="PercentFree"; Expression={[math]::Round(($_.FreeSpace / $_.Size) * 100, 2)}}
        } -ErrorAction Stop
       
        return $diskSpace
    }
    catch {
        Write-Host "Failed to retrieve disk space information from ${ComputerName}: ${_}" -ForegroundColor Red
        return $null
    }
}

# Function to test SQL Server connection
function Test-SQLServerConnection {
    param(
        [string]$ComputerName,
        [System.Management.Automation.PSCredential]$Credential = $null
    )
   
    Write-Host "Testing SQL Server connections on $ComputerName..."
   
    try {
        # Use Invoke-Command to run the SQL connection test remotely
        $connectionStatus = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            # Load SQL Server module if available
            if (Get-Module -ListAvailable -Name SQLPS) {
                Import-Module SQLPS -DisableNameChecking
            }
            elseif (Get-Module -ListAvailable -Name SqlServer) {
                Import-Module SqlServer
            }
            else {
                throw "SQL Server PowerShell modules not found on $using:ComputerName"
            }
           
            # Get all SQL instances on the server
            $instances = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL" |
                Select-Object -Property * -ExcludeProperty PSPath, PSParentPath, PSChildName, PSProvider |
                Get-Member -MemberType NoteProperty |
                Select-Object -ExpandProperty Name
           
            if (-not $instances) {
                $instances = @("MSSQLSERVER") # Default instance if none found
            }
           
            $connectionResults = @()
           
            foreach ($instance in $instances) {
                $instanceName = if ($instance -eq "MSSQLSERVER") { $env:COMPUTERNAME } else { "$($env:COMPUTERNAME)\$instance" }
               
                try {
                    # Attempt to connect to the instance
                    $server = New-Object Microsoft.SqlServer.Management.Smo.Server($instanceName)
                    $server.ConnectionContext.ConnectTimeout = 5 # 5 second timeout
                   
                    # Check connection by getting server version
                    $version = $server.Version
                    $edition = $server.Edition
                    $isConnected = $true
                    $errorMessage = ""
                   
                    # Get additional connection information
                    $activeConnections = $server.ConnectionContext.ExecuteWithResults("SELECT COUNT(*) AS connection_count FROM sys.dm_exec_connections").Tables[0].Rows[0]["connection_count"]
                   
                    # Check SQL Server service status
                    $serviceName = if ($instance -eq "MSSQLSERVER") { "MSSQLSERVER" } else { "MSSQL`$$instance" }
                    $service = Get-Service -Name $serviceName -ErrorAction SilentlyContinue
                    $serviceStatus = if ($service) { $service.Status } else { "Unknown" }
                }
                catch {
                    $isConnected = $false
                    $errorMessage = $_.Exception.Message
                    $version = "Unknown"
                    $edition = "Unknown"
                    $activeConnections = 0
                    $serviceStatus = "Unknown"
                }
               
                $connectionResults += [PSCustomObject]@{
                    ServerName = $env:COMPUTERNAME
                    InstanceName = $instanceName
                    IsConnected = $isConnected
                    Version = $version
                    Edition = $edition
                    ServiceStatus = $serviceStatus
                    ActiveConnections = $activeConnections
                    ErrorMessage = $errorMessage
                }
            }
           
            return $connectionResults
        } -ErrorAction Stop
       
        return $connectionStatus
    }
    catch {
        Write-Host "Failed to test SQL Server connections on ${ComputerName}: ${_}" -ForegroundColor Red
        return $null
    }
}

# Function to clean up old backup files
function Remove-OldBackups {
    param(
        [string]$ComputerName,
        [int]$RetentionDays = 30,
        [System.Management.Automation.PSCredential]$Credential = $null
    )
   
    Write-Host "Cleaning up old backup files on $ComputerName (older than $RetentionDays days)..."
   
    try {
        # Use Invoke-Command to clean up old backups remotely
        $cleanupResults = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
            # Load SQL Server module if available
            if (Get-Module -ListAvailable -Name SQLPS) {
                Import-Module SQLPS -DisableNameChecking
            }
            elseif (Get-Module -ListAvailable -Name SqlServer) {
                Import-Module SqlServer
            }
            else {
                throw "SQL Server PowerShell modules not found on $using:ComputerName"
            }
           
            # Get all SQL instances on the server
            $instances = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\Instance Names\SQL" |
                Select-Object -Property * -ExcludeProperty PSPath, PSParentPath, PSChildName, PSProvider |
                Get-Member -MemberType NoteProperty |
                Select-Object -ExpandProperty Name
           
            if (-not $instances) {
                $instances = @("MSSQLSERVER") # Default instance if none found
            }
           
            $results = @()
            $cutoffDate = (Get-Date).AddDays(-$using:RetentionDays)
           
            foreach ($instance in $instances) {
                try {
                    $instanceName = if ($instance -eq "MSSQLSERVER") { $env:COMPUTERNAME } else { "$($env:COMPUTERNAME)\$instance" }
                    $server = New-Object Microsoft.SqlServer.Management.Smo.Server($instanceName)
                   
                    # Get backup directory
                    $backupDir = $server.BackupDirectory
                   
                    if (Test-Path $backupDir) {
                        # Find backup files older than retention period
                        $oldFiles = Get-ChildItem -Path $backupDir -Recurse -File |
                            Where-Object { $_.Extension -match '\.(bak|trn)$' -and $_.LastWriteTime -lt $cutoffDate }
                       
                        $totalSize = [math]::Round(($oldFiles | Measure-Object -Property Length -Sum).Sum / 1GB, 2)
                        $fileCount = ($oldFiles | Measure-Object).Count
                       
                        # Delete old files
                        foreach ($file in $oldFiles) {
                            try {
                                Remove-Item -Path $file.FullName -Force
                                $results += [PSCustomObject]@{
                                    ServerName = $env:COMPUTERNAME
                                    InstanceName = $instanceName
                                    FilePath = $file.FullName
                                    FileSize = [math]::Round($file.Length / 1MB, 2)
                                    LastModified = $file.LastWriteTime
                                    Status = "Deleted"
                                }
                            }
                            catch {
                                $results += [PSCustomObject]@{
                                    ServerName = $env:COMPUTERNAME
                                    InstanceName = $instanceName
                                    FilePath = $file.FullName
                                    FileSize = [math]::Round($file.Length / 1MB, 2)
                                    LastModified = $file.LastWriteTime
                                    Status = "Failed: ${_}"
                                }
                            }
                        }
                       
                        $results += [PSCustomObject]@{
                            ServerName = $env:COMPUTERNAME
                            InstanceName = $instanceName
                            FilePath = "SUMMARY"
                            FileSize = $totalSize
                            LastModified = $cutoffDate
                            Status = "Total files deleted: $fileCount, Total space reclaimed: $totalSize GB"
                        }
                    }
                    else {
                        $results += [PSCustomObject]@{
                            ServerName = $env:COMPUTERNAME
                            InstanceName = $instanceName
                            FilePath = $backupDir
                            FileSize = 0
                            LastModified = Get-Date
                            Status = "Backup directory not found"
                        }
                    }
                }
                catch {
                    $results += [PSCustomObject]@{
                        ServerName = $env:COMPUTERNAME
                        InstanceName = $instanceName
                        FilePath = "ERROR"
                        FileSize = 0
                        LastModified = Get-Date
                        Status = "Error: ${_}"
                    }
                }
            }
           
            return $results
        } -ErrorAction Stop
       
        return $cleanupResults
    }
    catch {
        Write-Host "Failed to clean up old backups on ${ComputerName}: ${_}" -ForegroundColor Red
        return $null
    }
}

# Ensure log directory exists
if (-not (Test-Path $logFolderPath)) {
    try {
        New-Item -Path $logFolderPath -ItemType Directory -Force | Out-Null
        Write-Host "Created log directory at $logFolderPath" -ForegroundColor Green
    }
    catch {
        Write-Host "Failed to create log directory: ${_}" -ForegroundColor Red
        Write-Host "Will attempt to use local directory instead." -ForegroundColor Yellow
        $logFolderPath = "C:\Temp"
        if (-not (Test-Path $logFolderPath)) {
            New-Item -Path $logFolderPath -ItemType Directory -Force | Out-Null
        }
    }
}

# Check if server list file exists
if (-not (Test-Path $serverListPath)) {
    Write-Host "Server list file not found at $serverListPath" -ForegroundColor Red
    Write-Host "Error: No servers to process. Please ensure the server list file exists." -ForegroundColor Red
    exit
}
else {
    # Read server list from file
    try {
        $servers = Get-Content -Path $serverListPath -ErrorAction Stop |
            Where-Object { $_ -match '\S' } | # Filter out empty lines
            ForEach-Object { $_.Trim() } # Trim whitespace
       
        $serverCount = ($servers | Measure-Object).Count
       
        if ($serverCount -eq 0) {
            Write-Host "Error: No servers found in $serverListPath" -ForegroundColor Red
            exit
        }
        else {
            Write-Host "Found $serverCount servers in $serverListPath" -ForegroundColor Green
            Write-Host "Servers to process:"
            $servers | ForEach-Object { Write-Host " - $_" -ForegroundColor Cyan }
        }
    }
    catch {
        Write-Host "Failed to read server list: ${_}" -ForegroundColor Red
        exit
    }
}

# Process each server
foreach ($currentServer in $servers) {
    # Create log file for this server
    $timestamp = Get-Date -Format 'yyyy-MM-dd_HH-mm-ss'
    $logFilePath = "$logFolderPath\$currentServer-SQLMonitor-$timestamp.log"
   
    try {
        # Start logging
        Start-Transcript -Path $logFilePath -Append
       
        Write-Host "==============================================" -ForegroundColor Green
        Write-Host "SQL Server Monitoring for: $currentServer" -ForegroundColor Green
        Write-Host "Started at: $(Get-Date)" -ForegroundColor Green
        Write-Host "==============================================" -ForegroundColor Green
       
        # Test SQL Server connection
        Write-Host "`n## CONNECTION STATUS ##" -ForegroundColor Magenta
        $connectionStatus = Test-SQLServerConnection -ComputerName $currentServer
       
        if ($connectionStatus) {
            $connectionStatus | ForEach-Object {
                $statusColor = if ($_.IsConnected) { "Green" } else { "Red" }
                Write-Host "Instance: $($_.InstanceName)" -ForegroundColor Yellow
                Write-Host "Connected: $($_.IsConnected)" -ForegroundColor $statusColor
                Write-Host "SQL Version: $($_.Version)"
                Write-Host "SQL Edition: $($_.Edition)"
                Write-Host "Service Status: $($_.ServiceStatus)"
                Write-Host "Active Connections: $($_.ActiveConnections)"
               
                if (-not $_.IsConnected) {
                    Write-Host "Error: $($_.ErrorMessage)" -ForegroundColor Red
                }
               
                Write-Host "-" * 60
            }
        }
        else {
            Write-Host "No connection information available for $currentServer" -ForegroundColor Red
        }
       
        # Get disk space information
        Write-Host "`n## DISK SPACE ##" -ForegroundColor Magenta
        $diskSpace = Get-ServerDiskSpace -ComputerName $currentServer
       
        if ($diskSpace) {
            $diskSpace | ForEach-Object {
                $spaceColor = if ($_.PercentFree -lt 10) { "Red" } elseif ($_.PercentFree -lt 20) { "Yellow" } else { "Green" }
               
                Write-Host "Drive: $($_.DeviceID)" -ForegroundColor Yellow
                Write-Host "Total Size: $($_.'Size(GB)') GB"
                Write-Host "Free Space: $($_.'FreeSpace(GB)') GB" -ForegroundColor $spaceColor
                Write-Host "Used Space: $($_.'Used(GB)') GB"
                Write-Host "Percent Free: $($_.PercentFree)%" -ForegroundColor $spaceColor
                Write-Host "-" * 60
            }
        }
        else {
            Write-Host "No disk space information available for $currentServer" -ForegroundColor Red
        }
       
        # Check SQL job statuses
        Write-Host "`n## SQL JOB STATUS ##" -ForegroundColor Magenta
        $jobStatuses = Get-SQLServerJobStatus -ComputerName $currentServer
       
        if ($jobStatuses) {
            # Display Failed Jobs with explanations
            Write-Host "`n# FAILED JOBS #" -ForegroundColor Red
            $failedJobs = $jobStatuses | Where-Object { $_.LastRunOutcome -eq "Failed" }
           
            if ($failedJobs.Count -gt 0) {
                foreach ($job in $failedJobs) {
                    Write-Host "Job: $($job.JobName)" -ForegroundColor Yellow
                    Write-Host "Instance: $($job.InstanceName)"
                    Write-Host "Last Run: $($job.LastRunDate)"
                    Write-Host "Duration: $($job.LastRunDuration)"
                   
                    # Display detailed failure information
                    if (-not [string]::IsNullOrEmpty($job.FailureDetails)) {
                        Write-Host "Failure Details: $($job.FailureDetails)" -ForegroundColor Red
                    }
                    else {
                        Write-Host "No detailed failure information available" -ForegroundColor Yellow
                    }
                   
                    Write-Host "-" * 60
                }
            }
            else {
                Write-Host "No failed jobs found" -ForegroundColor Green
            }
           
            # Display Successful Jobs
            Write-Host "`n# SUCCESSFUL JOBS #" -ForegroundColor Green
            $successJobs = $jobStatuses | Where-Object { $_.LastRunOutcome -eq "Success" }
           
            if ($successJobs.Count -gt 0) {
                Write-Host "Found $($successJobs.Count) successfully completed jobs"
               
                # Group by category
                $jobsByCategory = $successJobs | Group-Object -Property Category
               
                foreach ($category in $jobsByCategory) {
                    Write-Host "`nCategory: $($category.Name)" -ForegroundColor Yellow
                    Write-Host "Jobs: $($category.Count)"
                   
                    foreach ($job in $category.Group) {
                        Write-Host "- $($job.JobName) (Last Run: $($job.LastRunDate), Duration: $($job.LastRunDuration))"
                    }
                }
            }
            else {
                Write-Host "No successful jobs found" -ForegroundColor Yellow
            }
           
            # Job Status Summary
            Write-Host "`n# JOB STATUS SUMMARY #" -ForegroundColor Cyan
            $failedCount = ($jobStatuses | Where-Object { $_.LastRunOutcome -eq "Failed" }).Count
            $successCount = ($jobStatuses | Where-Object { $_.LastRunOutcome -eq "Success" }).Count
            $canceledCount = ($jobStatuses | Where-Object { $_.LastRunOutcome -eq "Canceled" }).Count
            $unknownCount = ($jobStatuses | Where-Object { $_.LastRunOutcome -eq "Unknown" }).Count
            $disabledCount = ($jobStatuses | Where-Object { -not $_.Enabled }).Count
           
            Write-Host "Total Jobs: $($jobStatuses.Count)"
            Write-Host "Failed Jobs: $failedCount" -ForegroundColor $(if($failedCount -gt 0){"Red"}else{"Green"})
            Write-Host "Successful Jobs: $successCount" -ForegroundColor Green
            Write-Host "Canceled Jobs: $canceledCount" -ForegroundColor Yellow
            Write-Host "Unknown Status: $unknownCount" -ForegroundColor Gray
            Write-Host "Disabled Jobs: $disabledCount" -ForegroundColor Yellow
        }
        else {
            Write-Host "No SQL job information available for $currentServer" -ForegroundColor Red
        }
       
        # Check backup information
        Write-Host "`n## BACKUP STATUS ##" -ForegroundColor Magenta
        $backupInfo = Get-SQLServerBackupInfo -ComputerName $currentServer
       
        if ($backupInfo) {
            # Display backup location information
            Write-Host "`n# BACKUP LOCATIONS #" -ForegroundColor Cyan
            $backupLocations = $backupInfo | Where-Object { $_.BackupType -eq "INFO" }
           
            foreach ($loc in $backupLocations) {
                Write-Host "Instance: $($loc.InstanceName)" -ForegroundColor Yellow
                Write-Host "Backup Location: $($loc.PhysicalDeviceName)"
                Write-Host "-" * 60
            }
           
            # Display most recent backups by database
            Write-Host "`n# RECENT BACKUPS #" -ForegroundColor Cyan
            $recentBackups = $backupInfo | Where-Object { $_.BackupType -ne "INFO" -and $_.BackupType -ne "MISSING" } |
                Sort-Object -Property DatabaseName, BackupStartDate -Descending |
                Group-Object -Property DatabaseName |
                ForEach-Object { $_.Group | Select-Object -First 1 }
           
            foreach ($backup in $recentBackups) {
                Write-Host "Database: $($backup.DatabaseName)" -ForegroundColor Yellow
                Write-Host "Last Backup: $($backup.BackupStartDate)"
                Write-Host "Type: $($backup.BackupType)"
                Write-Host "Size: $($backup.BackupSize) MB"
                Write-Host "Location: $($backup.PhysicalDeviceName)"
                Write-Host "-" * 60
            }
           
            # Display databases without recent backups
            Write-Host "`n# MISSING BACKUPS #" -ForegroundColor Red
            $missingBackups = $backupInfo | Where-Object { $_.BackupType -eq "MISSING" }
           
            if ($missingBackups.Count -gt 0) {
                foreach ($miss in $missingBackups) {
                    Write-Host "Database: $($miss.DatabaseName)" -ForegroundColor Yellow
                    Write-Host "Last Backup: $($miss.BackupStartDate)"
                    Write-Host "Days Since Last Backup: $($miss.DaysSinceLastBackup)" -ForegroundColor Red
                    Write-Host "-" * 60
                }
            }
            else {
                Write-Host "All databases have recent backups" -ForegroundColor Green
            }
        }
        else {
            Write-Host "No backup information available for $currentServer" -ForegroundColor Red
        }
       
        # Clean up old backups
        Write-Host "`n## BACKUP CLEANUP ##" -ForegroundColor Magenta
        $cleanupResults = Remove-OldBackups -ComputerName $currentServer -RetentionDays $backupRetentionDays
       
        if ($cleanupResults) {
            # Get summary information
            $summary = $cleanupResults | Where-Object { $_.FilePath -eq "SUMMARY" }
           
            foreach ($sum in $summary) {
                Write-Host "Instance: $($sum.InstanceName)" -ForegroundColor Yellow
                Write-Host "$($sum.Status)" -ForegroundColor Green
                Write-Host "-" * 60
            }
           
            # Display any errors
            $errors = $cleanupResults | Where-Object { $_.Status -like "Failed*" -or $_.Status -like "Error*" }
           
            if ($errors.Count -gt 0) {
                Write-Host "`n# CLEANUP ERRORS #" -ForegroundColor Red
                foreach ($err in $errors) {
                    Write-Host "Instance: $($err.InstanceName)" -ForegroundColor Yellow
                    Write-Host "File: $($err.FilePath)"
                    Write-Host "Error: $($err.Status)" -ForegroundColor Red
                    Write-Host "-" * 60
                }
            }
        }
        else {
            Write-Host "No backup cleanup information available for $currentServer" -ForegroundColor Red
        }
       
        Write-Host "`n==============================================" -ForegroundColor Green
        Write-Host "SQL Server Monitoring completed for: $currentServer" -ForegroundColor Green
        Write-Host "Completed at: $(Get-Date)" -ForegroundColor Green
        Write-Host "==============================================" -ForegroundColor Green
    }
    catch {
        Write-Host "Error processing server $currentServer : ${_}" -ForegroundColor Red
    }
    finally {
        # Stop logging
        Stop-Transcript
    }
}

Write-Host "SQL Server monitoring completed" -ForegroundColor Green
