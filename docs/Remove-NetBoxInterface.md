---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# Remove-NetBoxInterface

## SYNOPSIS
Deletes an interface from netbox

## SYNTAX

### ByName (Default)
```
Remove-NetBoxInterface -Name <String> [-Recurse] [-Confirm <Boolean>] [<CommonParameters>]
```

### ByInputObject
```
Remove-NetBoxInterface [-Recurse] [-Confirm <Boolean>] [-InputObject <Object>] [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
Remove-NetBoxInterface -Id "1"
Deletes an interface with id "1"
```

## PARAMETERS

### -Name
Name of the interface

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
Confirm the deletion of the interface

```yaml
Type: Boolean
Parameter Sets: (All)
Aliases:

Required: False
Position: Named
Default value: True
Accept pipeline input: False
Accept wildcard characters: False
```

### -InputObject
interface object to delete

```yaml
Type: Object
Parameter Sets: ByInputObject
Aliases:

Required: False
Position: Named
Default value: None
Accept pipeline input: True (ByValue)
Accept wildcard characters: False
```

### CommonParameters
This cmdlet supports the common parameters: -Debug, -ErrorAction, -ErrorVariable, -InformationAction, -InformationVariable, -OutVariable, -OutBuffer, -PipelineVariable, -Verbose, -WarningAction, and -WarningVariable. For more information, see [about_CommonParameters](http://go.microsoft.com/fwlink/?LinkID=113216).

## INPUTS

### NetBox.Interface
## OUTPUTS

### Output (if any)
## NOTES
General notes

## RELATED LINKS
