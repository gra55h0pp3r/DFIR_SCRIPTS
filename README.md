# Digital Forensic Incident Response PowerShell Scripts

The purpose of these PowerShell scripts is to be able to remotely collect forenisc information, search for files, delete files/folder, and collect files into a password protected ZIP files. All the collector scripts were written to able to be deployed via Tanium, Microsoft Defender for Endpoint (MDE) aka Microsoft 365 Portal, remotely (PSEXEC, PSSession, etc...), and by an administrator on a local system.

All PowerShell scripts are built as a one-stop shop script that have all the necessary external tools contained within a ZIP file that is base64 encoded and embedded within the script.

## NOTE ##

- All scripts work in MDE and Tanium.
- If uploaded to MDE Library, please make sure you URL Encode strings.
- Tanium automatically URL Encodes strings
  
## Contributions ##

All comments, suggestions, and recommendations are all welcome. Please open an issue with your proprosed changes, modifications, or additions. The goal is to make a one-stop script that can be easily deployed by any product or manually executed for isolated systems by an administrator.

## Credits ##

**Ebuka John Onyejegbu (Live Forensicator)** - Excellent Forensic Log Collector.

**DoD Agencies**

## LICENSE ##

These scripts are provided to the public for use without any guarantees. The only thing I ask is that you give credit where it is due though.
