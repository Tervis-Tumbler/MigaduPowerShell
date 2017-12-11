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

    Invoke-MigaduAPI -EntityType mailboxes -Domain $Domain -XAuthorizationToken $XAuthorizationToken -XAuthorizationEmail $XAuthorizationEmail -Parameters $RequestParameters
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
    param (
        $Domain,
        $EntityType,
        $EntityID,
        $XAuthorizationToken,
        $XAuthorizationEmail,
        $_migadu_key,
        $LastUser,
        $Parameters
    )    
    $Guid = New-Guid
    $Boundary = $Guid.ToString()
    $Body = $Parameters | ConvertTo-MultiPartFormData -Boundary $Boundary

    $Session = New-Object Microsoft.PowerShell.Commands.WebRequestSession    

    $URI = Get-MigaduAPIURI -Domain $Domain -EntityType $EntityType -EntityID $EntityID

    Invoke-WebRequest -Method Post -Uri $URI -Headers @{
        "X-Authorization-Token" = $XAuthorizationToken
        "X-Authorization-Email" = $XAuthorizationEmail
    } -ContentType "multipart/form-data; boundary=$Boundary" -WebSession $Session -Body $Body
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