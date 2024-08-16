function Get-IPAddress {
    <#
    .SYNOPSIS
       Retrieves an IP address from NetBox.
    .DESCRIPTION
       This function retrieves an IP address from NetBox by address, DNS name, or ID.
    .EXAMPLE
       PS C:\> Get-IPAddress -Address "192.168.1.10"
       Retrieves the IP address "192.168.1.10" from NetBox.
    .PARAMETER Address
       The IP address to retrieve.
    .PARAMETER DNSName
       The DNS name associated with the IP address.
    .PARAMETER ID
       The ID of the IP address to retrieve.
    .INPUTS
       None. This function does not accept piped input.
    .OUTPUTS
       NetBox.IP. Returns a list of IP addresses matching the criteria.
    .NOTES
       Ensure that the IP address or DNS name exists in NetBox before retrieving it.
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
        $ID
    )

    begin {
        Test-Config | Out-Null
        $URL = "/ipam/ip-addresses/"
    }

    process {
        $Query = "?"

        if ($Address) {
            $Query = $Query + "address=$($address)&"
        }

        if ($DNSName) {
            $Query = $Query + "dns_name__ic=$($DNSName)&"
        }

        if ($ID) {
            $Query = $Query + "id=$($id)&"
        }

        $Query = $Query.TrimEnd("&")

        $Result = Get-NextPage -Result $(Invoke-RestMethod -Uri $($NetboxURL + $URL + $Query) @RestParams -Method Get)

        $IPs = New-Object collections.generic.list[object]

        foreach ($Item in $Result) {
            [PSCustomObject]$IP = $item
            $IP.PSObject.TypeNames.Insert(0, "NetBox.IP")
            $IPs += $IP
        }

        return $IPs
    }
}