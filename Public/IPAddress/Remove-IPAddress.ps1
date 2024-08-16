
function Remove-IPAddress {
    <#
    .SYNOPSIS
       Removes an IP address from NetBox.
    .DESCRIPTION
       This function removes an IP address from NetBox by address, DNS name, or ID.
    .EXAMPLE
       PS C:\> Remove-IPAddress -Address "192.168.1.10"
       Removes the IP address "192.168.1.10" from NetBox.
    .PARAMETER Address
       The IP address to remove.
    .PARAMETER DNSName
       The DNS name associated with the IP address.
    .PARAMETER ID
       The ID of the IP address to remove.
    .PARAMETER Confirm
       If specified, prompts the user for confirmation before removing the IP address.
    .INPUTS
       NetBox.IP. You can pipe an IP address object to this function.
    .OUTPUTS
       None. This function does not return a value.
    .NOTES
       Ensure that the IP address exists in NetBox before attempting to remove it.
    #>

    param (
        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [String]
        $Address,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
        [Alias("HostName")]
        [String]
        $DNSName,

        [Parameter(Mandatory = $false, ParameterSetName = "Filtered")]
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
        $URL = "/ipam/ip-addresses/"
    }

    process {
        if ($Address) {
            $IPAddress = Get-IPAddress -Address $Address
        }

        if ($ID) {
            $IPAddress = Get-IPAddress -ID $ID
        }

        if ($Confirm) {
            Show-ConfirmDialog -Object $IPAddress
        }

        try {
            Invoke-RestMethod -Uri $($NetboxURL + $URL + $($IPAddress.ID) + "/") @RestParams -Method Delete
        }
        catch {
            if ((($RestError.ErrorRecord) | ConvertFrom-Json).Detail -like "Unable to delete object*") {
                Write-Error "$($($($RestError.ErrorRecord) | ConvertFrom-Json).detail)"
                Write-Error "Delete those objects first or run again using the -recurse switch"
            }
            else {
                Write-Error "$($($($RestError.ErrorRecord) | ConvertFrom-Json).detail)"
            }
        }
    }
}