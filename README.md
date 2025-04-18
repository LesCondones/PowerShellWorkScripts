# Work Scripts
Scripts I have created for making life at work easier.

PowerShell & Bash Scripts I create for essential job functions can be found here.

# Certificate Information and Renewal Script

## Description

This PowerShell script retrieves and manages SSL/TLS certificates across multiple servers. Key functionalities include:

- Scanning multiple certificate stores (LocalMachine, WebHosting, CA)
- Identifying expiring certificates based on configurable thresholds
- Exporting certificate data to CSV for record-keeping
- Providing step-by-step renewal instructions for expired certificates
- Color-coded output to highlight certificates needing attention
- Robust error handling with fallback paths for exports

# SQL Server Monitoring and Job Status Script

## Description

This comprehensive PowerShell script monitors SQL Server instances across your infrastructure. Key functionalities include:

- Job status monitoring (success/failure detection with detailed failure analysis)
- Backup verification and reporting (missing/outdated backup detection)
- Disk space monitoring with configurable warning thresholds
- Automatic emergency cleanup for critically low disk space conditions
- SQL Server connection testing with version detection
- Cleanup of old backup files based on retention policies
- Detailed logging of all operations with timestamps
- Cross-instance compatible (works with default and named instances)

# DB-UpdateAndMaintenance

## Description

DB-UpdateAndMaintenance is a PowerShell utility with a graphical interface designed to automate routine maintenance tasks on PostgreSQL and EnterpriseDB database servers. The script intelligently detects server configurations and handles maintenance operations including:

- Repository validation
- Database service shutdown and restart
- System update checks and application
- Server reboots with connectivity verification
- PostgreSQL/EDB service health monitoring
- Barman replication monitoring and repair

The utility features auto-detection of database types (PostgreSQL/EnterpriseDB), supports various data directory configurations, and provides detailed logging of all operations. It allows administrators to select specific servers and maintenance tasks through an intuitive interface, streamlining the maintenance process and reducing potential for human error.

