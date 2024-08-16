function Remove-DeviceType {
    <#
    .SYNOPSIS
       Deletes a device type from NetBox.
    .DESCRIPTION
       This function allows you to delete a device type from NetBox by specifying its model name or ID.
    .EXAMPLE
       PS C:\> Remove-NetboxDeviceType -Model "Cisco Catalyst 2960"
       Deletes the device type "Cisco Catalyst 2960" from NetBox.
    .PARAMETER Model
       The model name of the device type to be deleted.
    .PARAMETER Recurse
       Deletes all related objects as well.
    .PARAMETER Confirm
       Confirm the deletion of the device type.
    .PARAMETER InputObject
       The device type object to delete.
    .INPUTS
       NetBox.DeviceType object.
    .OUTPUTS
       Returns the status of the deletion.
    .NOTES
       This function interacts with the NetBox API to delete a device type.
    #>

    [CmdletBinding(DefaultParameterSetName = "ByName")]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [String]
        $Model,

        [Parameter(Mandatory = $false)]
        [Switch]
        $Recurse,

        [Parameter(Mandatory = $false)]
        [Bool]
        $Confirm = $true,

        [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByInputObject')]
        $InputObject
    )

    begin {
        # Test configuration and prepare the API endpoint URL
        Test-Config | Out-Null
        $URL = "/dcim/device-types/"
    }

    process {
        # Retrieve the device type based on input
        if ($InputObject) {
            $Model = $InputObject.Model
        }

        $DeviceType = Get-DeviceType -Model $Model

        # Fetch related objects if recurse is enabled
        $RelatedObjects = Get-RelatedObjects -Object $DeviceType -ReferenceObjects DeviceType

        # Confirm deletion if requested
        if ($Confirm) {
            Show-ConfirmDialog -Object $DeviceType
        }

        # Remove all related objects if recurse is enabled
        if ($Recurse) {
            foreach ($Object in $RelatedObjects) {
                Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
            }
        }

        try {
            # Delete the device type
            Invoke-RestMethod -Uri $($NetboxURL + $URL + $($DeviceType.ID) + "/") @RestParams -Method Delete
        }
        catch {
            if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {
                Write-Error "$($($($RestError.ErrorRecord) | ConvertFrom-Json).detail)"
                Write-Error "Delete those objects first or run again using the -Recurse switch."
            }
            else {
                Write-Error "$($($($RestError.ErrorRecord) | ConvertFrom-Json).detail)"
            }
        }
    }
}
