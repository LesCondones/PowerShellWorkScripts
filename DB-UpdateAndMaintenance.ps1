# Author: Lester Artis Jr.
# Created: 04/09/2025

# Took already created script and made it more efficient, still isnt complete

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

# Create form with improved styling
$form = New-Object System.Windows.Forms.Form
$form.Text = 'PostgreSQL/EDB Server Maintenance Utility'
$form.Size = New-Object System.Drawing.Size(850, 600) # Start size, layout should handle resizing
$form.MinimumSize = New-Object System.Drawing.Size(600, 450) # Prevent making it too small
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
$titleLabel.Location = New-Object System.Drawing.Point(15, ($headerPanel.Height - $titleLabel.PreferredHeight) / 2) # Center vertically
$headerPanel.Controls.Add($titleLabel)

# Create main container
$mainContainer = New-Object System.Windows.Forms.TableLayoutPanel
$mainContainer.Dock = [System.Windows.Forms.DockStyle]::Fill
$mainContainer.RowCount = 2
$mainContainer.ColumnCount = 2
# Row 0: Main content area (takes all available space)
$mainContainer.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Percent, 100)))
# Row 1: Bottom controls area (fixed height)
$mainContainer.RowStyles.Add((New-Object System.Windows.Forms.RowStyle([System.Windows.Forms.SizeType]::Absolute, 60))) # Increased height for controls
# Column 0: Left panel (servers, options)
$mainContainer.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 30))) # Adjusted percentage
# Column 1: Right panel (log, progress, buttons)
$mainContainer.ColumnStyles.Add((New-Object System.Windows.Forms.ColumnStyle([System.Windows.Forms.SizeType]::Percent, 70))) # Adjusted percentage
$mainContainer.Padding = New-Object System.Windows.Forms.Padding(10)
# Add mainContainer AFTER the headerPanel so it doesn't overlap
$form.Controls.Add($mainContainer)
$mainContainer.BringToFront() # Ensure it's layered correctly above the form background

# Create server list & controls panel (left side - Cell 0,0)
$leftPanel = New-Object System.Windows.Forms.Panel
$leftPanel.Dock = [System.Windows.Forms.DockStyle]::Fill
$leftPanel.Padding = New-Object System.Windows.Forms.Padding(0, 0, 10, 0) # Padding on the right
# Place leftPanel in the correct cell
$mainContainer.Controls.Add($leftPanel, 0, 0)

# Server list group
$serverGroup = New-Object System.Windows.Forms.GroupBox
$serverGroup.Text = "Servers"
$serverGroup.Dock = [System.Windows.Forms.DockStyle]::Top # Dock to top of leftPanel
$serverGroup.Height = 200 # Keep fixed height for server list
$serverGroup.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$leftPanel.Controls.Add($serverGroup)

# Server list box
$serverListBox = New-Object System.Windows.Forms.CheckedListBox
$serverListBox.Dock = [System.Windows.Forms.DockStyle]::Fill # Fill the serverGroup
$serverListBox.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$serverListBox.CheckOnClick = $true
$serverListBox.Padding = New-Object System.Windows.Forms.Padding(5) # Add padding inside listbox
$serverListBox.IntegralHeight = $false # Allows partial lines to show if needed
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
$optionsGroup.Dock = [System.Windows.Forms.DockStyle]::Fill # Fill remaining space in leftPanel below serverGroup
# *** REMOVED Height and Top properties - Dock=Fill handles this ***
$optionsGroup.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$leftPanel.Controls.Add($optionsGroup)
$optionsGroup.BringToFront() # Ensure it draws correctly after serverGroup

