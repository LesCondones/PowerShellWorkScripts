#Author: Lester Artis Jr.

#Created: 04/09/2025
#Modified: 04/16/2025 - Added optimizations for high workloads

# Load Windows Forms and Drawing assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing
[System.Windows.Forms.Application]::EnableVisualStyles()

# Configuration paths
$configPath = "C:\Powershell_scripts\check_yum"
$serverListFile = "$configPath\serversPROD.txt"
$usernameListFile = "$configPath\username.txt"

# Read configuration
$servers = Get-Content $serverListFile
$username = Get-Content $usernameListFile

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
# Fixed division operator error by using [int] cast
$titleLabel.Location = New-Object System.Drawing.Point(15, [int](($headerPanel.Height - $titleLabel.PreferredHeight) / 2))
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
# Row 0: Main content area (takes all available space)
$mainContainer.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)))
# Row 1: Bottom controls area (fixed height)
$mainContainer.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 60)))
# Column 0: Left panel (servers, options)
$mainContainer.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 30)))
# Column 1: Right panel (log, progress, buttons)
$mainContainer.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 70)))
$mainContainer.Padding = New-Object System.Windows.Forms.Padding(10)
# Add mainContainer AFTER the headerPanel so it doesn't overlap
$mainContainer.Controls.Add($scrollPanel, 0, 1)
$form.Controls.Add($mainContainer)
$mainContainer.BringToFront() # Ensure it's layered correctly above the form background

# Create server list & controls panel (left side - Cell 0,0)
$leftPanel = New-Object System.Windows.Forms.Panel
$leftPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$leftPanel.Padding = New-Object System.Windows.Forms.Padding(0, 0, 10, 0)
# Place leftPanel in the correct cell
$mainContainer.Controls.Add($leftPanel, 0, 0)

# Server list group
$serverGroup = New-Object System.Windows.Forms.GroupBox
$serverGroup.Text = "Servers"
$serverGroup.Dock = [System.Windows.Forms.DockStyle]::Top
$serverGroup.Height = 200 # Keep fixed height for server list
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

# Options container - Use FlowLayoutPanel for automatic checkbox layout
$optionsContainer = New-Object System.Windows.Forms.FlowLayoutPanel
$optionsContainer.Dock = [System.Windows.Forms.DockStyle]::Fill
$optionsContainer.Padding = New-Object System.Windows.Forms.Padding(10)
$optionsContainer.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown
$optionsContainer.WrapContents = $false
$optionsContainer.AutoScroll = $true
$optionsGroup.Controls.Add($optionsContainer)

# Checkboxes for options - Add to FlowLayoutPanel, remove Location, add Margin
$checkboxMargin = New-Object System.Windows.Forms.Padding(3, 0, 3, 5) # L,T,R,B margin for spacing

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

# Advanced options
$chkParallel = New-Object System.Windows.Forms.CheckBox
$chkParallel.Text = "Parallel execution"
$chkParallel.AutoSize = $true
$chkParallel.Checked = $false
$chkParallel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$chkParallel.Margin = $checkboxMargin
$optionsContainer.Controls.Add($chkParallel)

# Timeout selector
$timeoutLabel = New-Object System.Windows.Forms.Label
$timeoutLabel.Text = "Update timeout (minutes):"
$timeoutLabel.AutoSize = $true
$timeoutLabel.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$timeoutLabel.Margin = $checkboxMargin
$optionsContainer.Controls.Add($timeoutLabel)

$timeoutSelector = New-Object System.Windows.Forms.NumericUpDown
$timeoutSelector.Minimum = 5
$timeoutSelector.Maximum = 60
$timeoutSelector.Value = 30
$timeoutSelector.Width = 70
$timeoutSelector.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$timeoutSelector.Margin = $checkboxMargin
$optionsContainer.Controls.Add($timeoutSelector)

# Output log panel (right side - top - Cell 1,0)
$logPanel = New-Object System.Windows.Forms.Panel
$logPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$mainContainer.Controls.Add($logPanel, 1, 0)

# Output group
$outputGroup = New-Object System.Windows.Forms.GroupBox
$outputGroup.Text = "Activity Log"
$outputGroup.Dock = [System.Windows.Forms.DockStyle]::Fill
$outputGroup.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$outputGroup.Padding = New-Object System.Windows.Forms.Padding(5, 3, 5, 5) # Padding around textbox
$logPanel.Controls.Add($outputGroup)

# Output textbox with rich text
$outputBox = New-Object System.Windows.Forms.RichTextBox
$outputBox.Dock = [System.Windows.Forms.DockStyle]::Fill
$outputBox.Multiline = $true
$outputBox.ScrollBars = [System.Windows.Forms.RichTextBoxScrollBars]::Vertical # Use Enum
$outputBox.ReadOnly = $true
$outputBox.BackColor = [System.Drawing.Color]::White
$outputBox.Font = New-Object System.Drawing.Font("Consolas", 9)
$outputBox.HideSelection = $false # Keep text selected even when focus leaves
$outputBox.MaxLength = 1000000 # Limit text length to prevent memory issues
$outputGroup.Controls.Add($outputBox)

# Create controls panel (right side - bottom - Cell 1,1)
$controlsPanel = New-Object System.Windows.Forms.Panel
$controlsPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$controlsPanel.Padding = New-Object System.Windows.Forms.Padding(0, 5, 0, 0) # Add some top padding
$mainContainer.Controls.Add($controlsPanel, 1, 1)

# Progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Dock = [System.Windows.Forms.DockStyle]::Top
$progressBar.Height = 20 # Explicitly set height
$progressBar.Style = [System.Windows.Forms.ProgressBarStyle]::Continuous
$controlsPanel.Controls.Add($progressBar)

# Button container - Use FlowLayoutPanel for easy button arrangement
$buttonContainer = New-Object System.Windows.Forms.FlowLayoutPanel
# *** Dock the button container to fill the rest of the controlsPanel ***
$buttonContainer.Dock = [System.Windows.Forms.DockStyle]::Fill
$buttonContainer.FlowDirection = [System.Windows.Forms.FlowDirection]::RightToLeft # Buttons align to the right
$buttonContainer.WrapContents = $false # Keep buttons on one line
# Add some padding so buttons aren't flush against progress bar/edges
$buttonContainer.Padding = New-Object System.Windows.Forms.Padding(0, 5, 0, 0) # T Padding
$controlsPanel.Controls.Add($buttonContainer)
$buttonContainer.BringToFront()

# Buttons with improved styling - Add directly to FlowLayoutPanel
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

# Create a synchronized hashtable for sharing data between runspaces
$script:SyncHash = [hashtable]::Synchronized(@{})
$script:SyncHash.OutputQueue = [System.Collections.Concurrent.ConcurrentQueue[object]]::new()
$script:SyncHash.ServerStatus = @{}
$script:SyncHash.RunningJobs = @{}
$script:SyncHash.CancelOperation = $false

