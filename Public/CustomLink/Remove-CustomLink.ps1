function Remove-CustomLink {
    <#
    .SYNOPSIS
       Removes a custom link from NetBox.
    .DESCRIPTION
       This function removes a custom link from NetBox by name or ID.
    .EXAMPLE
       PS C:\> Remove-CustomLink -ID 3
       Removes the custom link with ID 3 from NetBox.
    .PARAMETER Name
       The name of the custom link to remove.
    .PARAMETER ID
       The ID of the custom link to remove.
    .PARAMETER InputObject
       The custom link object to remove.
    .INPUTS
       NetBox.CustomLink. You can pipe a custom link object to this function.
    .OUTPUTS
       None. This function does not return a value.
    .NOTES
       Ensure that the custom link exists before attempting to remove it.
    #>

    [CmdletBinding(DefaultParameterSetName = "ByName")]
    param (
        [Parameter(Mandatory = $true, ParameterSetName = "ByName")]
        [String]
        $Name,

        [Parameter(Mandatory = $true, ParameterSetName = "ById")]
        [Int32]
        $ID,

        [Parameter(Mandatory = $false)]
        [Bool]
        $Confirm = $true,

        [Parameter(ValueFromPipeline = $true, ParameterSetName = 'ByInputObject')]
        $InputObject
    )

    begin {
        Test-Config | Out-Null
        $URL = "/extras/custom-links/"
    }

    process {
        if (-not ($InputObject.psobject.TypeNames -contains "NetBox.CustomLink")) {
            Write-Error "InputObject is not of type NetBox.CustomLink"
            break
        }

        if ($InputObject) {
            $Name = $InputObject.name
            $ID = $InputObject.Id
        }

        if ($ID) {
            $CustomLink = Get-CustomLink -Id $ID
        }
        else {
            $CustomLink = Get-CustomLink -Name $Name
        }

        $RelatedObjects = Get-RelatedObjects -Object $CustomLink -ReferenceObjects CustomLink

        if ($Confirm) {
            Show-ConfirmDialog -Object $CustomLink
        }

        # Remove all related objects
        if ($Recurse) {
            foreach ($Object in $RelatedObjects) {
                Invoke-RestMethod -Uri $Object.url @RestParams -Method Delete | Out-Null
            }
        }

        try {
            Invoke-RestMethod -Uri $($NetboxURL + $URL + $($CustomLink.ID) + "/") @RestParams -Method Delete
        }
        catch {
            if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {
                Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
                Write-Error "Delete those objects first or run again using the -recurse switch"
            }
            else {
                Write-Error "$($($($RestError.ErrorRecord) |ConvertFrom-Json).detail)"
            }
        }
    }
}