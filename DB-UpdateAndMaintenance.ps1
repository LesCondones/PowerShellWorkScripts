# Author: Lester Artis Jr.
# Created: 04/09/2025
# Modified: 04/16/2025 - Performance improvements

# Load Windows Forms and Drawing assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Configuration paths
$configPath = "C:\Powershell_scripts\check_yum"
$serverListFile = "$configPath\servers.txt"
$usernameListFile = "$configPath\username.txt"

# Read configuration
$servers = Get-Content $serverListFile
$username = Get-Content $usernameListFile

# Create a cache for server configurations
$global:serverConfigs = @{}

# Create form with improved styling
$form = New-Object System.Windows.Forms.Form
$form.Text = 'PostgreSQL/EDB Server Maintenance Utility'
$form.Size = New-Object System.Drawing.Size(850, 600)
$form.MinimumSize = New-Object System.Drawing.Size(600, 450)
$form.StartPosition = 'CenterScreen'
$form.BackColor = [System.Drawing.Color]::FromArgb(240, 240, 240)
$form.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$form.Icon = [System.Drawing.SystemIcons]::Application

# Create header panel
$headerPanel = New-Object System.Windows.Forms.Panel
$headerPanel.Dock = [System.Windows.Forms.DockStyle]::Top
$headerPanel.Height = 60
$headerPanel.BackColor = [System.Drawing.Color]::FromArgb(41, 128, 185)
$form.Controls.Add($headerPanel)

# Add title to header
$titleLabel = New-Object System.Windows.Forms.Label
$titleLabel.Text = "Database Server Maintenance"
$titleLabel.ForeColor = [System.Drawing.Color]::White
$titleLabel.Font = New-Object System.Drawing.Font("Segoe UI", 16, [System.Drawing.FontStyle]::Bold)
$titleLabel.AutoSize = $true
$titleLabel.Location = New-Object System.Drawing.Point(15, ($headerPanel.Height - $titleLabel.PreferredHeight) / 2)
$headerPanel.Controls.Add($titleLabel)

#Create a scroll panel to contain main content
$scrollPanel = New-Object System.Windows.Forms.Panel
$scrollPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$scrollPanel.AutoScroll = $true

# Create main container
$mainContainer = New-Object System.Windows.Forms.TableLayoutPanel
$mainContainer.Dock = [System.Windows.Forms.DockStyle]::Fill
$mainContainer.RowCount = 2
$mainContainer.ColumnCount = 2
$mainContainer.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)))
$mainContainer.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 60)))
$mainContainer.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 30)))
$mainContainer.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 70)))
$mainContainer.Padding = New-Object System.Windows.Forms.Padding(10)
$mainContainer.Controls.Add($scrollPanel, 0, 1)
$form.Controls.Add($mainContainer)
$mainContainer.BringToFront()

# Create server list & controls panel (left side - Cell 0,0)
$leftPanel = New-Object System.Windows.Forms.Panel
$leftPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$leftPanel.Padding = New-Object System.Windows.Forms.Padding(0, 0, 10, 0)
$mainContainer.Controls.Add($leftPanel, 0, 0)

# Server list group
$serverGroup = New-Object System.Windows.Forms.GroupBox
$serverGroup.Text = "Servers"
$serverGroup.Dock = [System.Windows.Forms.DockStyle]::Top
$serverGroup.Height = 200
$serverGroup.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$leftPanel.Controls.Add($serverGroup)

# Server list box
$serverListBox = New-Object System.Windows.Forms.CheckedListBox
$serverListBox.Dock = [System.Windows.Forms.DockStyle]::Fill
$serverListBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$serverListBox.CheckOnClick = $true
$serverListBox.Padding = New-Object System.Windows.Forms.Padding(5)
$serverListBox.IntegralHeight = $false
if ($null -ne $servers) {
    foreach ($server in $servers) {
        [void]$serverListBox.Items.Add($server, $true)
    }
} else {
    [void]$serverListBox.Items.Add("No servers defined", $false)
    $serverListBox.Enabled = $false
}
$serverGroup.Controls.Add($serverListBox)

# Options group
$optionsGroup = New-Object System.Windows.Forms.GroupBox
$optionsGroup.Text = "Options"
$optionsGroup.Dock = [System.Windows.Forms.DockStyle]::Fill
$optionsGroup.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$leftPanel.Controls.Add($optionsGroup)
$optionsGroup.BringToFront()

# Options container
$optionsContainer = New-Object System.Windows.Forms.FlowLayoutPanel
$optionsContainer.Dock = [System.Windows.Forms.DockStyle]::Fill
$optionsContainer.Padding = New-Object System.Windows.Forms.Padding(10)
$optionsContainer.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
$optionsContainer.WrapContents = $false
$optionsContainer.AutoScroll = $true
$optionsGroup.Controls.Add($optionsContainer)

# Checkboxes for options
$checkboxMargin = New-Object System.Windows.Forms.Padding(3, 0, 3, 5)

$chkRepoCheck = New-Object System.Windows.Forms.CheckBox
$chkRepoCheck.Text = "Check repositories"
$chkRepoCheck.AutoSize = $true
$chkRepoCheck.Checked = $true
$chkRepoCheck.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$chkRepoCheck.Margin = $checkboxMargin
$optionsContainer.Controls.Add($chkRepoCheck)