# Function to run SSH commands with specific user and improved timeout handling
function Run-SSHCommand {
    param (
        [string]$server,
        [string]$command,
        [string]$execUser = "root",
        [string]$connectAs = $username,
        [int]$timeout = 60,
        [switch]$getLongOutput
    )
   
    try {
        $sshCommand = ""
        if ($execUser -eq "root") {
            # For root commands, use dzdo directly
            $sshCommand = "ssh -o GSSAPIAuthentication=yes -o ConnectTimeout=10 ${connectAs}@${server} `"dzdo su - -c '$command'`""
        } else{
            $sshCommand = "ssh -o GSSAPIAuthentication=yes -o ConnectTimeout=10 ${connectAs}@${server} `"dzdo su -  $execUser -c '$command'`""
        }
       
        # For long output operations like yum update, use a different approach
        if ($getLongOutput) {
            # Create a temp file to store output
            $tempFile = [System.IO.Path]::GetTempFileName()
            
            # Start the process and redirect output to temp file
            $process = Start-Process -FilePath "powershell" -ArgumentList "-Command", $sshCommand -RedirectStandardOutput $tempFile -NoNewWindow -PassThru
            
            # Wait for the process with progress updates
            $elapsedTime = 0
            $interval = 5  # Check every 5 seconds
            
            while (!$process.HasExited -and $elapsedTime -lt $timeout) {
                Start-Sleep -Seconds $interval
                $elapsedTime += $interval
                
                # Get current output progress
                try {
                    $currentOutput = Get-Content -Path $tempFile -Tail 5 -ErrorAction SilentlyContinue
                    if ($currentOutput) {
                        $progressLine = $currentOutput | Where-Object { $_ -match 'Running|Processing|Complete|Installing|Updating' } | Select-Object -Last 1
                        if ($progressLine) {
                            $script:SyncHash.OutputQueue.Enqueue(@{
                                Type = "PROGRESS"
                                Server = $server
                                Message = "Progress: $progressLine"
                            })
                        }
                    }
                } catch { }
                
                # Check if operation should be canceled
                if ($script:SyncHash.CancelOperation) {
                    try { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue } catch { }
                    Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
                    return "CANCELED: Operation was canceled by user"
                }
            }
            
            # Check if timed out
            if (!$process.HasExited) {
                try { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue } catch { }
                Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
                return "ERROR: Command execution timed out after $timeout seconds"
            }
            
            # Get the output
            $result = Get-Content -Path $tempFile -Raw
            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
            return $result
        }
        else {
            # For regular commands, use the job approach
            $job = Start-Job -ScriptBlock {
                param($cmd)
                Invoke-Expression $cmd
            } -ArgumentList $sshCommand
           
            # Wait for the command to complete or timeout
            if (Wait-Job $job -Timeout $timeout) {
                $result = Receive-Job $job
                Remove-Job $job
                return $result
            } else {
                Stop-Job $job
                Remove-Job $job
                return "ERROR: Command execution timed out after $timeout seconds"
            }
        }
    }
    catch {
        return "ERROR: $_"
    }
}

# Function to update output with color coding and thread safety
function Update-Output {
    param (
        [string]$message,
        [string]$type = "INFO", # INFO, SUCCESS, WARNING, ERROR
        [string]$server = ""
    )
   
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $serverPrefix = if ($server) { "[$server] " } else { "" }
    $fullMessage = "[$timestamp] $serverPrefix$message"
   
    # Add to synchronized queue for thread-safe UI updates
    $script:SyncHash.OutputQueue.Enqueue(@{
        Message = $fullMessage
        Type = $type
    })
}

# Timer for processing output queue to avoid UI thread blocking
$outputTimer = New-Object System.Windows.Forms.Timer
$outputTimer.Interval = 200  # Update the UI every 200ms
$outputTimer.Add_Tick({
    # Process up to 10 messages at a time to prevent UI freezing
    $processCount = 0
    $maxProcessPerTick = 10
    
    while ($script:SyncHash.OutputQueue.Count -gt 0 -and $processCount -lt $maxProcessPerTick) {
        $item = $null
        $dequeued = $script:SyncHash.OutputQueue.TryDequeue([ref]$item)
        
        if ($dequeued -and $item -ne $null) {
            if ($item.Type -eq "PROGRESS") {
                # Update status label for progress
                $statusLabel.Text = $item.Message
            }
            else {
                # Set color based on message type
                switch ($item.Type) {
                    "SUCCESS" { $color = [System.Drawing.Color]::FromArgb(39, 174, 96) }
                    "WARNING" { $color = [System.Drawing.Color]::FromArgb(211, 84, 0) }
                    "ERROR"   { $color = [System.Drawing.Color]::FromArgb(192, 57, 43) }
                    default   { $color = [System.Drawing.Color]::FromArgb(44, 62, 80) }
                }
                
                # Add colored text and avoid UI thread blocking
                $outputBox.SelectionStart = $outputBox.TextLength
                $outputBox.SelectionLength = 0
                $outputBox.SelectionColor = $color
                $outputBox.AppendText("$($item.Message)`n")
                
                # Auto-trim output box if it gets too large
                if ($outputBox.TextLength > 800000) {
                    $outputBox.Select(0, 200000)
                    $outputBox.SelectedText = ""
                }
                
                $outputBox.SelectionStart = $outputBox.TextLength
                $outputBox.ScrollToCaret()
                
                # Update status bar
                $statusLabel.Text = $item.Message
            }
        }
        
        $processCount++
    }
})

# Function to detect server configuration
function Detect-ServerConfig {
    param (
        [string]$server
    )
   
    Update-Output "Detecting server configuration..." -server $server
   
    # First check which database user exists: enterprisedb or postgres
    $entDbCheck = Run-SSHCommand -server $server -command "id -u enterprisedb 2>/dev/null || echo 'Not found'" -execUser "enterprisedb"
    $pgCheck = Run-SSHCommand -server $server -command "id -u postgres 2>/dev/null || echo 'Not found'" -execUser "postgres"
   
    $pgUser = ""
    if ($entDbCheck -ne "Not found" -and $entDbCheck -notmatch "ERROR") {
        $pgUser = "enterprisedb"
        Update-Output "Detected enterprisedb user" "SUCCESS" -server $server
    } elseif ($pgCheck -ne "Not found" -and $pgCheck -notmatch "ERROR") {
        $pgUser = "postgres"
        Update-Output "Detected postgres user" "SUCCESS" -server $server
    } else {
        Update-Output "ERROR: Could not detect database user (neither enterprisedb nor postgres found)" "ERROR" -server $server
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
            Update-Output "Found database path: $pgDataPath" "SUCCESS" -server $server
            break
        }
    }
   
    # If no path was found, try to check environment variable
    if ([string]::IsNullOrEmpty($pgDataPath)) {
        $envCheck = Run-SSHCommand -server $server -command "echo \$PGDATA" -execUser $pgUser
        if (-not [string]::IsNullOrEmpty($envCheck) -and $envCheck -ne '$PGDATA' -and $envCheck -notmatch "ERROR") {
            $pgDataPath = $envCheck.Trim()
            Update-Output "Found database path from PGDATA environment variable: $pgDataPath" "SUCCESS" -server $server
        }
    }
   
    # If still no path, check postmaster.pid locations
    if ([string]::IsNullOrEmpty($pgDataPath)) {
        $pidCheck = Run-SSHCommand -server $server -command "find / -name postmaster.pid -path '*/data/*' 2>/dev/null | head -1" -execUser "root"
        if (-not [string]::IsNullOrEmpty($pidCheck) -and $pidCheck -notmatch "ERROR") {
            $pgDataPath = $pidCheck.Trim() -replace "/postmaster.pid", ""
            Update-Output "Found database path from postmaster.pid: $pgDataPath" "SUCCESS" -server $server
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
            Update-Output "Found barman configuration for: $barmanName" "SUCCESS" -server $server
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
                Update-Output "Barman is installed but $barmanName is not configured" "WARNING" -server $server
            } else {
                Update-Output "Found barman configuration for: $barmanName" "SUCCESS" -server $server
            }
        }
    }
   
    # Return the configuration
    if ([string]::IsNullOrEmpty($pgDataPath)) {
        Update-Output "WARNING: Could not detect database data path" "WARNING" -server $server
        return $null
    }
   
    Update-Output "Configuration detected successfully" "SUCCESS" -server $server
   
    return @{
        PgUser = $pgUser
        PgDataPath = $pgDataPath
        HasBarman = $hasBarman
        BarmanUser = $barmanUser
        BarmanName = $barmanName
    }
}

