---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# Remove-NetBoxRack

## SYNOPSIS
Deletes a rack from NetBox

## SYNTAX

### ByName (Default)
```
Remove-NetBoxRack -Name <String> [-Recurse] [-Confirm <Boolean>] [<CommonParameters>]
```

### ByInputObject
```
Remove-NetBoxRack [-Recurse] [-Confirm <Boolean>] [-InputObject <Object>] [<CommonParameters>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
Remove-NetBoxRack -Name "Y-14"
Deletes rack "Y-14" in NetBox
```

## PARAMETERS

### -Name
Name of the rack

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
Confirm the deletion of the rack

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
Rack object to delete

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

### NetBox.Rack
## OUTPUTS

### Output (if any)
## NOTES
General notes

## RELATED LINKS
