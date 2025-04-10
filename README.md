# PowerShellWorkScripts
Scripts I have created for making life at work easier.

PowerShell & Bash Scripts I create for essential job functions can be found here.

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