$chkDbStop = New-Object System.Windows.Forms.CheckBox
$chkDbStop.Text = "Stop database"
$chkDbStop.AutoSize = $true
$chkDbStop.Checked = $true
$chkDbStop.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$chkDbStop.Margin = $checkboxMargin
$optionsContainer.Controls.Add($chkDbStop)

$chkUpdateCheck = New-Object System.Windows.Forms.CheckBox
$chkUpdateCheck.Text = "Check for updates"
$chkUpdateCheck.AutoSize = $true
$chkUpdateCheck.Checked = $true
$chkUpdateCheck.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$chkUpdateCheck.Margin = $checkboxMargin
$optionsContainer.Controls.Add($chkUpdateCheck)

$chkUpdateApply = New-Object System.Windows.Forms.CheckBox
$chkUpdateApply.Text = "Apply updates"
$chkUpdateApply.AutoSize = $true
$chkUpdateApply.Checked = $true
$chkUpdateApply.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$chkUpdateApply.Margin = $checkboxMargin
$optionsContainer.Controls.Add($chkUpdateApply)

$chkReboot = New-Object System.Windows.Forms.CheckBox
$chkReboot.Text = "Reboot servers"
$chkReboot.AutoSize = $true
$chkReboot.Checked = $true
$chkReboot.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$chkReboot.Margin = $checkboxMargin
$optionsContainer.Controls.Add($chkReboot)

# Advanced options - NEW
$chkParallel = New-Object System.Windows.Forms.CheckBox
$chkParallel.Text = "Process servers in parallel"
$chkParallel.AutoSize = $true
$chkParallel.Checked = $true  # Enable by default
$chkParallel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$chkParallel.Margin = $checkboxMargin
$optionsContainer.Controls.Add($chkParallel)

# Max parallel servers - NEW
$parallelContainer = New-Object System.Windows.Forms.Panel
$parallelContainer.Height = 28
$parallelContainer.Width = 200
$parallelContainer.Margin = $checkboxMargin
$optionsContainer.Controls.Add($parallelContainer)

$parallelLabel = New-Object System.Windows.Forms.Label
$parallelLabel.Text = "Max parallel servers:"
$parallelLabel.AutoSize = $true
$parallelLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$parallelLabel.Location = New-Object System.Drawing.Point(0, 4)
$parallelContainer.Controls.Add($parallelLabel)

$numParallelServers = New-Object System.Windows.Forms.NumericUpDown
$numParallelServers.Minimum = 1
$numParallelServers.Maximum = 10
$numParallelServers.Value = 3  # Default to 3 parallel servers
$numParallelServers.Width = 50
$numParallelServers.Location = New-Object System.Drawing.Point($parallelLabel.Width + 5, 2)
$parallelContainer.Controls.Add($numParallelServers)

# Output log panel (right side - top - Cell 1,0)
$logPanel = New-Object System.Windows.Forms.Panel
$logPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$mainContainer.Controls.Add($logPanel, 1, 0)

# Output group
$outputGroup = New-Object System.Windows.Forms.GroupBox
$outputGroup.Text = "Activity Log"
$outputGroup.Dock = [System.Windows.Forms.DockStyle]::Fill
$outputGroup.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$outputGroup.Padding = New-Object System.Windows.Forms.Padding(5, 3, 5, 5)
$logPanel.Controls.Add($outputGroup)

# Output textbox with rich text
$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Dock = [System.Windows.Forms.DockStyle]::Fill
$outputBox.Multiline = $true
$outputBox.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical
$outputBox.ReadOnly = $true
$outputBox.BackColor = [System.Drawing.Color]::White
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$outputBox.HideSelection = $false
$outputGroup.Controls.Add($outputBox)

# Create controls panel (right side - bottom - Cell 1,1)
$controlsPanel = New-Object System.Windows.Forms.Panel
$controlsPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$controlsPanel.Padding = New-Object System.Windows.Forms.Padding(0, 5, 0, 0)
$mainContainer.Controls.Add($controlsPanel, 1, 1)

# Progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Dock = [System.Windows.Forms.DockStyle]::Top
$progressBar.Height = 20
$progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
$controlsPanel.Controls.Add($progressBar)

# Button container
$buttonContainer = New-Object System.Windows.Forms.FlowLayoutPanel
$buttonContainer.Dock = [System.Windows.Forms.DockStyle]::Fill
$buttonContainer.FlowDirection = [System.Windows.Forms.FlowDirection]::RightToLeft
$buttonContainer.WrapContents = $false
$buttonContainer.Padding = New-Object System.Windows.Forms.Padding(0, 5, 0, 0)
$controlsPanel.Controls.Add($buttonContainer)
$buttonContainer.BringToFront()

# Buttons with improved styling
$buttonMargin = New-Object System.Windows.Forms.Padding(5, 0, 0, 0)

$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = 'Run Maintenance'
$runButton.Size = New-Object System.Drawing.Size(150, 30)
$runButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$runButton.BackColor = [System.Drawing.Color]::FromArgb(41, 128, 185)
$runButton.ForeColor = [System.Drawing.Color]::White
$runButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$runButton.Margin = $buttonMargin
$buttonContainer.Controls.Add($runButton)

