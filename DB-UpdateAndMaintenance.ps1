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

# Function to update output
function Update-Output {
    param (
        [string]$message
    )
    
    $outputBox.AppendText("$message`n")
    $outputBox.ScrollToCaret()
    [System.Windows.Forms.Application]::DoEvents()
# Function to run a complete maintenance cycle
function Start-MaintenanceCycle {
    $outputBox.Clear()
    $totalSteps = $servers.Count * 7  # Updated for 7 steps per server
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
        $pgPort = "5444"      # The port from the error message
        $pgDataDir = "/var/lib/edb/as14/data"  # Default EDB data directory, adjust as needed
        
        Update-Output "[$server] Shutting down PostgreSQL database as $pgUser..."
        $result = Run-SSHCommand -server $server -command "pg_ctl stop -D $pgDataDir -m fast" -execUser $pgUser
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
        
        # Step 5: Reboot server as root
        Update-Output "[$server] Rebooting server..."
        $result = Run-SSHCommand -server $server -command "init 6" -execUser "root" -timeout 10
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
        
        # Step 6: Check and ensure PostgreSQL is running correctly
        Update-Output "[$server] Checking if PostgreSQL is running..."

        # Check if PostgreSQL process is running
        $processCheck = Run-SSHCommand -server $server -command "ps -ef | grep postgres | grep -v grep" -execUser $pgUser
        if (-not ($processCheck -match "postgres")) {
            Update-Output "[$server] PostgreSQL process not found. Attempting to start..."
            
            # Start PostgreSQL with specific data directory
            $startResult = Run-SSHCommand -server $server -command "pg_ctl start -D $pgDataDir" -execUser $pgUser
            Update-Output "[$server] PostgreSQL start attempt result: $startResult"
            
            # Wait for PostgreSQL to initialize
            Start-Sleep -Seconds 10
        } else {
            Update-Output "[$server] PostgreSQL process is running. Checking socket connectivity..."
        }

        # Verify PostgreSQL is responding on the socket
        $socketCheck = Run-SSHCommand -server $server -command "psql -p $pgPort -c 'SELECT 1'" -execUser $pgUser

        if ($socketCheck -match "ERROR" -or $socketCheck -match "failed") {
            Update-Output "[$server] Socket connection failed. Attempting to restart PostgreSQL..."
            
            # Attempt to stop PostgreSQL gracefully first
            $stopResult = Run-SSHCommand -server $server -command "pg_ctl stop -D $pgDataDir -m fast" -execUser $pgUser
            Update-Output "[$server] PostgreSQL stop attempt: $stopResult"
            Start-Sleep -Seconds 5
            
            # Start PostgreSQL again
            $startResult = Run-SSHCommand -server $server -command "pg_ctl start -D $pgDataDir" -execUser $pgUser
            Update-Output "[$server] PostgreSQL restart attempt: $startResult"
            Start-Sleep -Seconds 10
            
            # Final verification
            $finalCheck = Run-SSHCommand -server $server -command "psql -p $pgPort -c 'SELECT version()'" -execUser $pgUser
            
            if ($finalCheck -match "PostgreSQL") {
                Update-Output "[$server] PostgreSQL successfully restarted and responding."
            } else {
                Update-Output "[$server] WARNING: PostgreSQL still not responding after restart attempts."
                # Check logs for errors
                $logCheck = Run-SSHCommand -server $server -command "tail -n 20 $pgDataDir/pg_log/postgresql-*.log" -execUser $pgUser
                Update-Output "[$server] Recent PostgreSQL log entries:"
                Update-Output $logCheck
            }
        } else {
            Update-Output "[$server] PostgreSQL is running and accepting connections."
        }
        $currentStep++
        $progressBar.Value = [int](($currentStep / $totalSteps) * 100)
        
        # Step 7: Check if barman is running properly
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
$form.ShowDialog(