# Function to check if PostgreSQL is running
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
   
    # Check socket connectivity using pg_isready
    $readyCheck = Run-SSHCommand -server $server -command "pg_isready -p $pgPort 2>&1 || echo 'Not ready'" -execUser $pgUser
    $isReady = ($readyCheck -match "accepting connections")
   
    # Also test with psql for comprehensive testing
    $socketCheck = Run-SSHCommand -server $server -command "psql -p $pgPort -c 'SELECT 1' 2>&1 || echo 'Connection failed'" -execUser $pgUser
    $socketConnected = !($socketCheck -match "Connection failed" -or $socketCheck -match "failed" -or $socketCheck -match "ERROR")
    $socketError = ($socketCheck -match "socket.*failed: No such file or directory")
   
    # Return combined status
    return @{
        ProcessRunning = $processRunning
        SocketConnected = $socketConnected
        SocketError = $socketError
        IsHealthy = ($processRunning -and $socketConnected)
    }
}


# Function to check and fix Barman status
function Check-FixBarman {
    param (
        [string]$server,
        [string]$barmanUser,
        [string]$barmanName = "edb-5444"
    )
   
    Update-Output "Checking barman status..." -server $server
    $result = Run-SSHCommand -server $server -command "barman check $barmanName" -execUser "barman" -timeout 120
   
    # Check for replication slot missing error and fix
    if ($result -match "replication slot .* doesn't exist") {
        Update-Output "Replication slot missing. Creating slot..." "WARNING" -server $server
        $createSlotResult = Run-SSHCommand -server $server -command "barman receive-wal --create-slot $barmanName" -execUser "barman" -timeout 120
        Update-Output "Create slot result: $createSlotResult" -server $server
        Start-Sleep -Seconds 5
    }
   
    # Check for receive-wal not running error and fix
    if ($result -match "receive-wal running: FAILED") {
        Update-Output "WAL receiver not running. Starting WAL receiver..." "WARNING" -server $server
        $receiveWalResult = Run-SSHCommand -server $server -command "barman receive-wal $barmanName &" -execUser "barman" -timeout 120
        Update-Output "Start WAL receiver result: $receiveWalResult" -server $server
        Start-Sleep -Seconds 5
    }
   
    # Final verification
    Update-Output "Performing final barman check..." -server $server
    $finalCheck = Run-SSHCommand -server $server -command "barman check $barmanName" -execUser "barman" -timeout 120
   
    # Log the detailed results for troubleshooting
    Update-Output "Barman status details:" -server $server
    Update-Output $finalCheck -server $server
   
    if ($finalCheck -match "FAILED") {
        Update-Output "WARNING: Some barman checks still failing after fixes." "WARNING" -server $server
        return $false
    } else {
        Update-Output "All barman checks passed successfully." "SUCCESS" -server $server
        return $true
    }
}

