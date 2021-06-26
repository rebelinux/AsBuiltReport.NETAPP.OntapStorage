<p align="center">
    <a href="https://www.asbuiltreport.com/" alt="AsBuiltReport"></a> 
            <img src='https://raw.githubusercontent.com/AsBuiltReport/AsBuiltReport/master/AsBuiltReport.png' width="8%" height="8%" /></a>
</p>
<p align="center">
    <a href="https://www.powershellgallery.com/packages/AsBuiltReport.NETAPP.OntapStorage/" alt="PowerShell Gallery Version">
        <img src="https://img.shields.io/powershellgallery/v/AsBuiltReport.NETAPP.OntapStorage.svg" /></a>
    <a href="https://www.powershellgallery.com/packages/AsBuiltReport.NETAPP.OntapStorage/" alt="PS Gallery Downloads">
        <img src="https://img.shields.io/powershellgallery/dt/AsBuiltReport.NETAPP.OntapStorage.svg" /></a>
    <a href="https://www.powershellgallery.com/packages/AsBuiltReport.NETAPP.OntapStorage/" alt="PS Platform">
        <img src="https://img.shields.io/powershellgallery/p/AsBuiltReport.NETAPP.OntapStorage.svg" /></a>
</p>
<p align="center">
    <a href="https://github.com/rebelinux/AsBuiltReport.NETAPP.OntapStorage/graphs/commit-activity" alt="GitHub Last Commit">
        <img src="https://img.shields.io/github/last-commit/rebelinux/AsBuiltReport.NETAPP.OntapStorage/master.svg" /></a>
    <a href="https://raw.githubusercontent.com/rebelinux/AsBuiltReport.NETAPP.OntapStorage/master/LICENSE" alt="GitHub License">
        <img src="https://img.shields.io/github/license/rebelinux/AsBuiltReport.NETAPP.OntapStorage.svg" /></a>
    <a href="https://github.com/rebelinux/AsBuiltReport.NETAPP.OntapStorage/graphs/contributors" alt="GitHub Contributors">
        <img src="https://img.shields.io/github/contributors/rebelinux/AsBuiltReport.NETAPP.OntapStorage.svg"/></a>
</p>
<p align="center">
    <a href="https://twitter.com/AsBuiltReport" alt="Twitter">
            <img src="https://img.shields.io/twitter/follow/AsBuiltReport.svg?style=social"/></a>
</p>

# NetApp Ontap Arrays AsBuiltReport

