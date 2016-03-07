# SIS-PowerShell

A PowerShell Module for interacting with SIS Integrations in Blackboard Learn

This is still very much an early work-in-progress. Please submit issues as you find them, and (obviously, I hope) feel free to make pull requests, forks etc.

Mentioned as part of my BbWorld 2015 presentation [The SIS Framework: It's Not a Big Truck, It's a Series of Tubes!](https://speakerdeck.com/ksbarnt/the-sis-framework-its-not-a-big-truck-its-a-series-of-tubes)

## Version History

=======
## Installation

1. Clone or Download to a location of your choosing
2. Run `Install-SISPowerShell.ps1` from an Administrator PowerShell session

## Usage

Add `Import-Module SIS-PowerShell` to any scripts where you want to use the CmdLets. The `Install-SISPowerShell.ps1` script puts the module into `$env:ProgramFiles\WindowsPowerShell\Modules`, which is in the default `$env:PSModulePath` so you don't have to specify explicit paths.

For detailed help on a given CmdLet, use `Get-Help <CmdLet>` e.g. `Get-Help Get-FeedFileStatus`

## Version History

### v1.0.2

- Updated this file with version history information for hotfix v1.0.1

### v1.0.1

- Corrected typo in installation script

### v1.0

- Actually a Module Now!
- Installation Script!

### v0.2

- Addition of Send-SnapshotXMLFile.ps1

### v0.1

- Initial release to GitHub
- Includes only Send-SnapshotFlatFile.ps1 and Get-FeedFileStatus.ps1
- Not yet packaged as a module