# Options container - Use FlowLayoutPanel for automatic checkbox layout
$optionsContainer = New-Object System.Windows.Forms.FlowLayoutPanel
$optionsContainer.Dock = [System.Windows.Forms.DockStyle]::Fill
$optionsContainer.Padding = New-Object System.Windows.Forms.Padding(10) # Padding inside the container
$optionsContainer.FlowDirection = [System.Windows.Forms.FlowDirection]::TopDown # Stack checkboxes vertically
$optionsContainer.WrapContents = $false # Don't wrap horizontally
$optionsContainer.AutoScroll = $true # Add scrollbar if checkboxes exceed space
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
$buttonContainer.BringToFront() # Ensure it's drawn over the Panel background below the ProgressBar

# Buttons with improved styling - Add directly to FlowLayoutPanel
$buttonMargin = New-Object System.Windows.Forms.Padding(5, 0, 0, 0) # L margin for spacing between buttons (since RightToLeft)

$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = 'Run Maintenance'
$runButton.Size = New-Object System.Drawing.Size(150, 30)
$runButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$runButton.BackColor = [System.Drawing.Color]::FromArgb(41, 128, 185)
$runButton.ForeColor = [System.Drawing.Color]::White
$runButton.Font = New-Object System.Drawing.Font("Segoe UI", 9, [System.Drawing.FontStyle]::Bold)
$runButton.Margin = $buttonMargin # Use defined margin
$buttonContainer.Controls.Add($runButton) # Add directly

$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Text = 'Clear Log'
$clearButton.Size = New-Object System.Drawing.Size(100, 30)
$clearButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$clearButton.BackColor = [System.Drawing.Color]::FromArgb(149, 165, 166)
$clearButton.ForeColor = [System.Drawing.Color]::White
$clearButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$clearButton.Margin = $buttonMargin # Use defined margin
$buttonContainer.Controls.Add($clearButton) # Add directly

$saveButton = New-Object System.Windows.Forms.Button
$saveButton.Text = 'Save Log'
$saveButton.Size = New-Object System.Drawing.Size(100, 30)
$saveButton.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$saveButton.BackColor = [System.Drawing.Color]::FromArgb(149, 165, 166)
$saveButton.ForeColor = [System.Drawing.Color]::White
$saveButton.Font = New-Object System.Drawing.Font("Segoe UI", 9)
$saveButton.Margin = $buttonMargin # Use defined margin
$buttonContainer.Controls.Add($saveButton) # Add directly

# Status bar
$statusStrip = New-Object System.Windows.Forms.StatusStrip
$statusStrip.BackColor = [System.Drawing.Color]::FromArgb(236, 240, 241)
# StatusStrip docks bottom by default, but explicit doesn't hurt
$statusStrip.Dock = [System.Windows.Forms.DockStyle]::Bottom
$form.Controls.Add($statusStrip)

$statusLabel = New-Object System.Windows.Forms.ToolStripStatusLabel
$statusLabel.Text = "Ready"
$statusStrip.Items.Add($statusLabel)