$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Text = 'Clear Log'
$clearButton.Size = New-Object System.Drawing.Size(100, 30)
$clearButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$clearButton.BackColor = [System.Drawing.Color]::FromArgb(149, 165, 166)
$clearButton.ForeColor = [System.Drawing.Color]::White
$clearButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$clearButton.Margin = $buttonMargin
$buttonContainer.Controls.Add($clearButton)

$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Text = 'Save Log'
$saveButton.Size = New-Object System.Drawing.Size(100, 30)
$saveButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$saveButton.BackColor = [System.Drawing.Color]::FromArgb(149, 165, 166)
$saveButton.ForeColor = [System.Drawing.Color]::White
$saveButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$saveButton.Margin = $buttonMargin
$buttonContainer.Controls.Add($saveButton)

# Status bar
$statusStrip = New-Object System.Windows.Forms.StatusStrip
$statusStrip.BackColor = [System.Drawing.Color]::FromArgb(236, 240, 241)
$statusStrip.Dock = [System.Windows.Forms.DockStyle]::Bottom
$form.Controls.Add($statusStrip)

$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Ready"
$statusStrip.Items.Add($statusLabel)

# Create a synchronized hashtable to track server status
$global:serverStatus = [hashtable]::Synchronized(@{})
$global:logBuffer = [System.Collections.ArrayList]::Synchronized((New-Object System.Collections.ArrayList))
$global:lastUIUpdate = [DateTime]::Now

# Function to run SSH commands with specific user - IMPROVED
function Run-SSHCommand {
    param (
        [string]$server,
        [string]$command,
        [string]$execUser = "root",
        [string]$connectAs = $username,
        [int]$timeout = 60,
        [switch]$noOutput
    )
   
    try {
        $sshCommand = ""
        if ($execUser -eq "root") {
            # For root commands, use dzdo directly
            $sshCommand = "ssh -o GSSAPIAuthentication=yes -o ConnectTimeout=10 ${connectAs}@${server} `"dzdo su - -c '$command'`""
        } else{
            $sshCommand = "ssh -o GSSAPIAuthentication=yes -o ConnectTimeout=10 ${connectAs}@${server} `"dzdo su -  $execUser -c '$command'`""
        }
       
        # Add timeout handling for commands
        $job = Start-Job -ScriptBlock {
            param($cmd)
            Invoke-Expression $cmd
        } -ArgumentList $sshCommand
       
        # Wait for the command to complete or timeout
        if (Wait-Job $job -Timeout $timeout) {
            $result = Receive-Job $job
            Remove-Job $job -Force
            return $result
        } else {
            Stop-Job $job
            Remove-Job $job -Force
            return "ERROR: Command execution timed out after $timeout seconds"
        }
    }
    catch {
        return "ERROR: $_"
    }
}

# Function to update output with color coding - IMPROVED
function Update-Output {
    param (
        [string]$message,
        [string]$type = "INFO", # INFO, SUCCESS, WARNING, ERROR
        [string]$server = "",
        [switch]$force
    )
   
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $fullMessage = if ($server) { "[$timestamp] [$server] $message" } else { "[$timestamp] $message" }
   
    # Add to buffer
    [void]$global:logBuffer.Add(@{
        Message = $fullMessage
        Type = $type
    })
    
    # Only update UI every 500ms or if forced
    $now = [DateTime]::Now
    if ($force -or ($now - $global:lastUIUpdate).TotalMilliseconds -gt 500) {
        $form.Invoke([Action]{
            foreach ($entry in $global:logBuffer) {
                # Set color based on message type
                switch ($entry.Type) {
                    "SUCCESS" { $color = [System.Drawing.Color]::FromArgb(39, 174, 96) }
                    "WARNING" { $color = [System.Drawing.Color]::FromArgb(211, 84, 0) }
                    "ERROR"   { $color = [System.Drawing.Color]::FromArgb(192, 57, 43) }
                    default   { $color = [System.Drawing.Color]::FromArgb(44, 62, 80) }
                }
               
                # Add colored text
                $outputBox.SelectionStart = $outputBox.TextLength
                $outputBox.SelectionLength = 0
                $outputBox.SelectionColor = $color
                $outputBox.AppendText("$($entry.Message)`n")
            }
            
            # Scroll to end and update status
            $outputBox.ScrollToCaret()
            if ($global:logBuffer.Count -gt 0) {
                $statusLabel.Text = $global:logBuffer[$global:logBuffer.Count - 1].Message
            }
            
            # Clear buffer
            $global:logBuffer.Clear()
            $global:lastUIUpdate = $now
        })
    }
}

