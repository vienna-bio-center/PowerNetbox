function Test-Config {
    <#
    .SYNOPSIS
       For internal use, checks if NetBox URL and APIToken are set.
    .DESCRIPTION
       Ensures that both the NetBox URL and API token have been configured before executing other functions.
    .EXAMPLE
       PS C:\> Test-Config | Out-Null
       Verifies that the necessary configuration has been set up.
    #>

    # Check if NetboxURL and NetboxAPIToken are set, otherwise return an error
    if (-not $(Get-Variable -Name NetboxURL) -or -not $(Get-Variable -Name NetboxAPIToken) ) {
        Write-Error "NetboxAPIToken and NetboxURL must be set before calling this function"
        break
    }
}