# Function to run SSH commands with specific user
function Run-SSHCommand {
    param (
        [string]$server,
        [string]$command,
        [string]$execUser = "root",
        [string]$connectAs = $username,
        [int]$timeout = 60
    )
   
    try {
        $sshCommand = ""
        if ($execUser -eq "root") {
            # For root commands, use dzdo directly
            $sshCommand = "ssh -o GSSAPIAuthentication=yes -o ConnectTimeout=10 ${connectAs}@${server} `"dzdo su - -c '$command'`""
        } elseif ($execUser -eq "postgres" -or $execUser -eq "enterprisedb" -or $execUser -eq "barman") {
            # For service accounts, use dzdo to switch to that user
            $sshCommand = "ssh -o GSSAPIAuthentication=yes -o ConnectTimeout=10 ${connectAs}@${server} `"dzdo su - $execUser -c '$command'`""
        } else {
            # For any other user, same pattern as service accounts
            $sshCommand = "ssh -o GSSAPIAuthentication=yes -o ConnectTimeout=10 ${connectAs}@${server} `"dzdo su - $execUser -c '$command'`""
        }
       
        # Add timeout handling for commands
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
    catch {
        return "ERROR: $_"
    }
}

# Function to update output with color coding
function Update-Output {
    param (
        [string]$message,
        [string]$type = "INFO" # INFO, SUCCESS, WARNING, ERROR
    )
   
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $fullMessage = "[$timestamp] $message"
    
    # Set color based on message type
    switch ($type) {
        "SUCCESS" { $color = [System.Drawing.Color]::FromArgb(39, 174, 96) }
        "WARNING" { $color = [System.Drawing.Color]::FromArgb(211, 84, 0) }
        "ERROR"   { $color = [System.Drawing.Color]::FromArgb(192, 57, 43) }
        default   { $color = [System.Drawing.Color]::FromArgb(44, 62, 80) }
    }
    
    # Add colored text
    $outputBox.SelectionStart = $outputBox.TextLength
    $outputBox.SelectionLength = 0
    $outputBox.SelectionColor = $color
    $outputBox.AppendText("$fullMessage`n")
    $outputBox.ScrollToCaret()
    
    # Update status bar
    $statusLabel.Text = $message
    
    # Update UI
    [System.Windows.Forms.Application]::DoEvents()
}

# Function to detect server configuration
function Detect-ServerConfig {
    param (
        [string]$server
    )
    
    Update-Output "[$server] Detecting server configuration..."
    
    # First check which database user exists: enterprisedb or postgres
    $entDbCheck = Run-SSHCommand -server $server -command "id -u enterprisedb 2>/dev/null || echo 'Not found'" -execUser "enterprisedb"
    $pgCheck = Run-SSHCommand -server $server -command "id -u postgres 2>/dev/null || echo 'Not found'" -execUser "postgres"
    
    $pgUser = ""
    if ($entDbCheck -ne "Not found" -and $entDbCheck -notmatch "ERROR") {
        $pgUser = "enterprisedb"
        Update-Output "[$server] Detected enterprisedb user"
    } elseif ($pgCheck -ne "Not found" -and $pgCheck -notmatch "ERROR") {
        $pgUser = "postgres"
        Update-Output "[$server] Detected postgres user"
    } else {
        Update-Output "[$server] ERROR: Could not detect database user (neither enterprisedb nor postgres found)" "ERROR"
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
            Update-Output "[$server] Found database path: $pgDataPath" "SUCCESS"
            break
        }
    }
    
    # If no path was found, try to check environment variable
    if ([string]::IsNullOrEmpty($pgDataPath)) {
        $envCheck = Run-SSHCommand -server $server -command "echo \$PGDATA" -execUser $pgUser
        if (-not [string]::IsNullOrEmpty($envCheck) -and $envCheck -ne '$PGDATA' -and $envCheck -notmatch "ERROR") {
            $pgDataPath = $envCheck.Trim()
            Update-Output "[$server] Found database path from PGDATA environment variable: $pgDataPath" "SUCCESS"
        }
    }
    
    # If still no path, check postmaster.pid locations
    if ([string]::IsNullOrEmpty($pgDataPath)) {
        $pidCheck = Run-SSHCommand -server $server -command "find / -name postmaster.pid -path '*/data/*' 2>/dev/null | head -1" -execUser "root"
        if (-not [string]::IsNullOrEmpty($pidCheck) -and $pidCheck -notmatch "ERROR") {
            $pgDataPath = $pidCheck.Trim() -replace "/postmaster.pid", ""
            Update-Output "[$server] Found database path from postmaster.pid: $pgDataPath" "SUCCESS"
        }
    }
    
    # Check if barman is available
    $barmanCheck = Run-SSHCommand -server $server -command "id -u barman 2>/dev/null || echo 'Not found'" -execUser "root"
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
            Update-Output "[$server] Found barman configuration for: $barmanName" "SUCCESS"
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
                Update-Output "[$server] Barman is installed but $barmanName is not configured" "WARNING"
            } else {
                Update-Output "[$server] Found barman configuration for: $barmanName" "SUCCESS"
            }
        }
    }
    
    # Return the configuration
    if ([string]::IsNullOrEmpty($pgDataPath)) {
        Update-Output "[$server] WARNING: Could not detect database data path" "WARNING"
        return $null
    }
    
    Update-Output "[$server] Configuration detected successfully" "SUCCESS"
    
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
    $processCheck = Run-SSHCommand -server $server -command "ps -ef | grep $processPattern | grep -v grep" -execUser $pgUser
    $processRunning = ($processCheck -match "postgres")
    
    # Check socket connectivity
    $socketCheck = Run-SSHCommand -server $server -command "psql -p $pgPort -c 'SELECT 1'" -execUser $pgUser
    $socketConnected = !($socketCheck -match "ERROR" -or $socketCheck -match "failed")
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
        [string]$barmanName
    )
   
    Update-Output "[$server] Checking barman status..."
    $result = Run-SSHCommand -server $server -command "barman check $barmanName" -execUser $barmanUser
   
    # Check for replication slot missing error and fix
    if ($result -match "replication slot .* doesn't exist") {
        Update-Output "[$server] Replication slot missing. Creating slot..." "WARNING"
        $createSlotResult = Run-SSHCommand -server $server -command "barman receive-wal --create-slot $barmanName" -execUser $barmanUser
        Update-Output "[$server] Create slot result: $createSlotResult"
        Start-Sleep -Seconds 5
    }
   
    # Check for receive-wal not running error and fix
    if ($result -match "receive-wal running: FAILED") {
        Update-Output "[$server] WAL receiver not running. Starting WAL receiver..." "WARNING"
        $receiveWalResult = Run-SSHCommand -server $server -command "barman receive-wal $barmanName" -execUser $barmanUser
        Update-Output "[$server] Start WAL receiver result: $receiveWalResult"
        Start-Sleep -Seconds 5
    }
   
    # Final verification
    Update-Output "[$server] Performing final barman check..."
    $finalCheck = Run-SSHCommand -server $server -command "barman check $barmanName" -execUser $barmanUser
   
    # Log the detailed results for troubleshooting
    Update-Output "[$server] Barman status details:"
    Update-Output $finalCheck
   
    if ($finalCheck -match "FAILED") {
        Update-Output "[$server] WARNING: Some barman checks still failing after fixes." "WARNING"
        return $false
    } else {
        Update-Output "[$server] All barman checks passed successfully." "SUCCESS"
        return $true
    }
}