NetApp Ontap AsBuiltReport is a module of the parent "AsBuiltReport" [project](https://github.com/AsBuiltReport/AsBuiltReport). AsBuiltReport is a PowerShell module which generates As-Built documentation for many common datacentre infrastructure systems. Reports can be generated in Text, XML, HTML and MS Word formats and can be presented with custom styling to align with your company/customer's brand.

For detailed documentation around the whole project, please refer to the `README.md` file in the parent AsBuiltReport repository (linked to above). This README is specific only to the NetApp Ontap Array repository.

## :books: Sample Reports

### Sample Report - Custom Style 1

Sample NetApp Ontap As Built report with health checks, using custom report style.

![Sample NetApp Ontap As Built Report](https://github.com/rebelinux/AsBuiltReport.NETAPP.OntapStorage/raw/master/Samples/Sample_NetApp_Report_1.png "Sample NetApp Ontap As Built Report")

### Sample Report - Custom Style 2

Sample NetApp Ontap As Built report with health checks, using custom report style.

![Sample NetApp Ontap As Built Report](https://github.com/rebelinux/AsBuiltReport.NETAPP.OntapStorage/raw/master/Samples/Sample_NetApp_Report_2.png "Sample NetApp Ontap As Built Report")

### Sample Report - Custom Style 3

Sample NetApp Ontap As Built report with health checks, using custom report style.

![Sample NetApp Ontap As Built Report](https://github.com/rebelinux/AsBuiltReport.NETAPP.OntapStorage/raw/master/Samples/Sample_NetApp_Report_3.png "Sample NetApp Ontap As Built Report")

# :beginner: Getting Started

Below are the instructions on how to install, configure and generate a NetApp Ontap As Built Report

## :floppy_disk: Supported Versions

### **NetApp / Ontap**

The Ontap Storage As Built Report supports the following Ontap versions;

- Ontap 9.x

### **PowerShell**

This report is compatible with the following PowerShell versions;

| Windows PowerShell 5.1 | PowerShell Core | PowerShell 7 |
|:----------------------:|:---------------:|:------------:|
|   :white_check_mark:   |   :white_check_mark:    |  :x:  |

## :wrench: System Requirements

Each of the following modules will be automatically installed by following the [module installation](https://github.com/rebelinux/AsBuiltReport.NETAPP.OntapStorage#package-module-installation) procedure.

These modules may also be manually installed.

| Module Name        | Minimum Required Version |                              PS Gallery                               |                                   GitHub                                    |
|--------------------|:------------------------:|:---------------------------------------------------------------------:|:---------------------------------------------------------------------------:|
| PScribo            |          0.9.1           |      [Link](https://www.powershellgallery.com/packages/PScribo)       |         [Link](https://github.com/iainbrighton/PScribo/tree/master)         |
| AsBuiltReport.Core |          1.1.0           | [Link](https://www.powershellgallery.com/packages/AsBuiltReport.Core) | [Link](https://github.com/AsBuiltReport/AsBuiltReport.Core/releases/latest) |
| Netapp.Ontap |          9.9.1           | [Link](https://www.powershellgallery.com/packages/NetApp.ONTAP) |  |

### :package: Module Installation

Open a Windows PowerShell terminal window and install each of the required modules as follows;

```powershell
Install-Module NetApp.ONTAP
Install-Module AsBuiltReport
```

Ensure you repeat the following steps for the [system requirements](https://github.com/rebelinux/AsBuiltReport.NETAPP.OntapStorage#wrench-system-requirements) also.

1. Download the code package / [latest release](https://github.com/rebelinux/AsBuiltReport.NETAPP.OntapStorage/releases/latest) zip from GitHub
2. Extract the zip file
3. Copy the folder `AsBuiltReport.NETAPP.OntapStorage` to a path that is set in `$env:PSModulePath`.
4. Open a PowerShell terminal window and unblock the downloaded files with

    ```powershell
    $path = (Get-Module -Name AsBuiltReport.NETAPP.OntapStorage -ListAvailable).ModuleBase; Unblock-File -Path $path\*.psd1; Unblock-File -Path $path\Src\Public\*.ps1; Unblock-File -Path $path\Src\Private\*.ps1
    ```

5. Close and reopen the PowerShell terminal window.

_Note: You are not limited to installing the module to those example paths, you can add a new entry to the environment variable PSModulePath if you want to use another path._
### :closed_lock_with_key: Required Privileges

To generate a NetApp Ontap Array report, a user account with the readonly role of higher on the AFF/FAS is required.

## :pencil2: Configuration

The NetApp Ontap Array As Built Report utilises a JSON file to allow configuration of report information, options, detail and healthchecks.

A NetApp Ontap Array report configuration file can be generated by executing the following command;

```powershell
New-AsBuiltReportConfig -Report NETAPP.OntapStorage -Path <User specified folder> -Name <Optional>
```

Executing this command will copy the default Ontap report JSON configuration to a user specified folder.

All report settings can then be configured via the JSON file.

The following provides information of how to configure each schema within the report's JSON file.

<Placeholder for future - there are currently no configurable options for the NetApp Ontap Array Report>

## :computer: Examples

There is one example listed below on running the AsBuiltReport script against a NetApp Ontap Array target. Refer to the `README.md` file in the main AsBuiltReport project repository for more examples.

- The following creates a NetApp Ontap Array As-Built report in HTML & Word formats in the folder C:\scripts\.

```powershell
PS C:\>New-AsBuiltReport -Report NETAPP.OntapStorage -Target 10.10.30.20 -Credential (Get-Credential) -Format HTML,Word -OutputPath C:\scripts\
```

## :x: Known Issues
