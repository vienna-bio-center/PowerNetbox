---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# Get-NetBoxContentType

## SYNOPSIS
Retrieves content types from NetBox

## SYNTAX

### SingleItem (Default)
```
Get-NetBoxContentType -Name <String> [-All] [<CommonParameters>]
```

### AllItems
```
Get-NetBoxContentType [-Name <String>] [-All] [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
Get-NetBoxContentType -Name Device
Retrieves content type "Device" from NetBox
```

## PARAMETERS

### -Name
Name of the content type

```yaml
Type: String
Parameter Sets: SingleItem
Aliases:

Required: True
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: String
Parameter Sets: AllItems
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -All
Retrieves all content types from NetBox

```yaml
Type: SwitchParameter
Parameter Sets: SingleItem
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

```yaml
Type: SwitchParameter
Parameter Sets: AllItems
Aliases:

Required: True
Position: Named
Default value: False
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
