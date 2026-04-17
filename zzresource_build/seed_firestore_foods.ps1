    [string]$ProjectId,
    [string]$ApiKey,
    [string]$MyfcdPath = 'assets/data/myfcd_full.json',
    [string]$SgfocosPath = 'assets/data/sgfocos_full.json',
    [int]$BatchSize = 250
)

# Load environment variables from .env if not provided
if ([string]::IsNullOrWhiteSpace($ProjectId) -or [string]::IsNullOrWhiteSpace($ApiKey)) {
    $envPath = Join-Path $PSScriptRoot "../.env"
    if (Test-Path $envPath) {
        $env = Get-Content $envPath | ConvertFrom-StringData
        if ([string]::IsNullOrWhiteSpace($ProjectId)) { $ProjectId = $env.FIREBASE_PROJECT_ID }
        if ([string]::IsNullOrWhiteSpace($ApiKey)) { $ApiKey = $env.FIREBASE_API_KEY }
    }
}

if ([string]::IsNullOrWhiteSpace($ProjectId) -or [string]::IsNullOrWhiteSpace($ApiKey)) {
    Write-Error "Missing FIREBASE_PROJECT_ID or FIREBASE_API_KEY. Provide as parameters or in .env file."
    exit 1
}

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function Convert-ToFirestoreValue {
    param([Parameter(ValueFromPipeline = $true)]$Value)

    if ($null -eq $Value) {
        return @{ nullValue = $null }
    }

    if ($Value -is [string]) {
        return @{ stringValue = $Value }
    }

    if ($Value -is [bool]) {
        return @{ booleanValue = $Value }
    }

    if ($Value -is [byte] -or $Value -is [int16] -or $Value -is [int32] -or $Value -is [int64]) {
        return @{ integerValue = [string]$Value }
    }

    if ($Value -is [single] -or $Value -is [double] -or $Value -is [decimal]) {
        return @{ doubleValue = [double]$Value }
    }

    if ($Value -is [System.Collections.IDictionary]) {
        $mapFields = @{}
        foreach ($key in $Value.Keys) {
            $mapFields[[string]$key] = Convert-ToFirestoreValue $Value[$key]
        }
        return @{ mapValue = @{ fields = $mapFields } }
    }

    if (($Value -is [System.Collections.IEnumerable]) -and -not ($Value -is [string])) {
        $vals = @()
        foreach ($item in $Value) {
            $vals += ,(Convert-ToFirestoreValue $item)
        }
        return @{ arrayValue = @{ values = $vals } }
    }

    return @{ stringValue = [string]$Value }
}

function Convert-ToFirestoreFields {
    param([Parameter(Mandatory = $true)] [System.Collections.IDictionary]$Object)

    $fields = @{}
    foreach ($k in $Object.Keys) {
        $fields[[string]$k] = Convert-ToFirestoreValue $Object[$k]
    }
    return $fields
}

function Normalize-DocId {
    param([Parameter(Mandatory = $true)][string]$RawId)

    $id = $RawId.Trim()
    if ([string]::IsNullOrWhiteSpace($id)) {
        return [guid]::NewGuid().ToString('N')
    }

    $id = $id -replace '/', '_' -replace '\\', '_' -replace '\s+', '_'
    if ($id.Length -gt 1500) {
        $id = $id.Substring(0, 1500)
    }
    return $id
}

function Read-JsonArray {
    param([Parameter(Mandatory = $true)][string]$Path)

    if (-not (Test-Path $Path)) {
        return @()
    }

    $raw = Get-Content -Raw -Path $Path
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return @()
    }

    $parsed = $raw | ConvertFrom-Json
    if ($null -eq $parsed) {
        return @()
    }
    if ($parsed -is [System.Collections.IEnumerable] -and -not ($parsed -is [string])) {
        return @($parsed)
    }

    return @($parsed)
}

$basePath = "https://firestore.googleapis.com/v1/projects/$ProjectId/databases/(default)/documents"
$commitUrl = "${basePath}:commit?key=$ApiKey"

$myfcdItems = Read-JsonArray $MyfcdPath
$sgfocosItems = Read-JsonArray $SgfocosPath
$allItems = @($myfcdItems + $sgfocosItems)
$myfcdCount = @($myfcdItems).Count
$sgfocosCount = @($sgfocosItems).Count

if ($allItems.Count -eq 0) {
    Write-Host 'No seed items found in configured JSON files.'
    exit 0
}

Write-Host "Loaded $myfcdCount MyFCD items and $sgfocosCount SGFOCOS items."

$seen = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$deduped = New-Object System.Collections.Generic.List[object]

foreach ($item in $allItems) {
    if ($null -eq $item) { continue }

    $code = [string]$item.myfcdCode
    if ([string]::IsNullOrWhiteSpace($code)) {
        $code = [string]$item.foodCode
    }
    if ([string]::IsNullOrWhiteSpace($code)) {
        $code = [string]$item.nameEn
    }

    if ([string]::IsNullOrWhiteSpace($code)) { continue }

    $key = Normalize-DocId $code
    if ($seen.Add($key)) {
        $deduped.Add([pscustomobject]@{
            id = $key
            payload = $item
        })
    }
}

Write-Host "Uploading $($deduped.Count) unique food documents..."

$total = $deduped.Count
$uploaded = 0

for ($i = 0; $i -lt $total; $i += $BatchSize) {
    $end = [Math]::Min($i + $BatchSize - 1, $total - 1)
    $chunk = $deduped[$i..$end]

    $writes = @()
    foreach ($entry in $chunk) {
        $docName = "projects/$ProjectId/databases/(default)/documents/foods/$($entry.id)"
        $payloadHashtable = @{}
        foreach ($prop in $entry.payload.PSObject.Properties) {
            $payloadHashtable[$prop.Name] = $prop.Value
        }
        $fields = Convert-ToFirestoreFields $payloadHashtable

        $writes += @{ update = @{ name = $docName; fields = $fields } }
    }

    $body = @{ writes = $writes } | ConvertTo-Json -Depth 30 -Compress
    Invoke-RestMethod -Method Post -Uri $commitUrl -ContentType 'application/json' -Body $body | Out-Null

    $uploaded += $chunk.Count
    Write-Host "Committed $uploaded / $total"
}

$documentsUrl = "$basePath/foods?pageSize=1000&key=$ApiKey"
$count = 0
$nextPageToken = $null

do {
    $url = $documentsUrl
    if ($nextPageToken) {
        $url = "$documentsUrl&pageToken=$nextPageToken"
    }

    $resp = Invoke-RestMethod -Method Get -Uri $url
    if ($resp.documents) {
        $count += @($resp.documents).Count
    }

    $nextTokenProp = $resp.PSObject.Properties['nextPageToken']
    $nextPageToken = if ($nextTokenProp) { [string]$nextTokenProp.Value } else { $null }
} while ($nextPageToken)

Write-Host "Seeding complete. Collection foods currently has $count documents."
