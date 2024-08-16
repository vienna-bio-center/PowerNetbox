function Update-IPAddress {
    <#
    .SYNOPSIS
       Updates an existing IP address in NetBox.
    .DESCRIPTION
       This function updates an existing IP address in NetBox with new details provided by the user.
    .EXAMPLE
       PS C:\> Update-IPAddress -Address "192.168.1.10" -DNSName "server1.example.com"
       Updates the IP address "192.168.1.10" to associate it with "server1.example.com".
    .PARAMETER Address
       The IP address to update.
    .PARAMETER Subnet
       The subnet mask for the IP address.
    .PARAMETER DNSName
       The DNS name associated with the IP address.
    .PARAMETER Status
       The status of the IP address (e.g., "active", "planned").
    .INPUTS
       None. This function does not accept piped input.
    .OUTPUTS
       NetBox.IP. Returns the updated IP address.
    .NOTES
       Ensure that the IP address and DNS name (if provided) are valid before updating the IP address.
    #>

    param (
        [Parameter(Mandatory = $True)]
        [String]
        $Address,

        [Parameter(Mandatory = $True)]
        [String]
        $Subnet,

        [Parameter(Mandatory = $false)]
        [Alias("HostName")]
        [String]
        $DNSName,

        [Parameter(Mandatory = $false)]
        [ValidateSet("offline", "active", "planned", "staged", "failed", "inventory", "decommissioning")]
        [String]
        $Status = "active"
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

        $Body = @{
            address  = "$Address/$Subnet"
            status   = $Status
            dns_name = $DNSName
        }

        # Remove empty keys
       ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

        if ($Confirm) {
            $OutPutObject = [pscustomobject]$Body
            Show-ConfirmDialog -Object $OutPutObject
        }

        Invoke-RestMethod -Uri $($NetboxURL + $URL + $($IPAddress.ID) + "/") @RestParams -Method Patch -Body $($Body | ConvertTo-Json)
    }
}