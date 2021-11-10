---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# Remove-NetBoxDevice

## SYNOPSIS
Deletes a device from NetBox

## SYNTAX

```
Remove-NetBoxDevice [-Name] <String> [-Recurse] [[-Confirm] <Boolean>] [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
Remove-NetBoxDevice -Name NewHost
Deletes the device NewHost from NetBox
```

## PARAMETERS

### -Name
Name of the device

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: True
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -Recurse
Deletes all related objects as well

```yaml
Type: SwitchParameter
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: False
Accept pipeline input: False
Accept wildcard characters: False
```

### -Confirm
Confirm the deletion of the device

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: True
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