# Function to detect server configuration - IMPROVED with caching
function Detect-ServerConfig {
    param (
        [string]$server
    )
    
    # Check cache first
    if ($global:serverConfigs.ContainsKey($server)) {
        Update-Output "[$server] Using cached server configuration" -server $server
        return $global:serverConfigs[$server]
    }
   
    Update-Output "Detecting server configuration..." -server $server
   
    # First check which database user exists: enterprisedb or postgres
    $entDbCheck = Run-SSHCommand -server $server -command "id -u enterprisedb 2>/dev/null || echo 'Not found'" -execUser "enterprisedb"
    $pgCheck = Run-SSHCommand -server $server -command "id -u postgres 2>/dev/null || echo 'Not found'" -execUser "postgres"
   
    $pgUser = ""
    if ($entDbCheck -ne "Not found" -and $entDbCheck -notmatch "ERROR") {
        $pgUser = "enterprisedb"
        Update-Output "Detected enterprisedb user" -server $server
    } elseif ($pgCheck -ne "Not found" -and $pgCheck -notmatch "ERROR") {
        $pgUser = "postgres"
        Update-Output "Detected postgres user" -server $server
    } else {
        Update-Output "ERROR: Could not detect database user (neither enterprisedb nor postgres found)" -server $server -type "ERROR"
        return $null
    }
   
    # Paths to check for EDB installs
    $edbPaths = @(
        "/edbas/entdb/edb-5444"
    )
   
    # Paths to check for PostgreSQL installs
    $pgPaths = @(
        "/pgsql/pgdbs/pg-5444"
    )
   
    # Select paths to check based on detected user
    $pathsToCheck = if ($pgUser -eq "enterprisedb") { $edbPaths } else { $pgPaths }
    $pgDataPath = ""
   
    # Check each potential path
    foreach ($path in $pathsToCheck) {
        $pathCheck = Run-SSHCommand -server $server -command "test -d $path && echo 'Found' || echo 'Not found'" -execUser $pgUser
        if ($pathCheck -eq "Found") {
            $pgDataPath = $path
            Update-Output "Found database path: $pgDataPath" -server $server -type "SUCCESS"
            break
        }
    }
   
    # If no path was found, try to check environment variable
    if ([string]::IsNullOrEmpty($pgDataPath)) {
        $envCheck = Run-SSHCommand -server $server -command "echo \$PGDATA" -execUser $pgUser
        if (-not [string]::IsNullOrEmpty($envCheck) -and $envCheck -ne '$PGDATA' -and $envCheck -notmatch "ERROR") {
            $pgDataPath = $envCheck.Trim()
            Update-Output "Found database path from PGDATA environment variable: $pgDataPath" -server $server -type "SUCCESS"
        }
    }
   
    # If still no path, check postmaster.pid locations
    if ([string]::IsNullOrEmpty($pgDataPath)) {
        $pidCheck = Run-SSHCommand -server $server -command "find / -name postmaster.pid -path '*/data/*' 2>/dev/null | head -1" -execUser "root"
        if (-not [string]::IsNullOrEmpty($pidCheck) -and $pidCheck -notmatch "ERROR") {
            $pgDataPath = $pidCheck.Trim() -replace "/postmaster.pid", ""
            Update-Output "Found database path from postmaster.pid: $pgDataPath" -server $server -type "SUCCESS"
        }
    }
   
    # Check if barman is available
    $barmanCheck = Run-SSHCommand -server $server -command "id -u barman 2>/dev/null || echo 'Not found'" -execUser "barman"
    $hasBarman = ($barmanCheck -ne "Not found" -and $barmanCheck -notmatch "ERROR")
   
    # Determine barman database name
    $barmanName = ""
    $barmanUser = ""
    if ($hasBarman) {
        $barmanUser = "barman"
       
        # Check what barman servers are configured
        $barmanServers = Run-SSHCommand -server $server -command "barman list-server 2>/dev/null || echo 'Not configured'" -execUser $barmanUser
       
        if ($barmanServers -notmatch "Not configured" -and $barmanServers -notmatch "ERROR") {
            # Use first available barman server
            $barmanName = ($barmanServers -split '\n')[0].Trim()
            Update-Output "Found barman configuration for: $barmanName" -server $server -type "SUCCESS"
        } else {
            # Guess based on user type
            if ($pgUser -eq "enterprisedb") {
                $barmanName = "edb-5444"
            } else {
                $barmanName = "pg-5444"
            }
           
            # Check if this guess is valid
            $barmanConfigCheck = Run-SSHCommand -server $server -command "barman show-server $barmanName 2>/dev/null || echo 'Not configured'" -execUser $barmanUser
            if ($barmanConfigCheck -match "Not configured" -or $barmanConfigCheck -match "ERROR") {
                $hasBarman = $false
                Update-Output "Barman is installed but $barmanName is not configured" -server $server -type "WARNING"
            } else {
                Update-Output "Found barman configuration for: $barmanName" -server $server -type "SUCCESS"
            }
        }
    }
   
    # Return the configuration
    if ([string]::IsNullOrEmpty($pgDataPath)) {
        Update-Output "WARNING: Could not detect database data path" -server $server -type "WARNING"
        return $null
    }
   
    Update-Output "Configuration detected successfully" -server $server -type "SUCCESS"
   
    $config = @{
        PgUser = $pgUser
        PgDataPath = $pgDataPath
        HasBarman = $hasBarman
        BarmanUser = $barmanUser
        BarmanName = $barmanName
    }
    
    # Cache the configuration
    $global:serverConfigs[$server] = $config
    
    return $config
}

