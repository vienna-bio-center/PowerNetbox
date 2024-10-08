#
# Module manifest for module 'PowerNetBox'
#
# Generated by: Fabian Sasse
#
# Generated on: 05.11.2021
#

@{

    # Script module or binary module file associated with this manifest.
    RootModule           = '.\PowerNetBox.psm1'

    # Version number of this module.
    ModuleVersion        = '1.0.0'

    # Supported PSEditions
    # CompatiblePSEditions = @()

    # ID used to uniquely identify this module
    GUID                 = '71bd6105-abb3-4af2-8320-8a621be8828e'

    # Author of this module
    Author               = 'Fabian Sasse'

    # Company or vendor of this module
    CompanyName          = 'Vienna BioCenter'

    # Copyright statement for this module
    Copyright            = '(c) Fabian Sasse. All rights reserved.'

    # Description of the functionality provided by this module
    # Description = ''

    # Minimum version of the PowerShell engine required by this module
    # PowerShellVersion = ''

    # Name of the PowerShell host required by this module
    # PowerShellHostName = ''

    # Minimum version of the PowerShell host required by this module
    # PowerShellHostVersion = ''

    # Minimum version of Microsoft .NET Framework required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # DotNetFrameworkVersion = ''

    # Minimum version of the common language runtime (CLR) required by this module. This prerequisite is valid for the PowerShell Desktop edition only.
    # ClrVersion = ''

    # Processor architecture (None, X86, Amd64) required by this module
    # ProcessorArchitecture = ''

    # Modules that must be imported into the global environment prior to importing this module
    # RequiredModules = @()

    # Assemblies that must be loaded prior to importing this module
    # RequiredAssemblies = @()

    # Script files (.ps1) that are run in the caller's environment prior to importing this module.
    # ScriptsToProcess = @()

    # Type files (.ps1xml) to be loaded when importing this module
    # TypesToProcess = @()

    # Format files (.ps1xml) to be loaded when importing this module
    # FormatsToProcess = @()

    # Modules to import as nested modules of the module specified in RootModule/ModuleToProcess
    # NestedModules = @()

    # Functions to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no functions to export.
    FunctionsToExport    = @(
        "Get-Cable",
        "Get-ContentType",
        "Get-CustomField",
        "Get-CustomLink",
        "Get-Device",
        "Get-DeviceRole",
        "Get-DeviceBay",
        "Get-DeviceBayTemplate",
        "Get-DeviceType",
        "Get-Interface",
        "Get-InterfaceTemplate",
        "Get-InterfaceType",
        "Get-IPAddress",
        "Get-Location",
        "Get-Manufacturer",
        "Get-NextPage",
        "Get-PowerPortTemplate",
        "Get-PowerSupplyType",
        "Get-Rack",
        "Get-RelatedObjects",
        "Get-Site",
        "Import-DeviceType",
        "New-Cable",
        "New-CustomField",
        "New-CustomLink",
        "New-Device",
        "New-DeviceRole",
        "New-DeviceBay",
        "New-DeviceBayTemplate",
        "New-DeviceType",
        "New-Interface",
        "New-InterfaceTemplate",
        "New-IPAddress",
        "New-Location",
        "New-Manufacturer",
        "New-PowerPortTemplate",
        "New-Rack",
        "New-Site",
        "Remove-Cable",
        "Remove-CustomField",
        "Remove-CustomLink",
        "Remove-Device",
        "Remove-DeviceRole",
        "Remove-DeviceType",
        "Remove-Interface",
        "Remove-IPAddress",
        "Remove-Location",
        "Remove-Manufacturer",
        "Remove-PowerPortTemplate",
        "Remove-Rack",
        "Remove-Site",
        "Set-Config",
        "Update-Device",
        "Update-DeviceBay",
        "Update-Interface",
        "Update-IPAddress",
        "Update-Rack",
        "Update-Site"
    )

    # Cmdlets to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no cmdlets to export.
    CmdletsToExport      = '*'

    # Variables to export from this module
    VariablesToExport    = '*'

    # Aliases to export from this module, for best performance, do not use wildcards and do not delete the entry, use an empty array if there are no aliases to export.
    AliasesToExport      = '*'

    # DSC resources to export from this module
    # DscResourcesToExport = @()

    # List of all modules packaged with this module
    # ModuleList = @()

    # List of all files packaged with this module
    # FileList = @()

    # Private data to pass to the module specified in RootModule/ModuleToProcess. This may also contain a PSData hashtable with additional module metadata used by PowerShell.
    PrivateData          = @{

        PSData = @{

            # Tags applied to this module. These help with module discovery in online galleries.
            # Tags = @()

            # A URL to the license for this module.
            # LicenseUri = ''

            # A URL to the main website for this project.
            ProjectUri = 'https://bitbucket.vbc.ac.at/projects/VBCOPS/repos/ps-modules/browse/PowerNetBox?at=refs%2Fheads%2FPowerNetBox'

            # A URL to an icon representing this module.
            # IconUri = ''

            # ReleaseNotes of this module
            # ReleaseNotes = ''

            # Prerelease string of this module
            # Prerelease = ''

            # Flag to indicate whether the module requires explicit user acceptance for install/update/save
            # RequireLicenseAcceptance = $false

            # External dependent modules of this module
            # ExternalModuleDependencies = @()

        } # End of PSData hashtable

    } # End of PrivateData hashtable

    # HelpInfo URI of this module
    # HelpInfoURI = ''

    # Default prefix for commands exported from this module. Override the default prefix using Import-Module -Prefix.
    DefaultCommandPrefix = 'NetBox'

}
