function Import-DeviceType {
    <#
    .SYNOPSIS
       Imports device types from a YAML file into NetBox.
    .DESCRIPTION
       This function reads YAML files containing device type definitions and imports them into NetBox. It creates the device type, interfaces, power ports, and device bays as specified in the YAML file.
    .EXAMPLE
       PS C:\> Import-DeviceType -Path "C:\device-types\"
       Imports all YAML files from the specified directory into NetBox.
    .PARAMETER Path
       The file path to the directory containing YAML files to import.
    .INPUTS
       None. You cannot pipe objects to this function.
    .OUTPUTS
       Returns the imported device type objects.
    .NOTES
       This function requires the presence of YAML files formatted according to the NetBox device type schema.
    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [String]
        [Alias("YamlFile")]
        $Path
    )

    # Get all files in the specified path
    $Files = Get-ChildItem -Path $Path

    foreach ($DeviceFile in $Files) {
        # Convert YAML content to PowerShell object
        $DeviceType = Get-Content $DeviceFile.FullName | ConvertFrom-Yaml

        # Log the device type details
        Write-Verbose $($DeviceType | Format-Table | Out-String)
        Write-Verbose $($DeviceType.Interfaces | Format-Table | Out-String)

        # Create manufacturer if it doesn't exist
        New-Manufacturer -Name $DeviceType.Manufacturer -Confirm $false | Out-Null

        # Build parameters for creating a new device type
        $NewDeviceTypeParams = @{
            ManufacturerName = $DeviceType.Manufacturer
            Model            = $DeviceType.Model
            Confirm          = $false
        }

        # Optional parameters based on YAML content
        if ($DeviceType.u_height) {
            $NewDeviceTypeParams["Height"] = $DeviceType.u_height
        }
        if ($DeviceType.is_full_depth) {
            $NewDeviceTypeParams["FullDepth"] = $DeviceType.is_full_depth
        }
        if ($DeviceType.subdevice_role) {
            $NewDeviceTypeParams["SubDeviceRole"] = $DeviceType.subdevice_role
        }
        if ($DeviceType.part_number) {
            $NewDeviceTypeParams["PartNumber"] = $DeviceType.part_number
        }
        if ($DeviceType.slug) {
            $NewDeviceTypeParams["Slug"] = $DeviceType.slug
        }
        if ($DeviceType."device-bays") {
            $NewDeviceTypeParams["DeviceBays"] = $DeviceType."device-bays"
        }

        # Log the new device type parameters
        Write-Verbose $($NewDeviceTypeParams | Format-Table | Out-String)

        # Create the new device type in NetBox
        $NewDeviceType = New-DeviceType @NewDeviceTypeParams -Confirm $false | Out-Null

        # Retrieve the device type if it wasn't created (e.g., it already exists)
        if ($null -eq $NewDeviceType) {
            $NewDeviceType = Get-NetBoxDeviceType -Model $DeviceType.Model -Manufacturer $DeviceType.Manufacturer
        }

        # Create interfaces based on YAML content
        foreach ($Interface in $DeviceType.interfaces) {
            Write-Verbose "Creating Interfaces"
            New-InterfaceTemplate -Name $Interface.Name -Type $Interface.Type -ManagementOnly $([System.Convert]::ToBoolean($Interface.mgmt_only)) -DeviceTypeID $NewDeviceType.ID -Confirm $false | Out-Null
        }

        # Create power ports based on YAML content
        foreach ($PSU in $DeviceType."power-ports") {
            Write-Verbose "Creating PSUs"
            New-PowerPortTemplate -Name $PSU.Name -Type $PSU.Type -DeviceTypeID $NewDeviceType.ID -Confirm $false | Out-Null
        }

        # Create device bays based on YAML content
        foreach ($DeviceBay in $DeviceType."device-bays") {
            Write-Verbose "Creating Device Bays"
            New-DeviceBayTemplate -Name $DeviceBay.Name -DeviceTypeID $NewDeviceType.ID -Confirm $false | Out-Null
        }
    }
}