# Function to check if PostgreSQL is running - IMPROVED
function Check-PostgreSQL {
    param (
        [string]$server,
        [string]$pgUser,
        [string]$pgDataPath,
        [string]$pgPort = "5444"
    )
   
    # Check if process is running
    $processPattern = if ($pgUser -eq "enterprisedb") { "enterpr+" } else { "postgres" }
    $processCheck = Run-SSHCommand -server $server -command "ps -ef | grep -E $processPattern | grep -v grep" -execUser $pgUser
    $processRunning = ($processCheck -match "postgres")
   
    # Check socket connectivity using pg_isready (faster than psql)
    $readyCheck = Run-SSHCommand -server $server -command "pg_isready -p $pgPort 2>&1 || echo 'Not ready'" -execUser $pgUser
    $isReady = ($readyCheck -match "accepting connections")
   
    # Only test with psql if the process is running but not ready
    $socketConnected = $isReady
    $socketError = $false
    
    if ($processRunning -and -not $isReady) {
        $socketCheck = Run-SSHCommand -server $server -command "psql -p $pgPort -c 'SELECT 1' 2>&1 || echo 'Connection failed'" -execUser $pgUser
        $socketConnected = !($socketCheck -match "Connection failed" -or $socketCheck -match "failed" -or $socketCheck -match "ERROR")
        $socketError = ($socketCheck -match "socket.*failed: No such file or directory")
    }
   
    # Return combined status
    return @{
        ProcessRunning = $processRunning
        SocketConnected = $socketConnected
        SocketError = $socketError
        IsHealthy = ($processRunning -and $socketConnected)
    }
}

# Function to check and fix Barman status - IMPROVED
function Check-FixBarman {
    param (
        [string]$server,
        [string]$barmanUser,
        [string]$barmanName = "edb-5444"
    )
   
    Update-Output "Checking barman status..." -server $server
    $result = Run-SSHCommand -server $server -command "barman check $barmanName" -execUser $barmanUser
   
    $needsRecheck = $false
    
    # Check for replication slot missing error and fix
    if ($result -match "replication slot .* doesn't exist") {
        Update-Output "Replication slot missing. Creating slot..." -server $server -type "WARNING"
        $createSlotResult = Run-SSHCommand -server $server -command "barman receive-wal --create-slot $barmanName" -execUser $barmanUser -timeout 30
        Update-Output "Create slot result: $createSlotResult" -server $server
        $needsRecheck = $true
    }
   
    # Check for receive-wal not running error and fix
    if ($result -match "receive-wal running: FAILED") {
        Update-Output "WAL receiver not running. Starting WAL receiver..." -server $server -type "WARNING"
        # Use nohup to run in background
        $receiveWalResult = Run-SSHCommand -server $server -command "nohup barman receive-wal $barmanName > /dev/null 2>&1 &" -execUser $barmanUser
        Update-Output "Start WAL receiver result: $receiveWalResult" -server $server
        $needsRecheck = $true
    }
   
    # Final verification
    if ($needsRecheck) {
        Start-Sleep -Seconds 3  # Reduced wait time
        
        Update-Output "Performing final barman check..." -server $server
        $finalCheck = Run-SSHCommand -server $server -command "barman check $barmanName" -execUser $barmanUser
        
        # Log only the failed checks for efficiency
        $failedChecks = $finalCheck -split '\n' | Where-Object { $_ -match 'FAILED' }
        if ($failedChecks) {
            Update-Output "Barman status - failed checks:" -server $server
            foreach ($check in $failedChecks) {
                Update-Output $check -server $server
            }
        }
        
        if ($finalCheck -match "FAILED") {
            Update-Output "WARNING: Some barman checks still failing after fixes." -server $server -type "WARNING"
            return $false
        } else {
            Update-Output "All barman checks passed successfully." -server $server -type "SUCCESS"
            return $true
        }
    } else {
        # If no fixes needed, just return success
        Update-Output "All barman checks passed successfully." -server $server -type "SUCCESS"
        return $true
    }
}

