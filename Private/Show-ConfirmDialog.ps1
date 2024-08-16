function Show-ConfirmDialog {
    <#
    .SYNOPSIS
       For internal use, Shows a confirmation dialog before executing the command.
    .DESCRIPTION
       Displays a confirmation dialog with details about the object that is about to be created or modified.
    .EXAMPLE
       PS C:\> Show-ConfirmDialog -Object $NewSite
       Asks the user to confirm before creating a new site.
    .PARAMETER Object
       The object to display in the confirmation dialog.
    .INPUTS
       None
    .OUTPUTS
       None
    .NOTES
       This function is used to confirm actions that have significant impact.
    #>

    param (
        [Parameter(Mandatory = $true)]
        $Object
    )

    # Display the details of the object
    "Device Model:"
    $Object | Format-List

    # Define the dialog title and question
    $Title = "New Object Creation"
    $Question = "Are you sure you want to create this object?"

    # Define the choices for the user
    $Choices = New-Object Collections.ObjectModel.Collection[Management.Automation.Host.ChoiceDescription]
    $Choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList "&Yes"))
    $Choices.Add((New-Object Management.Automation.Host.ChoiceDescription -ArgumentList "&No"))

    # Prompt the user for their decision
    $Decision = $Host.UI.PromptForChoice($Title, $Question, $Choices, 1)
    if ($Decision -ne 0) {
        Write-Error "Canceled by User"
        break
    }
}
