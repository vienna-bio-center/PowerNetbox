function Remove-Site {
    <#
     .SYNOPSIS
        Deletes a site in NetBox.
     .DESCRIPTION
        Removes a site from NetBox, optionally including all related objects.
     .EXAMPLE
        PS C:\> Remove-NetBoxSite -Name vbc -Recurse
        Deletes a site vbc and all related objects.
     .PARAMETER Name
        Name of the site to delete.
     .PARAMETER ID
        ID of the site to delete.
     .PARAMETER Recurse
        Deletes all related objects as well.
     .PARAMETER Confirm
        Confirm the deletion of the site.
     .PARAMETER InputObject
        Site object to delete.
     .INPUTS
        NetBox.Site
     .OUTPUTS
        None
     .NOTES
        Deletes a site and optionally its related objects in NetBox.
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
        $URL = "/dcim/sites/"
    }

    process {
        # Validate the InputObject type
        if (-not ($InputObject.psobject.TypeNames -contains "NetBox.Site")) {
            Write-Error "InputObject is not type NetBox.Site"
            break
        }

        # Retrieve site details based on input parameters
        if ($InputObject) {
            $Name = $InputObject.name
            $ID = $InputObject.Id
        }

        if ($ID) {
            $Site = Get-Site -ID $ID
        }
        else {
            $Site = Get-Site -Name $Name
        }

        # Get related objects to potentially delete them as well
        $RelatedObjects = Get-RelatedObjects -Object $Site -ReferenceObjects Site

        # Show confirmation dialog if required
        if ($Confirm) {
            Show-ConfirmDialog -Object $Site
        }

        # Remove all related objects if Recurse is specified
        if ($Recurse) {
            foreach ($Object in $RelatedObjects) {
                Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
            }
        }

        # Try to delete the site, handling errors appropriately
        try {
            Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Site.ID) + "/") @RestParams -Method Delete
        }
        catch {
            if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {
                Write-Error "$($($($RestError.ErrorRecord) | ConvertFrom-Json).detail)"
                Write-Error "Delete those objects first or run again using -recurse switch"
            }
            else {
                Write-Error "$($($($RestError.ErrorRecord) | ConvertFrom-Json).detail)"
            }

        }
    }
}
