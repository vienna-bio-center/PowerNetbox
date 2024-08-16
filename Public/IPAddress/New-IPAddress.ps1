function New-IPAddress {
    <#
    .SYNOPSIS
       Creates a new IP address in NetBox.
    .DESCRIPTION
       This function creates a new IP address in NetBox using the provided address and subnet.
    .EXAMPLE
       PS C:\> New-IPAddress -Address "192.168.1.10" -Subnet "24"
       Creates a new IP address "192.168.1.10" with a subnet mask of "24".
    .PARAMETER Address
       The IP address to create.
    .PARAMETER Subnet
       The subnet mask for the IP address.
    .PARAMETER DNSName
       The DNS name associated with the IP address.
    .PARAMETER Status
       The status of the IP address (e.g., "active", "planned").
    .INPUTS
       None. This function does not accept piped input.
    .OUTPUTS
       NetBox.IP. Returns the created IP address.
    .NOTES
       Ensure that the subnet and DNS name (if provided) are valid before creating the IP address.
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
            if (Get-IPAddress -Address $Address) {
                Write-Warning "IP Address $Address already exists"
                $Exists = $true
            }
        }

        $Body = @{
            address  = "$Address/$Subnet"
            status   = $Status
            dns_name = $DNSName
        }

        if ($CustomFields) {
            $Body.custom_fields = @{}
            foreach ($Key in $CustomFields.Keys) {
                $Body.custom_fields.add($Key, $CustomFields[$Key])
            }
        }

        # Remove empty keys
       ($Body.GetEnumerator() | Where-Object { -not $_.Value }) | ForEach-Object { $Body.Remove($_.Name) }

        if ($Confirm) {
            $OutPutObject = [pscustomobject]$Body
            Show-ConfirmDialog -Object $OutPutObject
        }

        if (-Not $Exists) {
            $IPAddress = Invoke-RestMethod -Uri $($NetboxURL + $URL) @RestParams -Method Post -Body $($Body | ConvertTo-Json)
            $IPAddress.PSObject.TypeNames.Insert(0, "NetBox.IP")
            return $IPAddress
        }
        else {
            return
        }
    }
}