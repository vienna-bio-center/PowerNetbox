function Get-NextPage {
    <#
     .SYNOPSIS
        For internal use, gets the next page of results from NetBox.
     .DESCRIPTION
        Retrieves additional pages of results from a paginated NetBox API response.
     .EXAMPLE
        PS C:\> Get-NextPage -Result $Result
        Retrieves all items from API call and returns them in $CompleteResult.
     .PARAMETER Result
        Result from previous API call.
     #>

    param (
        [Parameter(Mandatory = $true)]
        $Result
    )

    # Initialize an empty list to store the complete results
    $CompleteResult = New-Object collections.generic.list[object]

    # Add the current page's results to the complete result list
    $CompleteResult += $Result.Results

    # Continue fetching pages while there is a next page available
    if ($null -ne $result.next) {
        do {
            $Result = Invoke-RestMethod -Uri $Result.next @RestParams -Method Get
            $CompleteResult += $Result.Results
        } until ($null -eq $result.next)
    }
    return $CompleteResult
}