# Function to run maintenance on a single server - NEW (for parallel processing)
function Invoke-ServerMaintenance {
    param (
        [string]$server,
        [hashtable]$options,
        [int]$serverIndex,
        [int]$totalServers
    )
    
    $global:serverStatus[$server] = @{
        Status = "Running"
        Progress = 0
        CurrentStep = "Initializing"
    }
    
    try {
        # Detect server configuration
        Update-Output "Starting maintenance..." -server $server
        $config = Detect-ServerConfig -server $server
        
        if ($config -eq $null) {
            Update-Output "ERROR: Failed to detect server configuration, skipping server" -server $server -type "ERROR"
            $global:serverStatus[$server] = @{
                Status = "Failed"
                Progress = 100
                CurrentStep = "Configuration detection failed"
            }
            return
        }
        
        $pgUser = $config.PgUser
        $pgDataPath = $config.PgDataPath
        $pgPort = "5444"  # Assuming standard port for all servers
        
        $totalSteps = 0
        if ($options.RepoCheck) { $totalSteps++ }
        if ($options.DbStop) { $totalSteps++ }
        if ($options.UpdateCheck) { $totalSteps++ }
        if ($options.UpdateApply) { $totalSteps++ }
        if ($options.Reboot) { $totalSteps++ }
        $totalSteps += 2  # For DB restart and barman check
        
        $currentStep = 0
        
        # Step 1: Check Repositories
        if ($options.RepoCheck) {
            $global:serverStatus[$server].CurrentStep = "Checking repositories"
            Update-Output "Checking enabled repositories as root..." -server $server
            $result = Run-SSHCommand -server $server -command "yum repolist enabled" -execUser "root" -timeout 30
            if ($result -match "ERROR") {
                Update-Output "Failed to check repositories: $result" -server $server -type "ERROR"
            }
            else {
                Update-Output "Repository check complete." -server $server -type "SUCCESS"
            }
            $currentStep++
            $global:serverStatus[$server].Progress = [int](($currentStep / $totalSteps) * 100)
        }
        
        # Step 2: Shutdown Database
        if ($options.DbStop) {
            $global:serverStatus[$server].CurrentStep = "Stopping database"
            Update-Output "Shutting down PostgreSQL database as $pgUser..." -server $server
            $result = Run-SSHCommand -server $server -command "pg_ctl -D $pgDataPath stop -m fast" -execUser $pgUser -timeout 60
            if ($result -match "ERROR" -or $result -match "failed") {
                Update-Output "Failed to stop database: $result" -server $server -type "ERROR"
            }
            else {
                Update-Output "PostgreSQL database stopped successfully." -server $server -type "SUCCESS"
            }
            $currentStep++
            $global:serverStatus[$server].Progress = [int](($currentStep / $totalSteps) * 100)
        }
        
        # Step 3: Check Updates
        if ($options.UpdateCheck) {
            $global:serverStatus[$server].CurrentStep = "Checking for updates"
            Update-Output "Checking for updates as root..." -server $server
            $result = Run-SSHCommand -server $server -command "yum check-update" -execUser "root" -timeout 180  # Increased timeout
            if ($result -match "ERROR") {
                Update-Output "Failed to check updates: $result" -server $server -type "ERROR"
            }
            else {
                Update-Output "Update check complete." -server $server -type "SUCCESS"
            }
            $currentStep++
            $global:serverStatus[$server].Progress = [int](($currentStep / $totalSteps) * 100)
        }
        
        # Step 4: Apply Updates - SIGNIFICANTLY IMPROVED TIMEOUT
        if ($options.UpdateApply) {
            $global:serverStatus[$server].CurrentStep = "Applying updates"
            Update-Output "Applying updates as root (this may take several minutes)..." -server $server
            
            # Use a much higher timeout for updates - 20 minutes
            $result = Run-SSHCommand -server $server -command "yum -y update" -execUser "root" -timeout 1200
            
            if ($result -match "ERROR") {
                Update-Output "Failed to apply updates: $result" -server $server -type "ERROR"
            }
            else {
                Update-Output "Updates applied successfully." -server $server -type "SUCCESS"
            }
            $currentStep++
            $global:serverStatus[$server].Progress = [int](($currentStep / $totalSteps) * 100)
        }
        
        # Step 5: Reboot server
        if ($options.Reboot) {
            $global:serverStatus[$server].CurrentStep = "Rebooting server"
            Update-Output "Rebooting server..." -server $server
            # Just send the reboot command and don't wait for response
            $result = Run-SSHCommand -server $server -command "init 6" -execUser "root" -timeout 10
            Update-Output "Reboot command sent. Waiting for server to come back online..." -server $server

            # Wait for server to reboot - IMPROVED
            $timeout = 180 # 3 minutes timeout
            $checkInterval = 10 # Check every 10 seconds
            $timer = [Diagnostics.Stopwatch]::StartNew()
            $isOnline = $false

            while (-not $isOnline -and $timer.Elapsed.TotalSeconds -lt $timeout) {
                Start-Sleep -Seconds $checkInterval
                try {
                    # Try ping first (faster)
                    $pingResult = Test-Connection -ComputerName $server -Count 1 -Quiet
                    if ($pingResult) {
                        # Try SSH connection to verify it's fully up
                        $sshTest = Run-SSHCommand -server $server -command "echo 'online'" -execUser "root" -timeout 5
                        if ($sshTest -eq "online") {
                            $isOnline = $true
                            break
                        }
                    }
                }
                catch {
                    # Continue waiting
                }
                
                $elapsed = [int]$timer.Elapsed.TotalSeconds
                $global:serverStatus[$server].CurrentStep = "Waiting for reboot ($elapsed sec)"
                Update-Output "Waiting for server to come back online... ($elapsed seconds)" -server $server
            }

            if (-not $isOnline) {
                Update-Output "WARNING: Server did not come back online within timeout period" -server $server -type "WARNING"
            }
            else {
                Update-Output "Server is back online" -server $server -type "SUCCESS"
                # Allow extra time for all services to start
                Start-Sleep -Seconds 20
            }
            $currentStep++
            $global:serverStatus[$server].Progress = [int](($currentStep / $totalSteps) * 100)
        }
        
        # Step 6: Check and start PostgreSQL if needed
        $global:serverStatus[$server].CurrentStep = "Checking database status"
        Update-Output "Checking if PostgreSQL or Enterprisedb is running..." -server $server
        $pgStatus = Check-PostgreSQL -server $server -pgUser $pgUser -pgDataPath $pgDataPath -pgPort $pgPort

        if (-not $pgStatus.IsHealthy) {
            Update-Output "$pgUser database not running or not responding. Starting using detected data path: $pgDataPath" -server $server
   
            # If we have a socket error but the process is running, stop it first
            if ($pgStatus.ProcessRunning -and $pgStatus.SocketError) {
                Update-Output "Socket error detected. Stopping database before restart..." -server $server
                $stopResult = Run-SSHCommand -server $server -command "pg_ctl -D $pgDataPath stop -m fast" -execUser $pgUser -timeout 60
                Update-Output "Stop result: $stopResult" -server $server
                Start-Sleep -Seconds 5
            }
   
            # Start database using nohup to ensure it stays running
            $startCommand = "nohup pg_ctl -D ${pgDataPath} -l ${pgDataPath}/pg_log/startup.log start > /dev/null 2>&1 &"
            $startResult = Run-SSHCommand -server $server -command $startCommand -execUser $pgUser
   
            Update-Output "Database start initiated with command: $startCommand" -server $server
            Update-Output "Waiting for database to start..." -server $server
            
            # Wait for database to start with a timeout
            $dbTimeout = 60
            $dbTimer = [Diagnostics.Stopwatch]::StartNew()
            $dbStarted = $false
            
            while (-not $dbStarted -and $dbTimer.Elapsed.TotalSeconds -lt $dbTimeout) {
                Start-Sleep -Seconds 5
                $pgStatus = Check-PostgreSQL -server $server -pgUser $pgUser -pgDataPath $pgDataPath -pgPort $pgPort
                if ($pgStatus.IsHealthy) {
                    $dbStarted = $true
                    break
                }
            }
   
            if ($pgStatus.IsHealthy) {
                Update-Output "$pgUser database successfully started and responding." -server $server -type "SUCCESS"
            } else {
                Update-Output "WARNING: $pgUser database failed to start properly." -server $server -type "ERROR"
               
                # If still having socket issues, try waiting longer
                if ($pgStatus.ProcessRunning -and $pgStatus.SocketError) {
                    Update-Output "Socket still not available. Checking logs..." -server $server
                    
                    # Check logs for errors
                    $logCheck = Run-SSHCommand -server $server -command "tail -n 20 $pgDataPath/pg_log/startup.log" -execUser $pgUser
                    Update-Output "Recent database log entries:" -server $server
                    Update-Output $logCheck -server $server
                }
            }
        } else {
            Update-Output "$pgUser database is already running and accepting connections." -server $server -type "SUCCESS"
        }
        $currentStep++
        $global:serverStatus[$server].Progress = [int](($currentStep / $totalSteps) * 100)
        
        # Step 7: Check barman
        $global:serverStatus[$server].CurrentStep = "Checking Barman status"
        if ($config.HasBarman) {
            $barmanStatus = Check-FixBarman -server $server -barmanUser $config.BarmanUser -barmanName $config.BarmanName
            Update-Output "Barman check complete." -server $server -type "INFO"
        } else {
            Update-Output "Barman not configured on this server, skipping barman check." -server $server -type "INFO"
        }
        $currentStep++
        $global:serverStatus[$server].Progress = 100
        
        # Mark server as completed
        $global:serverStatus[$server] = @{
            Status = "Completed"
            Progress = 100
            CurrentStep = "Maintenance complete"
        }
        
        Update-Output "Maintenance completed successfully." -server $server -type "SUCCESS" -force
    }
    catch {
        Update-Output "ERROR in maintenance process: $_" -server $server -type "ERROR" -force
        $global:serverStatus[$server] = @{
            Status = "Failed"
            Progress = 100
            CurrentStep = "Error: $_"
        }
    }
}

