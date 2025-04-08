
# Lester Artis 04/07/2025
# Certificate Information and Renewal Script
# This script retrieves certificate information and provides guidance on renewal




# Network paths and settings
$serverListPath = ""
$exportFolderPath = ""
$expirationThreshold = 60 # Days






# Function to get certificate information from a remote server
function Get-RemoteCertificateInfo {
    param(
        [string]$ComputerName,
        [System.Management.Automation.PSCredential]$Credential = $null
    )
   
    Write-Host "Getting certificate information from $ComputerName..."
   
    # Get all certificates from the local machine store
    $certs = Invoke-Command -ComputerName $ComputerName -ScriptBlock {
        $allCerts = @()
        $certStores = @("Cert:\LocalMachine\My", "Cert:\LocalMachine\WebHosting", "Cert:\LocalMachine\CA")
       
        foreach($store in $certStores) {
            if (Test-Path $store) {
                $storeCerts = Get-ChildItem -Path $store -Recurse
                foreach($cert in $storeCerts) {
                    $allCerts += [PSCustomObject]@{
                        SubjectName = $cert.Subject
                        Issuer = $cert.Issuer
                        Thumbprint = $cert.Thumbprint
                        NotBefore = $cert.NotBefore
                        NotAfter = $cert.NotAfter
                        DaysUntilExpiration = ($cert.NotAfter - (Get-Date)).Days
                        CertificatePath = $cert.PSPath
                        StoreLocation = $store
                        HasPrivateKey = $cert.HasPrivateKey
                        FriendlyName = $cert.FriendlyName
                    }
                }
            }
        }
        return $allCerts
    }
   
    return $certs
    }




# Ensure export directory exists
if (-not (Test-Path $exportFolderPath)) {
    try {
        New-Item -Path $exportFolderPath -ItemType Directory -Force | Out-Null
        Write-Host "Created export directory at $exportFolderPath" -ForegroundColor Green
    } catch {
        Write-Host "Failed to create export directory: $_" -ForegroundColor Red
        Write-Host "Will attempt to use local directory instead." -ForegroundColor Yellow
        $exportFolderPath = "C:\Temp"
        if (-not (Test-Path $exportFolderPath)) {
            New-Item -Path $exportFolderPath -ItemType Directory -Force | Out-Null
        }
    }
}


# Check if server list file exists
if (-not (Test-Path $serverListPath)) {
    Write-Host "Server list file not found at $serverListPath" -ForegroundColor Red
    Write-Host "Error: No servers to process. Please ensure the server list file exists." -ForegroundColor Red
    exit
} else {
    # Read server list from file
    try {
        $servers = Get-Content -Path $serverListPath -ErrorAction Stop |
                  Where-Object { $_ -match '\S' } |  # Filter out empty lines
                  ForEach-Object { $_.Trim() }      # Trim whitespace
       
        $serverCount = ($servers | Measure-Object).Count
       
        if ($serverCount -eq 0) {
            Write-Host "Error: No servers found in $serverListPath" -ForegroundColor Red
            exit
        } else {
            Write-Host "Found $serverCount servers in $serverListPath" -ForegroundColor Green
            Write-Host "Servers to process:"
            $servers | ForEach-Object { Write-Host "  - $_" -ForegroundColor Cyan }
        }
    } catch {
        Write-Host "Failed to read server list: $_" -ForegroundColor Red
        exit
    }
}


# Process each server
foreach ($currentServer in $servers) {
    # Get certificates from the server
    try {
        $certificates = Get-RemoteCertificateInfo -ComputerName $currentServer
       
        # Display certificate information
        Write-Host "`nCertificate Information for server: $currentServer`n" -ForegroundColor Green
        Write-Host "=" * 80
       
        # Sort by expiration date (soonest first)
        $certificates = $certificates | Sort-Object DaysUntilExpiration
       
  foreach ($cert in $certificates | Where-Object { $_.SubjectName -match "CN=.*$" }) {
     $highlightColor = if ($isHighlighted) { "Magenta" } else { "Cyan" }
           
            Write-Host "`nSubject: $($cert.SubjectName)" -ForegroundColor $highlightColor
            Write-Host "Friendly Name: $($cert.FriendlyName)"
            Write-Host "Thumbprint: $($cert.Thumbprint)"
            Write-Host "Issuer: $($cert.Issuer)"
            Write-Host "Valid From: $($cert.NotBefore)"
            Write-Host "Expires On: $($cert.NotAfter)"
            Write-Host "Days Until Expiration: $($cert.DaysUntilExpiration)" -ForegroundColor $(if($cert.DaysUntilExpiration -lt 30){"Red"} elseif($cert.DaysUntilExpiration -lt 90){"Yellow"} else{"Green"})
            Write-Host "Certificate Path: $($cert.CertificatePath)"
            Write-Host "Store Location: $($cert.StoreLocation)"
            Write-Host "Has Private Key: $($cert.HasPrivateKey)"
            Write-Host "-" * 80
        }
       
        # Export to CSV for record keeping
        $timestamp = Get-Date -Format 'yyyy-MM-dd'
        $outputPath = "$exportFolderPath\$currentServer-Certificates-$timestamp.csv"
       
        try {
            $certificates | Export-Csv -Path $outputPath -NoTypeInformation
            Write-Host "`nCertificate information exported to $outputPath" -ForegroundColor Green
        } catch {
            Write-Host "Failed to export CSV to network path: $_" -ForegroundColor Red
            # Try local backup
            $localOutputPath = "C:\Temp\$currentServer-Certificates-$timestamp.csv"
            $certificates | Export-Csv -Path $localOutputPath -NoTypeInformation
            Write-Host "Certificate information exported to local path: $localOutputPath" -ForegroundColor Yellow
        }
       
        # Check for certificates expiring within threshold
        $expiringCerts = $certificates | Where-Object { $_.DaysUntilExpiration -le $expirationThreshold -and $_.DaysUntilExpiration -gt 0 }
       
        if ($expiringCerts.Count -gt 0) {
            Write-Host "`nWARNING: Found $($expiringCerts.Count) certificates expiring within $expirationThreshold days" -ForegroundColor Red
           
           
        }
       
    } catch {
        Write-Host "Error processing server $currentServer : $_" -ForegroundColor Red
    }
}


# Display renewal instructions
Write-Host "`nCERTIFICATE RENEWAL INSTRUCTIONS:" -ForegroundColor Yellow
Write-Host "To renew a certificate with the same key, follow these steps:" -ForegroundColor Yellow
Write-Host "1. Run mmc.exe"
Write-Host "2. Click on File -> Add/Remove Snap-in"
Write-Host "3. Select 'Certificates' from the list and click 'Add'"
Write-Host "4. Select 'Computer account' and click 'Next'"
Write-Host "5. Select 'Local computer' or 'Another computer' as needed and click 'Finish'"
Write-Host "6. Click 'OK' to close the Add/Remove Snap-in dialog"
Write-Host "7. Navigate to the appropriate certificate store"
Write-Host "8. Right-click on the certificate you want to renew"
Write-Host "9. Select 'All Tasks' -> 'Advanced Operations' -> 'Renew this certificate with the same key'"


Write-Host "`nScript execution completed" -ForegroundColor Green

