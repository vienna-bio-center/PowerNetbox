---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# Get-NetBoxCustomField

## SYNOPSIS
Retrievess a custom field from NetBox

## SYNTAX

### Byname (Default)
```
Get-NetBoxCustomField [<CommonParameters>]
```

### ByName
```
Get-NetBoxCustomField -Name <String> [<CommonParameters>]
```

### ById
```
Get-NetBoxCustomField -Id <Int32> [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
Get-NetBoxCustomField -Name "ServiceCatalogID"
Retrieves custom field "ServiceCatalogID" from NetBox
```

## PARAMETERS

### -Name
Name of the custom field

```yaml
Type: String
Parameter Sets: ByName
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Id
ID of the custom field

```yaml
Type: Int32
Parameter Sets: ById
Aliases:

Required: True
Position: Named
Default value: 0
Accept pipeline input: False
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### Inputs (if any)
## OUTPUTS

### Output (if any)
## NOTES
General notes

## RELATED LINKS