# Function to run a complete maintenance cycle for a single server
function Start-ServerMaintenance {
    param (
        [string]$server,
        [array]$tasks,
        [int]$updateTimeout,
        [bool]$parallelEnabled
    )
    
    try {
        # Initialize server status
        $script:SyncHash.ServerStatus[$server] = "Running"
        
        # Detect server configuration
        $config = Detect-ServerConfig -server $server
        
        if ($config -eq $null) {
            Update-Output "ERROR: Failed to detect server configuration, skipping server" "ERROR" -server $server
            $script:SyncHash.ServerStatus[$server] = "Failed"
            return
        }
        
        $pgUser = $config.PgUser
        $pgDataPath = $config.PgDataPath
        $pgPort = "5444"  # Assuming standard port for all servers
        
        # Step 1: Check Repositories (explicitly as root)
        if ($tasks -contains "Check repositories") {
            Update-Output "Checking enabled repositories as root..." -server $server
            $result = Run-SSHCommand -server $server -command "yum repolist enabled" -execUser "root" -timeout 120
            if ($result -match "ERROR") {
                Update-Output "Failed to check repositories: $result" "ERROR" -server $server
            }
            else {
                Update-Output "Repository check complete." "SUCCESS" -server $server
            }
        }
        
        # Step 2: Shutdown Database
        if ($tasks -contains "Stop database") {
            Update-Output "Shutting down PostgreSQL database as $pgUser..." -server $server
            $result = Run-SSHCommand -server $server -command "pg_ctl -D $pgDataPath stop -m fast" -execUser $pgUser -timeout 120
            if ($result -match "ERROR" -or $result -match "failed") {
                Update-Output "Failed to stop database: $result" "ERROR" -server $server
            }
            else {
                Update-Output "PostgreSQL database stopped successfully." "SUCCESS" -server $server
            }
        }
        
        # Step 3: Check Updates (as root)
        if ($tasks -contains "Check for updates") {
            Update-Output "Checking for updates as root..." -server $server
            $result = Run-SSHCommand -server $server -command "yum check-update" -execUser "root" -timeout 180
            if ($result -match "ERROR") {
                Update-Output "Failed to check updates: $result" "ERROR" -server $server
            }
            else {
                Update-Output "Update check complete." "SUCCESS" -server $server
            }
        }
        
        # Step 4: Apply Updates (as root) - with extended timeout and progress reporting
        if ($tasks -contains "Apply updates") {
            Update-Output "Applying updates as root..." -server $server
            
            # Using a much longer timeout and getting progress output
            $timeoutSeconds = $updateTimeout * 60
            Update-Output "Using extended timeout of $updateTimeout minutes for updates" -server $server
            
            # Execute with progress monitoring
            $result = Run-SSHCommand -server $server -command "yum -y update" -execUser "root" -timeout $timeoutSeconds -getLongOutput
            
            if ($result -match "ERROR" -or $result -match "CANCELED") {
                if ($result -match "CANCELED") {
                    Update-Output "Update operation was canceled by user" "WARNING" -server $server
                } else {
                    Update-Output "Failed to apply updates: $result" "ERROR" -server $server
                }
            }
            else {
                Update-Output "Updates applied successfully." "SUCCESS" -server $server
            }
        }
        
        # Step 5: Reboot server as root
        if ($tasks -contains "Reboot servers") {
            Update-Output "Rebooting server..." -server $server
            $result = Run-SSHCommand -server $server -command "init 6" -execUser "root" -timeout 10
            Update-Output "Reboot command sent. Waiting for server to come back online..." -server $server

            # Wait for server to reboot
            $timeout = 300 # 5 minutes timeout
            $timer = [Diagnostics.Stopwatch]::StartNew()
            $isOnline = $false

            while (-not $isOnline -and $timer.Elapsed.TotalSeconds -lt $timeout) {
                Start-Sleep -Seconds 15
                try {
                    $pingTest = Test-Connection -ComputerName $server -Count 1 -Quiet
                    if ($pingTest) {
                        # Additional wait for SSH to become available
                        Start-Sleep -Seconds 30
                        $isOnline = $true
                    }
                }
                catch {
                    # Continue waiting
                }
                
                # Add progress updates every 15 seconds
                Update-Output "Waiting for server to come back online... ($([int]$timer.Elapsed.TotalSeconds) seconds)" -server $server
            }

            if (-not $isOnline) {
                Update-Output "WARNING: Server did not come back online within timeout period" "WARNING" -server $server
            }
            else {
                Update-Output "Server is back online" "SUCCESS" -server $server
            }
        }
        
        # Step 6: Check and start PostgreSQL if needed after reboot
        Update-Output "Checking if PostgreSQL or Enterprisedb is running after system reboot..." -server $server
        
        # Additional wait after reboot to ensure services have time to start
        Start-Sleep -Seconds 15
        
        $pgStatus = Check-PostgreSQL -server $server -pgUser $pgUser -pgDataPath $pgDataPath -pgPort $pgPort

        if (-not $pgStatus.IsHealthy) {
            Update-Output "$pgUser database not running or not responding. Will start using detected data path: $pgDataPath" -server $server
   
            # If we have a socket error but the process is running, stop it first
            if ($pgStatus.ProcessRunning -and $pgStatus.SocketError) {
                Update-Output "Socket error detected. Stopping database before restart..." -server $server
                $stopResult = Run-SSHCommand -server $server -command "pg_ctl -D $pgDataPath stop -m fast" -execUser $pgUser -timeout 120
                Update-Output "Stop result: $stopResult" -server $server
                Start-Sleep -Seconds 5
            }
   
            # Start database using the detected user and data path with improved command
            $startCommand = "nohup pg_ctl -D ${pgDataPath} -l ${pgDataPath}/pg_log/startup.log start > /dev/null 2>&1 &"
            $startResult = Run-SSHCommand -server $server -command $startCommand -execUser $pgUser -timeout 120
   
            Update-Output "Database start initiated with command: $startCommand" -server $server
            Update-Output "Waiting for database to start..." -server $server
            
            # Progressive waiting for database startup
            for ($i = 1; $i -le 6; $i++) {
                Start-Sleep -Seconds 5
                
                # Check status
                $pgStatus = Check-PostgreSQL -server $server -pgUser $pgUser -pgDataPath $pgDataPath -pgPort $pgPort
                
                if ($pgStatus.IsHealthy) {
                    Update-Output "$pgUser database successfully started and responding." "SUCCESS" -server $server
                    break
                } else {
                    Update-Output "Still waiting for database to start (attempt $i)..." -server $server
                }
            }
            
            # Final status check
            if (-not $pgStatus.IsHealthy) {
                Update-Output "WARNING: $pgUser database failed to start properly." "ERROR" -server $server
                
                # Check logs for errors
                $logCheck = Run-SSHCommand -server $server -command "tail -n 20 $pgDataPath/pg_log/startup.log" -execUser $pgUser -timeout 60
                Update-Output "Recent database log entries:" -server $server
                Update-Output $logCheck -server $server
            }
        } else {
            Update-Output "$pgUser database is already running and accepting connections." "SUCCESS" -server $server
        }
        
        # Step 7: Check if barman is running properly (only if barman is available)
        if ($config.HasBarman) {
            $barmanStatus = Check-FixBarman -server $server -barmanUser $config.BarmanUser -barmanName $config.BarmanName
            Update-Output "Barman check complete." "INFO" -server $server
        } else {
            Update-Output "Barman not configured on this server, skipping barman check." "INFO" -server $server
        }
        
        # Mark server as completed
        $script:SyncHash.ServerStatus[$server] = "Completed"
        Update-Output "All maintenance tasks completed successfully." "SUCCESS" -server $server
    }
    catch {
        Update-Output "ERROR: Unhandled exception during maintenance: $_" "ERROR" -server $server
        $script:SyncHash.ServerStatus[$server] = "Failed"
    }
}

