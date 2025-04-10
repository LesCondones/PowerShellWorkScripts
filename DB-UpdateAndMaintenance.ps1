# Load Windows Forms and Drawing assemblies
Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

# Configuration paths
$configPath = "C:\Powershell_scripts\check_yum"
$serverListFile = "$configPath\servers.txt"
$usernameListFile = "$configPath\username.txt"

# Read configuration
$servers = Get-Content $serverListFile
$username = Get-Content $usernameListFile

# Create form
$form = New-Object System.Windows.Forms.Form
$form.Text = 'PostgreSQL Server Maintenance'
$form.Size = New-Object System.Drawing.Size(600, 500)
$form.StartPosition = 'CenterScreen'

# Output textbox
$outputBox = New-Object System.Windows.Forms.TextBox
$outputBox.Location = New-Object System.Drawing.Point(10, 50)
$outputBox.Size = New-Object System.Drawing.Size(560, 350)
$outputBox.Multiline = $true
$outputBox.ScrollBars = 'Vertical'
$outputBox.ReadOnly = $true
$form.Controls.Add($outputBox)

# Progress bar
$progressBar = New-Object System.Windows.Forms.ProgressBar
$progressBar.Location = New-Object System.Drawing.Point(10, 410)
$progressBar.Size = New-Object System.Drawing.Size(560, 20)
$form.Controls.Add($progressBar)

# Button panel
$buttonPanel = New-Object System.Windows.Forms.FlowLayoutPanel
$buttonPanel.Location = New-Object System.Drawing.Point(10, 10)
$buttonPanel.Size = New-Object System.Drawing.Size(560, 35)
$buttonPanel.FlowDirection = 'LeftToRight'
$form.Controls.Add($buttonPanel)

# Function to run SSH commands with specific user
function Run-SSHCommand {
    param (
        [string]$server,
        [string]$command,
        [string]$execUser = "root",
        [string]$connectAs = $username
    )
    
    try {
        $sshCommand = ""
        if ($execUser -eq "root") {
            $sshCommand = "ssh -o GSSAPIAuthentication=yes -o ConnectTimeout=10 ${connectAs}@${server} `"dzdo su - -c '$command'`""
        } else {
            $sshCommand = "ssh -o GSSAPIAuthentication=yes -o ConnectTimeout=10 ${connectAs}@${server} `"dzdo su - $execUser -c '$command'`""
        }
        
        $result = Invoke-Expression $sshCommand
        return $result
    }
    catch {
        return "ERROR: $_"
    }
}

# Function to update output
function Update-Output {
    param (
        [string]$message
    )
    
    $outputBox.AppendText("$message`n")
    $outputBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
}

# Function to check if PostgreSQL is running
function Check-PostgreSQL {
    param (
        [string]$server,
        [string]$pgUser = "postgres"
    )
    
    $result = Run-SSHCommand -server $server -command "pg_isready" -execUser $pgUser
    return $result -match "accepting connections"
}

#Function to Check Barman Status
function Check-FixBarman {
    param (
        [string]$server
        [string]$barmanUser = "barman"
    )
    
    Update-Output "[$server] Checking barman status..."
    $result = Run-SSHCommand -server $server -command "barman check pg" -execUser $barmanUser
    
    if ($result -match "FAILURE") {
        Update-Output "[$server] Barman check failed. Restarting WAL receiver..."
        $restartResult = Run-SSHCommand -server $server -command "barman receive-wal pg &" -execUser $barmanUser
        
        # Wait a moment for the process to start
        Start-Sleep -Seconds 5
        
        # Check barman status again
        Update-Output "[$server] Checking barman status after restart..."
        $recheckResult = Run-SSHCommand -server $server -command "barman check pg" -execUser $barmanUser
        
        if ($recheckResult -match "FAILURE") {
            Update-Output "[$server] WARNING: Barman is still reporting failures after restart"
            return $false
        }
        else {
            Update-Output "[$server] Barman is now running correctly"
            return $true
        }
    }
    else {
        Update-Output "[$server] Barman is running correctly"
        return $true
    }
}

