function Get-MigaduMailbox {
    [CmdletBinding()]
    param (
        [Parameter(Mandatory)]$Domain,
        [Parameter(Mandatory)]$EmailAddressLocalPart,
        [Parameter(Mandatory)]$XAuthorizationToken,
        [Parameter(Mandatory)]$XAuthorizationEmail
    )

    Invoke-MigaduAPI -MethodType Get -EntityType mailboxes -EntityID $EmailAddressLocalPart -Domain $Domain -XAuthorizationToken $XAuthorizationToken -XAuthorizationEmail $XAuthorizationEmail 
}

function New-MigaduMailbox {
    param (
        [Parameter(Mandatory)]$Domain,
        [Parameter(Mandatory)]$EmailAddressLocalPart,
        [Parameter(Mandatory)]$DisplayName,
        [Parameter(Mandatory)]$Password,
        [Parameter(Mandatory)]$XAuthorizationToken,
        [Parameter(Mandatory)]$XAuthorizationEmail
    )

    $RequestParameters = [PSCustomObject]@{
        "mailbox[address]" = $EmailAddressLocalPart
        "mailbox[display_name]" = $DisplayName
        "mailbox[password]" = $Password
    }    

    Invoke-MigaduAPI -MethodType Post -EntityType mailboxes -Domain $Domain -XAuthorizationToken $XAuthorizationToken -XAuthorizationEmail $XAuthorizationEmail -Parameters $RequestParameters
}

function Remove-MigaduMailbox {
    param (
        [Parameter(Mandatory)]$Domain,
        [Parameter(Mandatory)]$EmailAddressLocalPart,
        [Parameter(Mandatory)]$XAuthorizationToken,
        [Parameter(Mandatory)]$XAuthorizationEmail
    )

    $RequestParameters = [PSCustomObject]@{
        "_method" = "delete"
    }    

    Invoke-MigaduAPI -EntityType mailboxes -EntityID $EmailAddressLocalPart -Domain $Domain -XAuthorizationToken $XAuthorizationToken -XAuthorizationEmail $XAuthorizationEmail -Parameters $RequestParameters
}

function Invoke-MigaduAPILogin {
    
}

function Get-MigaduAPIURI {
    param (
        [Parameter(Mandatory)]$Domain,
        [Parameter(Mandatory)]$EntityType,
        $EntityID
    )
    if ($EntityID ) {
        "https://manage.migadu.com/api/public/domains/$Domain/$EntityType/$EntityID"
    } else {
        "https://manage.migadu.com/api/public/domains/$Domain/$EntityType"
    }
}

function Invoke-MigaduAPI {
    [CmdletBinding()]
    param (
        $Domain,
        $EntityType,
        $EntityID,
        $XAuthorizationToken,
        $XAuthorizationEmail,
        [ValidateSet("Get","Post")]$MethodType,
        $Parameters
    )
    $URI = Get-MigaduAPIURI -Domain $Domain -EntityType $EntityType -EntityID $EntityID

    if ($MethodType -eq "Post") {
        $Guid = New-Guid
        $Boundary = $Guid.ToString()
        $Body = $Parameters | ConvertTo-MultiPartFormData -Boundary $Boundary

        Invoke-RestMethod -Method Post -Uri $URI -Headers @{
            "X-Authorization-Token" = $XAuthorizationToken
            "X-Authorization-Email" = $XAuthorizationEmail
        } -ContentType "multipart/form-data; boundary=$Boundary" -Body $Body
    } elseif ($MethodType -eq "Get") {
        Invoke-RestMethod -Method Get -Uri $URI -Headers @{
            "X-Authorization-Token" = $XAuthorizationToken
            "X-Authorization-Email" = $XAuthorizationEmail
        }
    }
}

function ConvertTo-MultiPartFormData {
    param (
        [Parameter(Mandatory,ValueFromPipeline)]$Object,
        [Parameter(Mandatory)]$Boundary
    )
    process {
        $HashTable = $Object | ConvertTo-HashTable
        $Parameters = @()
        ForEach ($Key in $HashTable.Keys) {
            $Parameters += [PSCustomObject]@{ 
                Name = $Key
                Value = $HashTable[$Key]
            }            
        }
        $Parameters | New-MultiPartFormData -Boundary $Boundary
    }
}

function New-MultiPartFormData {
    param (
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$Name,
        [Parameter(Mandatory,ValueFromPipelineByPropertyName)]$Value,
        [Parameter(Mandatory)]$Boundary
    )
    begin {
    }
    process {
$Text += @"
--$Boundary
Content-Disposition: form-data; name="$Name"

$Value

"@
    }
    end {
        $Text += "--$Boundary--"
        $Text
    }
}