# Function to run a complete maintenance cycle for all selected servers
function Start-MaintenanceCycle {
    # Clear old output and reset status
    $outputBox.Clear()
    $script:SyncHash.CancelOperation = $false
    $script:SyncHash.ServerStatus.Clear()
    $script:SyncHash.RunningJobs.Clear()
   
    # Get selected servers
    $selectedServers = @()
    for ($i = 0; $i -lt $serverListBox.Items.Count; $i++) {
        if ($serverListBox.GetItemChecked($i)) {
            $selectedServers += $serverListBox.Items[$i]
        }
    }
   
    if ($selectedServers.Count -eq 0) {
        Update-Output "No servers selected. Please select at least one server." "ERROR"
        $runButton.Enabled = $true
        $progressBar.Value = 0
        return
    }
   
    # Get selected tasks
    $tasks = @()
    if ($chkRepoCheck.Checked) { $tasks += "Check repositories" }
    if ($chkDbStop.Checked) { $tasks += "Stop database" }
    if ($chkUpdateCheck.Checked) { $tasks += "Check for updates" }
    if ($chkUpdateApply.Checked) { $tasks += "Apply updates" }
    if ($chkReboot.Checked) { $tasks += "Reboot servers" }

    # Get update timeout value
    $updateTimeout = [int]$timeoutSelector.Value
    
    # Get parallel execution option
    $parallelEnabled = $chkParallel.Checked
   
    Update-Output "Starting maintenance on $($selectedServers.Count) server(s) with tasks: $($tasks -join ', ')" "INFO"
    Update-Output "Update timeout set to $updateTimeout minutes" "INFO"
    
    if ($parallelEnabled) {
        Update-Output "Parallel execution enabled - servers will be processed simultaneously" "INFO"
    } else {
        Update-Output "Sequential execution - servers will be processed one by one" "INFO"
    }
    
    # Start the output timer
    $outputTimer.Start()
    
    # Progress tracking - Compatible with older PowerShell versions
    # Create the scriptblock for the timer that will update progress
    $progressTimer = New-Object System.Windows.Forms.Timer
    $progressTimer.Interval = 500  # Check every 500ms
    $progressTimer.Add_Tick({
        # Calculate progress based on server status
        if ($script:SyncHash.ServerStatus.Count -gt 0) {
            $completedCount = ($script:SyncHash.ServerStatus.Values | Where-Object { $_ -eq "Completed" }).Count
            $totalCount = $script:SyncHash.ServerStatus.Count
            
            if ($totalCount -gt 0) {
                $progressPercentage = [int](($completedCount / $totalCount) * 100)
                $progressBar.Value = $progressPercentage
            }
        }
        
        # Check if all servers are done
        $allDone = $true
        foreach ($status in $script:SyncHash.ServerStatus.Values) {
            if ($status -eq "Running") {
                $allDone = $false
                break
            }
        }
        
        if ($allDone -and $script:SyncHash.ServerStatus.Count -gt 0) {
            $runButton.Enabled = $true
            $statusLabel.Text = "Maintenance complete"
            
            # Stop the timers
            $outputTimer.Stop()
            $progressTimer.Stop()
            
            # Final messages
            Update-Output "Maintenance cycle completed for all selected servers." "SUCCESS"
            
            # Cleanup any remaining jobs
            foreach ($job in $script:SyncHash.RunningJobs.Values) {
                if ($job.Job -ne $null -and $job.Job.State -ne 'Completed') {
                    Remove-Job -Job $job.Job -Force -ErrorAction SilentlyContinue
                }
            }
            $script:SyncHash.RunningJobs.Clear()
        }
    })
    
    # Start the progress timer
    $progressTimer.Start()

    # Process servers - using standard PowerShell jobs for compatibility
    if ($parallelEnabled) {
        # Parallel processing
        $throttleLimit = [Math]::Min(5, $selectedServers.Count)  # Process up to 5 servers at once
        Update-Output "Processing up to $throttleLimit servers simultaneously" "INFO"
        
        # Start jobs for each server using standard PowerShell jobs
        foreach ($server in $selectedServers) {
            $script:SyncHash.ServerStatus[$server] = "Running"
            
            # Create a background job for each server
            $job = Start-Job -ScriptBlock {
                param($server, $tasks, $updateTimeout, $parallelEnabled, $syncHashTable, $username)
                
                # Create functions in the job scope
                function Update-Output {
                    param (
                        [string]$message,
                        [string]$type = "INFO",
                        [string]$server = ""
                    )
                   
                    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
                    $serverPrefix = if ($server) { "[$server] " } else { "" }
                    $fullMessage = "[$timestamp] $serverPrefix$message"
                   
                    # Add to synchronized queue
                    $syncHashTable.OutputQueue.Enqueue(@{
                        Message = $fullMessage
                        Type = $type
                    })
                }
                
                function Run-SSHCommand {
                    param (
                        [string]$server,
                        [string]$command,
                        [string]$execUser = "root",
                        [string]$connectAs = $username,
                        [int]$timeout = 60,
                        [switch]$getLongOutput
                    )
                   
                    try {
                        $sshCommand = ""
                        if ($execUser -eq "root") {
                            # For root commands, use dzdo directly
                            $sshCommand = "ssh -o GSSAPIAuthentication=yes -o ConnectTimeout=10 ${connectAs}@${server} `"dzdo su - -c '$command'`""
                        } else{
                            $sshCommand = "ssh -o GSSAPIAuthentication=yes -o ConnectTimeout=10 ${connectAs}@${server} `"dzdo su -  $execUser -c '$command'`""
                        }
                       
                        # For long output operations like yum update, use a different approach
                        if ($getLongOutput) {
                            # Create a temp file to store output
                            $tempFile = [System.IO.Path]::GetTempFileName()
                            
                            # Start the process and redirect output to temp file
                            $process = Start-Process -FilePath "powershell" -ArgumentList "-Command", $sshCommand -RedirectStandardOutput $tempFile -NoNewWindow -PassThru
                            
                            # Wait for the process with progress updates
                            $elapsedTime = 0
                            $interval = 5  # Check every 5 seconds
                            
                            while (!$process.HasExited -and $elapsedTime -lt $timeout) {
                                Start-Sleep -Seconds $interval
                                $elapsedTime += $interval
                                
                                # Get current output progress
                                try {
                                    $currentOutput = Get-Content -Path $tempFile -Tail 5 -ErrorAction SilentlyContinue
                                    if ($currentOutput) {
                                        $progressLine = $currentOutput | Where-Object { $_ -match 'Running|Processing|Complete|Installing|Updating' } | Select-Object -Last 1
                                        if ($progressLine) {
                                            $syncHashTable.OutputQueue.Enqueue(@{
                                                Type = "PROGRESS"
                                                Server = $server
                                                Message = "Progress: $progressLine"
                                            })
                                        }
                                    }
                                } catch { }
                                
                                # Check if operation should be canceled
                                if ($syncHashTable.CancelOperation) {
                                    try { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue } catch { }
                                    Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
                                    return "CANCELED: Operation was canceled by user"
                                }
                            }
                            
                            # Check if timed out
                            if (!$process.HasExited) {
                                try { Stop-Process -Id $process.Id -Force -ErrorAction SilentlyContinue } catch { }
                                Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
                                return "ERROR: Command execution timed out after $timeout seconds"
                            }
                            
                            # Get the output
                            $result = Get-Content -Path $tempFile -Raw
                            Remove-Item -Path $tempFile -Force -ErrorAction SilentlyContinue
                            return $result
                        }
                        else {
                            # For regular commands, use the job approach
                            $job = Start-Job -ScriptBlock {
                                param($cmd)
                                Invoke-Expression $cmd
                            } -ArgumentList $sshCommand
                           
                            # Wait for the command to complete or timeout
                            if (Wait-Job $job -Timeout $timeout) {
                                $result = Receive-Job $job
                                Remove-Job $job
                                return $result
                            } else {
                                Stop-Job $job
                                Remove-Job $job
                                return "ERROR: Command execution timed out after $timeout seconds"
                            }
                        }
                    }
                    catch {
                        return "ERROR: $_"
                    }
                }
                
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
                   
                    # Check socket connectivity using pg_isready
                    $readyCheck = Run-SSHCommand -server $server -command "pg_isready -p $pgPort 2>&1 || echo 'Not ready'" -execUser $pgUser
                    $isReady = ($readyCheck -match "accepting connections")
                   
                    # Also test with psql for comprehensive testing
                    $socketCheck = Run-SSHCommand -server $server -command "psql -p $pgPort -c 'SELECT 1' 2>&1 || echo 'Connection failed'" -execUser $pgUser
                    $socketConnected = !($socketCheck -match "Connection failed" -or $socketCheck -match "failed" -or $socketCheck -match "ERROR")
                    $socketError = ($socketCheck -match "socket.*failed: No such file or directory")
                   
                    # Return combined status
                    return @{
                        ProcessRunning = $processRunning
                        SocketConnected = $socketConnected
                        SocketError = $socketError
                        IsHealthy = ($processRunning -and $socketConnected)
                    }
                }
                
                function Detect-ServerConfig {
                    param (
                        [string]$server
                    )
                   
                    Update-Output "Detecting server configuration..." -server $server
                   
                    # First check which database user exists: enterprisedb or postgres
                    $entDbCheck = Run-SSHCommand -server $server -command "id -u enterprisedb 2>/dev/null || echo 'Not found'" -execUser "enterprisedb"
                    $pgCheck = Run-SSHCommand -server $server -command "id -u postgres 2>/dev/null || echo 'Not found'" -execUser "postgres"
                   
                    $pgUser = ""
                    if ($entDbCheck -ne "Not found" -and $entDbCheck -notmatch "ERROR") {
                        $pgUser = "enterprisedb"
                        Update-Output "Detected enterprisedb user" "SUCCESS" -server $server
                    } elseif ($pgCheck -ne "Not found" -and $pgCheck -notmatch "ERROR") {
                        $pgUser = "postgres"
                        Update-Output "Detected postgres user" "SUCCESS" -server $server
                    } else {
                        Update-Output "ERROR: Could not detect database user (neither enterprisedb nor postgres found)" "ERROR" -server $server
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
                            Update-Output "Found database path: $pgDataPath" "SUCCESS" -server $server
                            break
                        }
                    }
                   
                    # If no path was found, try to check environment variable
                    if ([string]::IsNullOrEmpty($pgDataPath)) {
                        $envCheck = Run-SSHCommand -server $server -command "echo \$PGDATA" -execUser $pgUser
                        if (-not [string]::IsNullOrEmpty($envCheck) -and $envCheck -ne '$PGDATA' -and $envCheck -notmatch "ERROR") {
                            $pgDataPath = $envCheck.Trim()
                            Update-Output "Found database path from PGDATA environment variable: $pgDataPath" "SUCCESS" -server $server
                        }
                    }
                   
                    # If still no path, check postmaster.pid locations
                    if ([string]::IsNullOrEmpty($pgDataPath)) {
                        $pidCheck = Run-SSHCommand -server $server -command "find / -name postmaster.pid -path '*/data/*' 2>/dev/null | head -1" -execUser "root"
                        if (-not [string]::IsNullOrEmpty($pidCheck) -and $pidCheck -notmatch "ERROR") {
                            $pgDataPath = $pidCheck.Trim() -replace "/postmaster.pid", ""
                            Update-Output "Found database path from postmaster.pid: $pgDataPath" "SUCCESS" -server $server
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
                            Update-Output "Found barman configuration for: $barmanName" "SUCCESS" -server $server
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
                                Update-Output "Barman is installed but $barmanName is not configured" "WARNING" -server $server
                            } else {
                                Update-Output "Found barman configuration for: $barmanName" "SUCCESS" -server $server
                            }
                        }
                    }
                   
                    # Return the configuration
                    if ([string]::IsNullOrEmpty($pgDataPath)) {
                        Update-Output "WARNING: Could not detect database data path" "WARNING" -server $server
                        return $null
                    }
                   
                    Update-Output "Configuration detected successfully" "SUCCESS" -server $server
                   
                    return @{
                        PgUser = $pgUser
                        PgDataPath = $pgDataPath
                        HasBarman = $hasBarman
                        BarmanUser = $barmanUser
                        BarmanName = $barmanName
                    }
                }
                
                function Check-FixBarman {
                    param (
                        [string]$server,
                        [string]$barmanUser,
                        [string]$barmanName = "edb-5444"
                    )
                   
                    Update-Output "Checking barman status..." -server $server
                    $result = Run-SSHCommand -server $server -command "barman check $barmanName" -execUser "barman" -timeout 120
                   
                    # Check for replication slot missing error and fix
                    if ($result -match "replication slot .* doesn't exist") {
                        Update-Output "Replication slot missing. Creating slot..." "WARNING" -server $server
                        $createSlotResult = Run-SSHCommand -server $server -command "barman receive-wal --create-slot $barmanName" -execUser "barman" -timeout 120
                        Update-Output "Create slot result: $createSlotResult" -server $server
                        Start-Sleep -Seconds 5
                    }
                   
                    # Check for receive-wal not running error and fix
                    if ($result -match "receive-wal running: FAILED") {
                        Update-Output "WAL receiver not running. Starting WAL receiver..." "WARNING" -server $server
                        $receiveWalResult = Run-SSHCommand -server $server -command "barman receive-wal $barmanName &" -execUser "barman" -timeout 120
                        Update-Output "Start WAL receiver result: $receiveWalResult" -server $server
                        Start-Sleep -Seconds 5
                    }
                   
                    # Final verification
                    Update-Output "Performing final barman check..." -server $server
                    $finalCheck = Run-SSHCommand -server $server -command "barman check $barmanName" -execUser "barman" -timeout 120
                   
                    # Log the detailed results for troubleshooting
                    Update-Output "Barman status details:" -server $server
                    Update-Output $finalCheck -server $server
                   
                    if ($finalCheck -match "FAILED") {
                        Update-Output "WARNING: Some barman checks still failing after fixes." "WARNING" -server $server
                        return $false
                    } else {
                        Update-Output "All barman checks passed successfully." "SUCCESS" -server $server
                        return $true
                    }
                }
                
                # Main maintenance logic for server
                try {
                    # Initialize server status
                    $syncHashTable.ServerStatus[$server] = "Running"
                    
                    # Detect server configuration
                    $config = Detect-ServerConfig -server $server
                    
                    if ($config -eq $null) {
                        Update-Output "ERROR: Failed to detect server configuration, skipping server" "ERROR" -server $server
                        $syncHashTable.ServerStatus[$server] = "Failed"
                        return
                    }
                    
                    $pgUser = $config.PgUser
                    $pgDataPath = $config.PgDataPath
                    $pgPort = "5444"  # Assuming standard port for all servers
                    
                    # Step 1: Check Repositories (explicitly as root)
                    if ($tasks -contains "Check repositories") {
                        Update-Output "Checking enabled repositories as root..." -server $server
                        $result = Run-SSHCommand -server $server -command "yum repolist enabled" -execUser "root" -timeout 120
                        if ($result -match "ERROR") {
                            Update-Output "Failed to check repositories: $result" "ERROR" -server $server
                        }
                        else {
                            Update-Output "Repository check complete." "SUCCESS" -server $server
                        }
                    }
                    
                    # Step 2: Shutdown Database
                    if ($tasks -contains "Stop database") {
                        Update-Output "Shutting down PostgreSQL database as $pgUser..." -server $server
                        $result = Run-SSHCommand -server $server -command "pg_ctl -D $pgDataPath stop -m fast" -execUser $pgUser -timeout 120
                        if ($result -match "ERROR" -or $result -match "failed") {
                            Update-Output "Failed to stop database: $result" "ERROR" -server $server
                        }
                        else {
                            Update-Output "PostgreSQL database stopped successfully." "SUCCESS" -server $server
                        }
                    }
                    
                    # Step 3: Check Updates (as root)
                    if ($tasks -contains "Check for updates") {
                        Update-Output "Checking for updates as root..." -server $server
                        $result = Run-SSHCommand -server $server -command "yum check-update" -execUser "root" -timeout 180
                        if ($result -match "ERROR") {
                            Update-Output "Failed to check updates: $result" "ERROR" -server $server
                        }
                        else {
                            Update-Output "Update check complete." "SUCCESS" -server $server
                        }
                    }
                    
                    # Step 4: Apply Updates (as root) - with extended timeout and progress reporting
                    if ($tasks -contains "Apply updates") {
                        Update-Output "Applying updates as root..." -server $server
                        
                        # Using a much longer timeout and getting progress output
                        $timeoutSeconds = $updateTimeout * 60
                        Update-Output "Using extended timeout of $updateTimeout minutes for updates" -server $server
                        
                        # Execute with progress monitoring
                        $result = Run-SSHCommand -server $server -command "yum -y update" -execUser "root" -timeout $timeoutSeconds -getLongOutput
                        
                        if ($result -match "ERROR" -or $result -match "CANCELED") {
                            if ($result -match "CANCELED") {
                                Update-Output "Update operation was canceled by user" "WARNING" -server $server
                            } else {
                                Update-Output "Failed to apply updates: $result" "ERROR" -server $server
                            }
                        }
                        else {
                            Update-Output "Updates applied successfully." "SUCCESS" -server $server
                        }
                    }
                    
                    # Step 5: Reboot server as root
                    if ($tasks -contains "Reboot servers") {
                        Update-Output "Rebooting server..." -server $server
                        $result = Run-SSHCommand -server $server -command "init 6" -execUser "root" -timeout 10
                        Update-Output "Reboot command sent. Waiting for server to come back online..." -server $server
            
                        # Wait for server to reboot
                        $timeout = 300 # 5 minutes timeout
                        $timer = [Diagnostics.Stopwatch]::StartNew()
                        $isOnline = $false
            
                        while (-not $isOnline -and $timer.Elapsed.TotalSeconds -lt $timeout) {
                            Start-Sleep -Seconds 15
                            try {
                                $pingTest = Test-Connection -ComputerName $server -Count 1 -Quiet
                                if ($pingTest) {
                                    # Additional wait for SSH to become available
                                    Start-Sleep -Seconds 30
                                    $isOnline = $true
                                }
                            }
                            catch {
                                # Continue waiting
                            }
                            
                            # Add progress updates every 15 seconds
                            Update-Output "Waiting for server to come back online... ($([int]$timer.Elapsed.TotalSeconds) seconds)" -server $server
                        }
            
                        if (-not $isOnline) {
                            Update-Output "WARNING: Server did not come back online within timeout period" "WARNING" -server $server
                        }
                        else {
                            Update-Output "Server is back online" "SUCCESS" -server $server
                        }
                    }
                    
                    # Step 6: Check and start PostgreSQL if needed after reboot
                    Update-Output "Checking if PostgreSQL or Enterprisedb is running after system reboot..." -server $server
                    
                    # Additional wait after reboot to ensure services have time to start
                    Start-Sleep -Seconds 15
                    
                    $pgStatus = Check-PostgreSQL -server $server -pgUser $pgUser -pgDataPath $pgDataPath -pgPort $pgPort
            
                    if (-not $pgStatus.IsHealthy) {
                        Update-Output "$pgUser database not running or not responding. Will start using detected data path: $pgDataPath" -server $server
               
                        # If we have a socket error but the process is running, stop it first
                        if ($pgStatus.ProcessRunning -and $pgStatus.SocketError) {
                            Update-Output "Socket error detected. Stopping database before restart..." -server $server
                            $stopResult = Run-SSHCommand -server $server -command "pg_ctl -D $pgDataPath stop -m fast" -execUser $pgUser -timeout 120
                            Update-Output "Stop result: $stopResult" -server $server
                            Start-Sleep -Seconds 5
                        }
               
                        # Start database using the detected user and data path with improved command
                        $startCommand = "nohup pg_ctl -D ${pgDataPath} -l ${pgDataPath}/pg_log/startup.log start > /dev/null 2>&1 &"
                        $startResult = Run-SSHCommand -server $server -command $startCommand -execUser $pgUser -timeout 120
               
                        Update-Output "Database start initiated with command: $startCommand" -server $server
                        Update-Output "Waiting for database to start..." -server $server
                        
                        # Progressive waiting for database startup
                        for ($i = 1; $i -le 6; $i++) {
                            Start-Sleep -Seconds 5
                            
                            # Check status
                            $pgStatus = Check-PostgreSQL -server $server -pgUser $pgUser -pgDataPath $pgDataPath -pgPort $pgPort
                            
                            if ($pgStatus.IsHealthy) {
                                Update-Output "$pgUser database successfully started and responding." "SUCCESS" -server $server
                                break
                            } else {
                                Update-Output "Still waiting for database to start (attempt $i)..." -server $server
                            }
                        }
                        
                        # Final status check
                        if (-not $pgStatus.IsHealthy) {
                            Update-Output "WARNING: $pgUser database failed to start properly." "ERROR" -server $server
                            
                            # Check logs for errors
                            $logCheck = Run-SSHCommand -server $server -command "tail -n 20 $pgDataPath/pg_log/startup.log" -execUser $pgUser -timeout 60
                            Update-Output "Recent database log entries:" -server $server
                            Update-Output $logCheck -server $server
                        }
                    } else {
                        Update-Output "$pgUser database is already running and accepting connections." "SUCCESS" -server $server
                    }
                    
                    # Step 7: Check if barman is running properly (only if barman is available)
                    if ($config.HasBarman) {
                        $barmanStatus = Check-FixBarman -server $server -barmanUser $config.BarmanUser -barmanName $config.BarmanName
                        Update-Output "Barman check complete." "INFO" -server $server
                    } else {
                        Update-Output "Barman not configured on this server, skipping barman check." "INFO" -server $server
                    }
                    
                    # Mark server as completed
                    $syncHashTable.ServerStatus[$server] = "Completed"
                    Update-Output "All maintenance tasks completed successfully." "SUCCESS" -server $server
                }
                catch {
                    Update-Output "ERROR: Unhandled exception during maintenance: $_" "ERROR" -server $server
                    $syncHashTable.ServerStatus[$server] = "Failed"
                }
            } -ArgumentList $server, $tasks, $updateTimeout, $parallelEnabled, $script:SyncHash, $username
            
            # Fixed hash table syntax - using semicolons instead of commas
            $script:SyncHash.RunningJobs[$server] = @{
                Job = $job;
                Server = $server
            }
        }
    }
    else {
        # Sequential processing
        $job = Start-Job -ScriptBlock {
            param($servers, $tasks, $updateTimeout, $parallelEnabled, $syncHashTable)
            
            # Set the global sync hash in this job
            $script:SyncHash = $syncHashTable
            
            # Process each server sequentially
            foreach ($server in $servers) {
                if ($script:SyncHash.CancelOperation) {
                    break
                }
                
                $script:SyncHash.ServerStatus[$server] = "Running"
                
                # Import the necessary functions
                . ([scriptblock]::Create($script:SyncHash.Functions))
                
                # Run maintenance for this server
                Start-ServerMaintenance -server $server -tasks $tasks -updateTimeout $updateTimeout -parallelEnabled $parallelEnabled
            }
        } -ArgumentList $selectedServers, $tasks, $updateTimeout, $parallelEnabled, $script:SyncHash
        
        # Store the job reference with fixed hashtable syntax
        $script:SyncHash.RunningJobs["Main"] = @{
            Job = $job;
            Servers = $selectedServers
        }
    }
    
    # Store function definitions in the sync hash for use in child runspaces/jobs
    $script:SyncHash.Functions = @"