# Function to run a complete maintenance cycle
function Start-MaintenanceCycle {
    $outputBox.Clear()
    $totalSteps = $servers.Count * 7  # Added one more step for DB restart check
    $currentStep = 0
    
    foreach ($server in $servers) {
        # Step 1: Check Repositories (explicitly as root)
        Update-Output "[$server] Checking enabled repositories as root..."
        $result = Run-SSHCommand -server $server -command "yum repolist enabled" -execUser "root"
        if ($result -match "ERROR") {
            Update-Output "[$server] Failed to check repositories: $result"
        }
        else {
            Update-Output "[$server] Repository check complete."
        }
        $currentStep++
        $progressBar.Value = [int](($currentStep / $totalSteps) * 100)
        
        # Step 2: Shutdown Database (as postgres or enterprisedb user)
        $pgUser = "postgres"  # Change to "enterprisedb" if using EDB Postgres
        Update-Output "[$server] Shutting down PostgreSQL database as $pgUser..."
        $result = Run-SSHCommand -server $server -command "ADD ACTUALLY STOP COMMAND" -execUser $pgUser
        if ($result -match "ERROR" -or $result -match "failed") {
            Update-Output "[$server] Failed to stop database: $result"
        }
        else {
            Update-Output "[$server] PostgreSQL database stopped successfully."
        }
        $currentStep++
        $progressBar.Value = [int](($currentStep / $totalSteps) * 100)
        
        # Step 3: Check Updates (as root)
        Update-Output "[$server] Checking for updates as root..."
        $result = Run-SSHCommand -server $server -command "yum check-update" -execUser "root"
        if ($result -match "ERROR") {
            Update-Output "[$server] Failed to check updates: $result"
        }
        else {
            Update-Output "[$server] Update check complete."
        }
        $currentStep++
        $progressBar.Value = [int](($currentStep / $totalSteps) * 100)
        
        # Step 4: Apply Updates (as root)
        Update-Output "[$server] Applying updates as root..."
        $result = Run-SSHCommand -server $server -command "yum -y update" -execUser "root"
        if ($result -match "ERROR") {
            Update-Output "[$server] Failed to apply updates: $result"
        }
        else {
            Update-Output "[$server] Updates applied successfully."
        }
        $currentStep++
        $progressBar.Value = [int](($currentStep / $totalSteps) * 100)

        # Step 5: Reboot
       Update-Output "[$server] Rebooting server..."
       $result = Run-SSHCommand -server $server -command "init 6" -execUser "root"
       Update-Output "[$server] Reboot command sent. Waiting for server to come back online..."
       
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
    Update-Output "[$server] Waiting for server to come back online... ($([int]$timer.Elapsed.TotalSeconds) seconds)"
}

    if (-not $isOnline) {
            Update-Output "[$server] WARNING: Server did not come back online within timeout period"
    }
        else {
                Update-Output "[$server] Server is back online"
            }
        $currentStep++
        $progressBar.Value = [int](($currentStep / $totalSteps) * 100)

        
        # Step 6: Check if database is running and start if needed
        Update-Output "[$server] Checking if PostgreSQL is running..."
        $isRunning = Check-PostgreSQL -server $server -pgUser $pgUser
        
        if (-not $isRunning) {
            Update-Output "[$server] PostgreSQL is not running. Starting database..."
            $result = Run-SSHCommand -server $server -command "ADD ACTUALL START COMMAND" -execUser $pgUser
            
            if ($result -match "ERROR" -or $result -match "failed") {
                Update-Output "[$server] Failed to start database: $result"
            }
            else {
                Update-Output "[$server] PostgreSQL database started successfully."
            }
        }
        else {
            Update-Output "[$server] PostgreSQL is already running."
        }
        $currentStep++
        $progressBar.Value = [int](($currentStep / $totalSteps) * 100)

        # Step 7: Check if Barman is running
        $barmanStatus = Check-FixBarman -server $server
        $currentStep++
        $progressBar.Value = [int](($currentStep / $totalSteps) * 100)
    }

   
    
    Update-Output "Maintenance cycle completed for all servers."
    $runButton.Enabled = $true
}

# Add buttons
$runButton = New-Object System.Windows.Forms.Button
$runButton.Text = 'Run Full Maintenance'
$runButton.Size = New-Object System.Drawing.Size(150, 30)
$runButton.Add_Click({
    $runButton.Enabled = $false
    Start-MaintenanceCycle
})
$buttonPanel.Controls.Add($runButton)

$closeButton = New-Object System.Windows.Forms.Button
$closeButton.Text = 'Close'
$closeButton.Size = New-Object System.Drawing.Size(100, 30)
$closeButton.Add_Click({ $form.Close() })
$buttonPanel.Controls.Add($closeButton)

# Show the form
$form.ShowDialog()
