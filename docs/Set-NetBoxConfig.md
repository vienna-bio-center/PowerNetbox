---
external help file: PowerNetBox-help.xml
Module Name: PowerNetBox
online version:
schema: 2.0.0
---

# Set-NetBoxConfig

## SYNOPSIS
Required to use PowerNetBox, sets up URL and APIToken for connection

## SYNTAX

```
Set-NetBoxConfig [[-NetboxAPIToken] <String>] [[-NetboxURL] <String>]
```

## DESCRIPTION
Long description

## EXAMPLES

### EXAMPLE 1
```
Set-NetBoxConfig -NetboxURL "https://netbox.example.com" -NetboxAPIToken "1277db26a31232132327265bd13221309a567fb67bf"
Sets up NetBox from https://netbox.example.com with APIToken 1277db26a31232132327265bd13221309a567fb67bf
```

## PARAMETERS

### -NetboxAPIToken
APIToken to access NetBox found under "Profiles & Settings" -\> "API Tokens" tab

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 1
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

### -NetboxURL
URL from Netbox, must be https

```yaml
Type: String
Parameter Sets: (All)
Aliases:

Required: False
Position: 2
Default value: None
Accept pipeline input: False
Accept wildcard characters: False
```

## INPUTS

## OUTPUTS

## NOTES

## RELATED LINKS