function Update-Output {
    param (
        [string]`$message,
        [string]`$type = "INFO",
        [string]`$server = ""
    )
   
    `$timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    `$serverPrefix = if (`$server) { "[`$server] " } else { "" }
    `$fullMessage = "[`$timestamp] `$serverPrefix`$message"
   
    # Add to synchronized queue
    `$script:SyncHash.OutputQueue.Enqueue(@{
        Message = `$fullMessage
        Type = `$type
    })
}

function Run-SSHCommand {
    param (
        [string]`$server,
        [string]`$command,
        [string]`$execUser = "root",
        [string]`$connectAs = "`$username",
        [int]`$timeout = 60,
        [switch]`$getLongOutput
    )
   
    try {
        `$sshCommand = ""
        if (`$execUser -eq "root") {
            # For root commands, use dzdo directly
            `$sshCommand = "ssh -o GSSAPIAuthentication=yes -o ConnectTimeout=10 `${connectAs}@`${server} `"dzdo su - -c '`$command'`""
        } else{
            `$sshCommand = "ssh -o GSSAPIAuthentication=yes -o ConnectTimeout=10 `${connectAs}@`${server} `"dzdo su -  `$execUser -c '`$command'`""
        }
       
        # For long output operations like yum update, use a different approach
        if (`$getLongOutput) {
            # Create a temp file to store output
            `$tempFile = [System.IO.Path]::GetTempFileName()
            
            # Start the process and redirect output to temp file
            `$process = Start-Process -FilePath "powershell" -ArgumentList "-Command", `$sshCommand -RedirectStandardOutput `$tempFile -NoNewWindow -PassThru
            
            # Wait for the process with progress updates
            `$elapsedTime = 0
            `$interval = 5  # Check every 5 seconds
            
            while (!`$process.HasExited -and `$elapsedTime -lt `$timeout) {
                Start-Sleep -Seconds `$interval
                `$elapsedTime += `$interval
                
                # Get current output progress
                try {
                    `$currentOutput = Get-Content -Path `$tempFile -Tail 5 -ErrorAction SilentlyContinue
                    if (`$currentOutput) {
                        `$progressLine = `$currentOutput | Where-Object { `$_ -match 'Running|Processing|Complete|Installing|Updating' } | Select-Object -Last 1
                        if (`$progressLine) {
                            `$script:SyncHash.OutputQueue.Enqueue(@{
                                Type = "PROGRESS"
                                Server = `$server
                                Message = "Progress: `$progressLine"
                            })
                        }
                    }
                } catch { }
                
                # Check if operation should be canceled
                if (`$script:SyncHash.CancelOperation) {
                    try { Stop-Process -Id `$process.Id -Force -ErrorAction SilentlyContinue } catch { }
                    Remove-Item -Path `$tempFile -Force -ErrorAction SilentlyContinue
                    return "CANCELED: Operation was canceled by user"
                }
            }
            
            # Check if timed out
            if (!`$process.HasExited) {
                try { Stop-Process -Id `$process.Id -Force -ErrorAction SilentlyContinue } catch { }
                Remove-Item -Path `$tempFile -Force -ErrorAction SilentlyContinue
                return "ERROR: Command execution timed out after `$timeout seconds"
            }
            
            # Get the output
            `$result = Get-Content -Path `$tempFile -Raw
            Remove-Item -Path `$tempFile -Force -ErrorAction SilentlyContinue
            return `$result
        }
        else {
            # For regular commands, use the job approach
            `$job = Start-Job -ScriptBlock {
                param(`$cmd)
                Invoke-Expression `$cmd
            } -ArgumentList `$sshCommand
           
            # Wait for the command to complete or timeout
            if (Wait-Job `$job -Timeout `$timeout) {
                `$result = Receive-Job `$job
                Remove-Job `$job
                return `$result
            } else {
                Stop-Job `$job
                Remove-Job `$job
                return "ERROR: Command execution timed out after `$timeout seconds"
            }
        }
    }
    catch {
        return "ERROR: `$_"
    }
}

