

function Remove-Rack {
    <#
    .SYNOPSIS
       Deletes a rack from NetBox.
    .DESCRIPTION
       Removes a rack from NetBox, optionally including all related objects.
    .EXAMPLE
       PS C:\> Remove-NetBoxRack -Name "Y-14"
       Deletes rack "Y-14" from NetBox.
    .PARAMETER Name
       Name of the rack to delete.
    .PARAMETER ID
       ID of the rack to delete.
     .PARAMETER Recurse
        Deletes all related objects as well.
     .PARAMETER Confirm
       Confirm the deletion of the rack.
     .PARAMETER InputObject
       Rack object to delete.
    .INPUTS
       NetBox.Rack
    .OUTPUTS
       None.
    .NOTES
       Deletes a rack and optionally its related objects in NetBox.
    #>

    [CmdletBinding(DefaultParameterSetName = "ByName")]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [String]
        $Name,

        [Parameter(Mandatory = $true, ParameterSetName = "ByID")]
        [Int32]
        $ID,

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

        # Verify configuration and initialize API endpoint
        Test-Config | Out-Null
        $URL = "/dcim/racks/"
    }

    process {
        # Ensure the input object is of the correct type
        if (-not ($InputObject.psobject.TypeNames -contains "NetBox.Rack")) {
            Write-Error "InputObject is not type NetBox.Rack"
            break
        }

        # Retrieve the rack by name or ID
        if ($InputObject) {
            $Name = $InputObject.name
            $ID = $InputObject.ID
        }

        if ($ID) {
            $Rack = Get-Rack -ID $ID
        }
        else {
            $Rack = Get-Rack -Name $Name
        }

        # Retrieve related objects to delete if the recurse option is enabled
        $RelatedObjects = Get-RelatedObjects -Object $Rack -ReferenceObjects Rack

        # Show confirmation dialog if required
        if ($Confirm) {
            Show-ConfirmDialog -Object $Rack
        }

        # Remove all related objects if recurse is enabled
        if ($Recurse) {
            foreach ($Object in $RelatedObjects) {
                Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
            }
        }

        # Delete the rack
        try {
            Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Rack.ID) + "/") @RestParams -Method Delete
        }
        catch {
            # Handle errors during deletion, especially related object issues
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