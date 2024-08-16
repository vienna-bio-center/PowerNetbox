function Set-Config {
    <#
    .SYNOPSIS
       Required to use PowerNetBox, sets up URL and APIToken for connection.
    .DESCRIPTION
       Sets up the necessary configuration for accessing the NetBox API by providing the NetBox URL and API token.
    .EXAMPLE
       PS C:\> Set-NetBoxConfig -NetboxURL "https://netbox.example.com" -NetboxAPIToken "1277db26a31232132327265bd13221309a567fb67bf"
       Sets up NetBox from https://netbox.example.com with APIToken 1277db26a31232132327265bd13221309a567fb67bf.
    .PARAMETER NetboxAPIToken
       APIToken to access NetBox found under "Profiles & Settings" -> "API Tokens" tab.
    .PARAMETER NetboxURL
       URL from NetBox, must be https.
    #>

    param (
        [String]
        $NetboxAPIToken,

        [String]
        [ValidatePattern ("^(https:\/\/).+")]
        $NetboxURL
    )

    # Setting up headers for API requests
    $Header = @{
        Authorization = "Token $($NetboxAPIToken)"
    }

    # Defining script-level variables for API requests
    $Script:RestParams = @{
        Headers       = $Header
        ContentType   = "application/json"
        ErrorVariable = "RestError"
    }

    # Storing the base URL of the NetBox API
    $Script:NetboxURL = $NetboxURL.TrimEnd("/")
    Set-Variable -Scope Script -Name NetboxURL
    Set-Variable -Scope Script -Name NetboxAPIToken

    # Adding /api to the URL if it is not already provided
    if ($NetboxURL -notlike "*api*" ) {
        $Script:NetboxURL = $NetboxURL + "/api"
    }
}