function Check-PostgreSQL {
    param (
        [string]`$server,
        [string]`$pgUser,
        [string]`$pgDataPath,
        [string]`$pgPort = "5444"
    )
   
    # Check if process is running
    `$processPattern = if (`$pgUser -eq "enterprisedb") { "enterpr+" } else { "postgres" }
    `$processCheck = Run-SSHCommand -server `$server -command "ps -ef | grep -E `$processPattern | grep -v grep" -execUser `$pgUser
    `$processRunning = (`$processCheck -match "postgres")
   
    # Check socket connectivity using pg_isready
    `$readyCheck = Run-SSHCommand -server `$server -command "pg_isready -p `$pgPort 2>&1 || echo 'Not ready'" -execUser `$pgUser
    `$isReady = (`$readyCheck -match "accepting connections")
   
    # Also test with psql for comprehensive testing
    `$socketCheck = Run-SSHCommand -server `$server -command "psql -p `$pgPort -c 'SELECT 1' 2>&1 || echo 'Connection failed'" -execUser `$pgUser
    `$socketConnected = !(`$socketCheck -match "Connection failed" -or `$socketCheck -match "failed" -or `$socketCheck -match "ERROR")
    `$socketError = (`$socketCheck -match "socket.*failed: No such file or directory")
   
    # Return combined status
    return @{
        ProcessRunning = `$processRunning
        SocketConnected = `$socketConnected
        SocketError = `$socketError
        IsHealthy = (`$processRunning -and `$socketConnected)
    }
}
"@
}

