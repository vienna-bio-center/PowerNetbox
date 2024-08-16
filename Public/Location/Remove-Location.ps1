function Remove-Location {
    <#
    .SYNOPSIS
       Deletes a location in NetBox.
    .DESCRIPTION
       Removes a location from NetBox, optionally including all related objects.
    .EXAMPLE
       PS C:\> Remove-NetBoxLocation -Name "High Density"
       Deletes the location High Density.
     .PARAMETER Name
        Name of the location to delete.
     .PARAMETER ID
        ID of the location to delete.
     .PARAMETER Recurse
        Deletes all related objects as well.
     .PARAMETER Confirm
        Confirm the deletion of the location.
     .PARAMETER InputObject
        Location object to delete.
    .INPUTS
       NetBox.Location
    .OUTPUTS
       None
    .NOTES
       Deletes a location and optionally its related objects in NetBox.
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
        Test-Config | Out-Null
        $URL = "/dcim/locations/"
    }

    process {
        # Validate the InputObject type
        if (-not ($InputObject.psobject.TypeNames -contains "NetBox.Location")) {
            Write-Error "InputObject is not type NetBox.Location"
            break
        }

        # Retrieve location details based on input parameters
        if ($InputObject) {
            $Name = $InputObject.name
            $ID = $InputObject.Id
        }

        if ($ID) {
            $Location = Get-Location -Id $ID
        }
        else {
            $Location = Get-Location -Name $Name
        }

        # Get related objects to potentially delete them as well
        $RelatedObjects = Get-RelatedObjects -Object $Location -ReferenceObjects Location

        # Show confirmation dialog if required
        if ($Confirm) {
            Show-ConfirmDialog -Object $Location
        }

        # Remove all related objects if Recurse is specified
        if ($Recurse) {
            foreach ($Object in $RelatedObjects) {
                Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
            }
        }

        # Try to delete the location, handling errors appropriately
        try {
            Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Location.ID) + "/") @RestParams -Method Delete
        }
        catch {
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