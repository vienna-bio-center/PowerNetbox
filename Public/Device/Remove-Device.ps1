

function Remove-Device {
    <#
    .SYNOPSIS
       Deletes a device from NetBox.
    .DESCRIPTION
       This function deletes a device and optionally all related objects from NetBox.
    .EXAMPLE
       PS C:\> Remove-NetBoxDevice -Name NewHost
       Deletes the device "NewHost" from NetBox.
    .PARAMETER Name
       The name of the device to delete.
    .PARAMETER Recurse
       Deletes all related objects as well.
    .PARAMETER Confirm
       Confirms the deletion of the device.
     .PARAMETER InputObject
       The device object to delete.
    .INPUTS
       None. You cannot pipe objects to this function.
    .OUTPUTS
       None.
    .NOTES
       This function interacts with the NetBox API to delete a device.
    #>

    [CmdletBinding(DefaultParameterSetName = "ByName")]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [String]
        $Name,

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
        $URL = "/dcim/devices/"
    }

    process {
        # If the device object is provided through the pipeline, extract the name
        if ($InputObject) {
            $Name = $InputObject.name
        }

        # Retrieve the device information
        $Device = Get-Device -Name $Name

        # Retrieve related objects if the recurse option is selected
        $RelatedObjects = Get-RelatedObjects -Object $Device -ReferenceObjects Device

        # Confirm the deletion if required
        if ($Confirm) {
            Show-ConfirmDialog -Object $Device
        }

        # Delete related objects if the recurse option is selected
        if ($Recurse) {
            foreach ($Object in $RelatedObjects) {
                Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
            }
        }

        try {
            # Delete the device from NetBox
            Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Device.ID) + "/") @RestParams -Method Delete
        }
        catch {
            # Handle specific errors, such as dependencies that must be deleted first
            if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {
                Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
                Write-Error "Delete those objects first or run again using -recurse switch"
            }
            else {
                Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
            }
        }
    }
}