# Add a cancel button
$cancelButton = New-Object System.Windows.Forms.Button
$cancelButton.Text = 'Cancel'
$cancelButton.Size = New-Object System.Drawing.Size(100, 30)
$cancelButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$cancelButton.BackColor = [System.Drawing.Color]::FromArgb(231, 76, 60)
$cancelButton.ForeColor = [System.Drawing.Color]::White
$cancelButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$cancelButton.Margin = $buttonMargin
$cancelButton.Enabled = $false
$buttonContainer.Controls.Add($cancelButton)

$cancelButton.Add_Click({
    $result = [System.Windows.Forms.MessageBox]::Show(
        "Are you sure you want to cancel the running maintenance operations?",
        "Confirm Cancel",
        [System.Windows.Forms.MessageBoxButtons]::YesNo,
        [System.Windows.Forms.MessageBoxIcon]::Question
    )
    
    if ($result -eq [System.Windows.Forms.DialogResult]::Yes) {
        $script:SyncHash.CancelOperation = $true
        Update-Output "Cancel requested. Stopping maintenance operations..." "WARNING"
        $cancelButton.Enabled = $false
    }
})

# Update button event handlers
$runButton.Add_Click({
    $runButton.Enabled = $false
    $cancelButton.Enabled = $true
    $statusLabel.Text = "Running maintenance..."
    $progressBar.Value = 0
    Start-MaintenanceCycle
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

# On form closing - cleanup jobs
$form.Add_FormClosing({
    $script:SyncHash.CancelOperation = $true
    
    # Clean up any running jobs
    foreach ($jobInfo in $script:SyncHash.RunningJobs.Values) {
        if ($jobInfo.PowerShell -ne $null) {
            $jobInfo.PowerShell.Stop()
            $jobInfo.PowerShell.Dispose()
        }
        
        if ($jobInfo.Job -ne $null) {
            Stop-Job -Job $jobInfo.Job -ErrorAction SilentlyContinue
            Remove-Job -Job $jobInfo.Job -Force -ErrorAction SilentlyContinue
        }
    }
    
    # Stop the output timer
    if ($outputTimer -ne $null) {
        $outputTimer.Stop()
        $outputTimer.Dispose()
    }
})

# Create version info
$versionLabel = New-Object System.Windows.Forms.Label
$versionLabel.Text = "v1.1.0 - Compatible with PowerShell 3.0+"
$versionLabel.ForeColor = [System.Drawing.Color]::White
$versionLabel.Font = New-Object System.Drawing.Font("Segoe UI", 8)
$versionLabel.AutoSize = $true
$versionLabel.Location = New-Object System.Drawing.Point(($headerPanel.Width - 210), ($headerPanel.Height - 25))
$headerPanel.Controls.Add($versionLabel)

# Initialize UI
Update-Output "PostgreSQL/EDB Server Maintenance Utility started" "INFO"
Update-Output "Found $($servers.Count) servers in configuration" "INFO"
Update-Output "Ready to start maintenance. Select servers and options, then click 'Run Maintenance'" "INFO"

# Show the form
$form.ShowDialog()