# Function to update progress bar from server status
function Update-Progress {
    $totalProgress = 0
    $serverCount = $global:serverStatus.Count
    
    if ($serverCount -gt 0) {
        foreach ($server in $global:serverStatus.Keys) {
            $totalProgress += $global:serverStatus[$server].Progress
        }
        $averageProgress = [int]($totalProgress / $serverCount)
        
        $form.Invoke([Action]{
            $progressBar.Value = $averageProgress
        })
    }
}

# Function to run a complete maintenance cycle - COMPLETELY REWRITTEN
function Start-MaintenanceCycle {
    $form.Invoke([Action]{ $outputBox.Clear() })
    
    # Reset global status
    $global:serverStatus.Clear()
    $global:logBuffer.Clear()
    
    # Get selected servers
    $selectedServers = @()
    $form.Invoke([Action]{
        for ($i = 0; $i -lt $serverListBox.Items.Count; $i++) {
            if ($serverListBox.GetItemChecked($i)) {
                $selectedServers += $serverListBox.Items[$i]
            }
        }
    })
    
    if ($selectedServers.Count -eq 0) {
        Update-Output "No servers selected. Please select at least one server." "ERROR" -force
        $form.Invoke([Action]{ $runButton.Enabled = $true })
        return
    }
    
    # Get selected tasks
    $options = @{
        RepoCheck = $false
        DbStop = $false
        UpdateCheck = $false
        UpdateApply = $false
        Reboot = $false
        Parallel = $false
        MaxParallel = 3
    }
    
    $form.Invoke([Action]{
        $options.RepoCheck = $chkRepoCheck.Checked
        $options.DbStop = $chkDbStop.Checked
        $options.UpdateCheck = $chkUpdateCheck.Checked
        $options.UpdateApply = $chkUpdateApply.Checked
        $options.Reboot = $chkReboot.Checked
        $options.Parallel = $chkParallel.Checked
        $options.MaxParallel = [int]$numParallelServers.Value
    })
    
    # Format tasks for log
    $tasks = @()
    if ($options.RepoCheck) { $tasks += "Check repositories" }
    if ($options.DbStop) { $tasks += "Stop database" }
    if ($options.UpdateCheck) { $tasks += "Check for updates" }
    if ($options.UpdateApply) { $tasks += "Apply updates" }
    if ($options.Reboot) { $tasks += "Reboot servers" }
    
    Update-Output "Starting maintenance on $($selectedServers.Count) server(s) with tasks: $($tasks -join ', ')" "INFO" -force
    
    # Initialize progress trackers for each server
    foreach ($server in $selectedServers) {
        $global:serverStatus[$server] = @{
            Status = "Pending"
            Progress = 0
            CurrentStep = "Waiting to start"
        }
    }
    
    # Start a thread to periodically update the progress bar
    $progressUpdater = [PowerShell]::Create().AddScript({
        param($serverStatus)
        while ($true) {
            # Calculate average progress
            $totalProgress = 0
            $serverCount = $serverStatus.Count
            
            if ($serverCount -gt 0) {
                foreach ($server in $serverStatus.Keys) {
                    $totalProgress += $serverStatus[$server].Progress
                }
                $averageProgress = [int]($totalProgress / $serverCount)
                
                # Check if all servers are completed
                $allCompleted = $true
                foreach ($server in $serverStatus.Keys) {
                    if ($serverStatus[$server].Status -ne "Completed" -and $serverStatus[$server].Status -ne "Failed") {
                        $allCompleted = $false
                        break
                    }
                }
                
                if ($allCompleted) {
                    break
                }
            }
            
            Start-Sleep -Seconds 1
        }
    }).AddArgument($global:serverStatus)
    
    $progressUpdaterJob = $progressUpdater.BeginInvoke()
    
    # Start maintenance based on parallel option
    if ($options.Parallel) {
        # Parallel processing with throttling
        $runspacePool = [runspacefactory]::CreateRunspacePool(1, $options.MaxParallel)
        $runspacePool.Open()
        
        $jobs = @()
        $runspaces = @()
        
        foreach ($server in $selectedServers) {
            $serverIndex = $selectedServers.IndexOf($server)
            
            # Create new runspace for server
            $powerShell = [powershell]::Create().AddScript($function:Invoke-ServerMaintenance)
            $powerShell.AddParameter("server", $server)
            $powerShell.AddParameter("options", $options)
            $powerShell.AddParameter("serverIndex", $serverIndex)
            $powerShell.AddParameter("totalServers", $selectedServers.Count)
            $powerShell.RunspacePool = $runspacePool
            
            $runspaces += @{
                PowerShell = $powerShell
                Handle = $powerShell.BeginInvoke()
                Server = $server
            }
        }
        
        # Wait for all runspaces to complete
        $completed = $false
        while (-not $completed) {
            $completed = $true
            
            foreach ($runspace in $runspaces) {
                if (-not $runspace.Handle.IsCompleted) {
                    $completed = $false
                    break
                }
            }
            
            # Update progress
            Update-Progress
            
            if (-not $completed) {
                Start-Sleep -Milliseconds 500
            }
        }
        
        # Clean up runspaces
        foreach ($runspace in $runspaces) {
            $runspace.PowerShell.EndInvoke($runspace.Handle)
            $runspace.PowerShell.Dispose()
        }
        
        $runspacePool.Close()
        $runspacePool.Dispose()
    }
    else {
        # Sequential processing
        foreach ($server in $selectedServers) {
            $serverIndex = $selectedServers.IndexOf($server)
            Invoke-ServerMaintenance -server $server -options $options -serverIndex $serverIndex -totalServers $selectedServers.Count
            
            # Update progress after each server
            Update-Progress
        }
    }
    
    # Ensure all logs are written
    Update-Output "Maintenance cycle completed for all selected servers." "SUCCESS" -force
    $form.Invoke([Action]{ 
        $statusLabel.Text = "Maintenance complete"
        $runButton.Enabled = $true
        $progressBar.Value = 100
    })
    
    # Dispose progress updater
    $progressUpdater.Dispose()
}

