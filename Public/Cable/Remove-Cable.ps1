function Remove-Cable {
    <#
    .SYNOPSIS
       Deletes a cable from NetBox.
    .DESCRIPTION
       This function deletes a cable from NetBox using the specified parameters.
    .EXAMPLE
       PS C:\> Remove-Cable -Label "Important Cable"
       Deletes the cable with the label "Important Cable".
    .PARAMETER Label
       The label of the cable to delete.
    .PARAMETER ID
       The ID of the cable to delete.
    .PARAMETER Confirm
       If specified, prompts the user for confirmation before deleting the cable.
    .INPUTS
       NetBox.Cable
    .OUTPUTS
       None.
    .NOTES
       Ensure that the cable specified exists in NetBox.
    #>

    param (
        [Parameter(Mandatory = $True)]
        [String]
        $Label,

        [Parameter(Mandatory = $false)]
        [String]
        $ID,

        [Parameter(Mandatory = $false)]
        [Bool]
        $Confirm = $true,

        [Parameter(Mandatory = $false)]
        [Switch]
        $Force
    )

    begin {
        Test-Config | Out-Null
        $URL = "/dcim/cables/"
    }

    process {
        if ($Label) {
            $Cable = Get-Cable -Label $Label
        }
        elseif ($ID) {
            $Cable = Get-Cable -ID $ID
        }
        else {
            Write-Error "Either -Label or -ID must be specified"
        }

        if ($Confirm) {
            Show-ConfirmDialog -Object $Cable
        }

        try {
            Invoke-RestMethod -Uri $($NetboxURL + $URL + $($Cable.ID) + "/") @RestParams -Method Delete
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