# Function to run a complete maintenance cycle
function Start-MaintenanceCycle {
    $outputBox.Clear()
    
    # Get selected servers
    $selectedServers = @()
    for ($i = 0; $i -lt $serverListBox.Items.Count; $i++) {
        if ($serverListBox.GetItemChecked($i)) {
            $selectedServers += $serverListBox.Items[$i]
        }
    }
    
    if ($selectedServers.Count -eq 0) {
        Update-Output "No servers selected. Please select at least one server." "ERROR"
        return
    }
    
    # Get selected tasks
    $tasks = @()
    if ($chkRepoCheck.Checked) { $tasks += "Check repositories" }
    if ($chkDbStop.Checked) { $tasks += "Stop database" }
    if ($chkUpdateCheck.Checked) { $tasks += "Check for updates" }
    if ($chkUpdateApply.Checked) { $tasks += "Apply updates" }
    if ($chkReboot.Checked) { $tasks += "Reboot servers" }
    
    Update-Output "Starting maintenance on $($selectedServers.Count) server(s) with tasks: $($tasks -join ', ')" "INFO"
    
    # Calculate total steps
    $totalSteps = $selectedServers.Count * (5 + 2) # 5 standard steps + DB restart + barman check
    $currentStep = 0
    
    foreach ($server in $selectedServers) {
        # Detect server configuration
        $config = Detect-ServerConfig -server $server
        
        if ($config -eq $null) {
            Update-Output "[$server] ERROR: Failed to detect server configuration, skipping server" "ERROR"
            $currentStep += 7  # Skip all steps for this server
            $progressBar.Value = [int](($currentStep / $totalSteps) * 100)
            continue
        }
        
        $pgUser = $config.PgUser
        $pgDataPath = $config.PgDataPath
        $pgPort = "5444"  # Assuming standard port for all servers
        
        # Step 1: Check Repositories (explicitly as root)
        if ($chkRepoCheck.Checked) {
            Update-Output "[$server] Checking enabled repositories as root..."
            $result = Run-SSHCommand -server $server -command "yum repolist enabled" -execUser "root"
            if ($result -match "ERROR") {
                Update-Output "[$server] Failed to check repositories: $result" "ERROR"
            }
            else {
                Update-Output "[$server] Repository check complete." "SUCCESS"
            }
        } else {
            Update-Output "[$server] Skipping repository check (disabled in options)"
        }
        $currentStep++
        $progressBar.Value = [int](($currentStep / $totalSteps) * 100)
       
        # Step 2: Shutdown Database
        if ($chkDbStop.Checked) {
            Update-Output "[$server] Shutting down PostgreSQL database as $pgUser..."
            $result = Run-SSHCommand -server $server -command "pg_ctl -D $pgDataPath stop -m fast" -execUser $pgUser
            if ($result -match "ERROR" -or $result -match "failed") {
                Update-Output "[$server] Failed to stop database: $result" "ERROR"
            }
            else {
                Update-Output "[$server] PostgreSQL database stopped successfully." "SUCCESS"
            }
        } else {
            Update-Output "[$server] Skipping database shutdown (disabled in options)"
        }
        $currentStep++
        $progressBar.Value = [int](($currentStep / $totalSteps) * 100)
       
        # Step 3: Check Updates (as root)
        if ($chkUpdateCheck.Checked) {
            Update-Output "[$server] Checking for updates as root..."
            $result = Run-SSHCommand -server $server -command "yum check-update" -execUser "root"
            if ($result -match "ERROR") {
                Update-Output "[$server] Failed to check updates: $result" "ERROR"
            }
            else {
                Update-Output "[$server] Update check complete." "SUCCESS"
            }
        } else {
            Update-Output "[$server] Skipping update check (disabled in options)"
        }
        $currentStep++
        $progressBar.Value = [int](($currentStep / $totalSteps) * 100)
       
        # Step 4: Apply Updates (as root)
        if ($chkUpdateApply.Checked) {
            Update-Output "[$server] Applying updates as root..."
            $result = Run-SSHCommand -server $server -command "yum -y update" -execUser "root"
            if ($result -match "ERROR") {
                Update-Output "[$server] Failed to apply updates: $result" "ERROR"
            }
            else {
                Update-Output "[$server] Updates applied successfully." "SUCCESS"
            }
        } else {
            Update-Output "[$server] Skipping update application (disabled in options)"
        }
        $currentStep++
        $progressBar.Value = [int](($currentStep / $totalSteps) * 100)
       
        # Step 5: Reboot server as root
        if ($chkReboot.Checked) {
            Update-Output "[$server] Rebooting server..."
            $result = Run-SSHCommand -server $server -command "init 6" -execUser "root" -timeout 10
            Update-Output "[$server] Reboot command sent. Waiting for server to come back online..."

            # Wait for server to reboot
            $timeout = 180 # 3 minutes timeout
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
                Update-Output "[$server] Waiting for server to come back online... ($([int]$timer.Elapsed.TotalSeconds) seconds)"
            }

            if (-not $isOnline) {
                Update-Output "[$server] WARNING: Server did not come back online within timeout period" "WARNING"
            }
            else {
                Update-Output "[$server] Server is back online" "SUCCESS"
            }
        } else {
            Update-Output "[$server] Skipping server reboot (disabled in options)"
        }
        $currentStep++
        $progressBar.Value = [int](($currentStep / $totalSteps) * 100)
       
  # Step 6: Check and start PostgreSQL if needed after reboot
Update-Output "[$server] Checking if PostgreSQL is running after system reboot..."
$pgStatus = Check-PostgreSQL -server $server -pgUser $pgUser -pgDataPath $pgDataPath -pgPort $pgPort

if (-not $pgStatus.IsHealthy) {
    Update-Output "[$server] $pgUser database not running or not responding. Will start using detected data path: $pgDataPath"
    
    # If we have a socket error but the process is running, stop it first
    if ($pgStatus.ProcessRunning -and $pgStatus.SocketError) {
        Update-Output "[$server] Socket error detected. Stopping database before restart..."
        $stopResult = Run-SSHCommand -server $server -command "pg_ctl -D $pgDataPath stop -m fast" -execUser $pgUser
        Update-Output "[$server] Stop result: $stopResult"
        Start-Sleep -Seconds 5
    }
    
    # Start database using the detected user and data path
    $startCommand = 'nohup pg_ctl -D $PGDATA -l logfile start > /dev/null 2>&1 &'
    $startResult = Run-SSHCommand -server $server -command $startCommand -execUser $pgUser
    
    Update-Output "[$server] Database start initiated with command: $startCommand"
    Update-Output "[$server] Waiting for database to initialize..."
    Start-Sleep -Seconds 10
    
    # Final verification
    $pgStatus = Check-PostgreSQL -server $server -pgUser $pgUser -pgDataPath $pgDataPath -pgPort $pgPort
    
    if ($pgStatus.IsHealthy) {
        Update-Output "[$server] $pgUser database successfully started and responding." "SUCCESS"
    } else {
        Update-Output "[$server] WARNING: $pgUser database failed to start properly." "ERROR"
        
        # If still having socket issues, try waiting longer
        if ($pgStatus.ProcessRunning -and $pgStatus.SocketError) {
            Update-Output "[$server] Socket still not available. Waiting longer for socket initialization..."
            Start-Sleep -Seconds 15
            $pgStatus = Check-PostgreSQL -server $server -pgUser $pgUser -pgDataPath $pgDataPath -pgPort $pgPort
            
            if ($pgStatus.IsHealthy) {
                Update-Output "[$server] $pgUser database successfully started after extended wait." "SUCCESS"
            } else {
                # Check logs for errors
                $logCheck = Run-SSHCommand -server $server -command "tail -n 20 $pgDataPath/pg_log/startup.log" -execUser $pgUser
                Update-Output "[$server] Recent database log entries:"
                Update-Output $logCheck
            }
        } else {
            # Check logs for errors
            $logCheck = Run-SSHCommand -server $server -command "tail -n 20 $pgDataPath/pg_log/startup.log" -execUser $pgUser
            Update-Output "[$server] Recent database log entries:"
            Update-Output $logCheck
        }
    }
} else {
    Update-Output "[$server] $pgUser database is already running and accepting connections." "SUCCESS"
}

$currentStep++
$progressBar.Value = [int](($currentStep / $totalSteps) * 100)

        # Step 7: Check if barman is running properly (only if barman is available)
        if ($config.HasBarman) {
            $barmanStatus = Check-FixBarman -server $server -barmanUser $config.BarmanUser -barmanName $config.BarmanName
            Update-Output "[$server] Barman check complete." "INFO"
        } else {
            Update-Output "[$server] Barman not configured on this server, skipping barman check." "INFO"
        }
        $currentStep++
        $progressBar.Value = [int](($currentStep / $totalSteps) * 100)
    }
   
    Update-Output "Maintenance cycle completed for all selected servers." "SUCCESS"
    $statusLabel.Text = "Maintenance complete"
    $runButton.Enabled = $true
    $progressBar.Value = 100
}

# Button event handlers
$runButton.Add_Click({
    $runButton.Enabled = $false
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

# Initialize UI
Update-Output "PostgreSQL/EDB Server Maintenance Utility started" "INFO"
Update-Output "Found $($servers.Count) servers in configuration" "INFO"
Update-Output "Ready to start maintenance. Select servers and options, then click 'Run Maintenance'" "INFO"

# Show the form
$form.ShowDialog()