# Button event handlers
$runButton.Add_Click({
    $runButton.Enabled = $false
    $statusLabel.Text = "Running maintenance..."
    $progressBar.Value = 0
    
    # Start maintenance in a background thread to keep UI responsive
    $maintenanceThread = [System.Threading.Thread]::new({
        Start-MaintenanceCycle
    })
    $maintenanceThread.Start()
})

$clearButton.Add_Click({
    $outputBox.Clear()
    $statusLabel.Text = "Log cleared"
})

$saveButton.Add_Click({
    $saveDialog = New-Object System.Windows.Forms.SaveFileDialog
    $saveDialog.Filter = "Log Files (*.log)|*.log|Text Files (*.txt)|*.txt|All Files (*.*)|*.*"
    $saveDialog.Title = "Save Log File"
    $saveDialog.FileName = "ServerMaintenance_$(Get-Date -Format 'yyyyMMdd_HHmmss').log"
   
    if ($saveDialog.ShowDialog() -eq [System.Windows.Forms.DialogResult]::OK) {
        $outputBox.Text | Out-File -FilePath $saveDialog.FileName
        $statusLabel.Text = "Log saved to $($saveDialog.FileName)"
    }
})

# Initialize UI
Update-Output "PostgreSQL/EDB Server Maintenance Utility started" "INFO" -force
Update-Output "Found $($servers.Count) servers in configuration" "INFO" -force
Update-Output "Ready to start maintenance. Select servers and options, then click 'Run Maintenance'" "INFO" -force

# Show the form
$form.ShowDialog()