param(
    [string]$OutputPath = 'assets/data/sgfocos_full.json',
    [string]$BaseUrl = 'https://pphtpc.hpb.gov.sg/bff/v1/food-portal',
    [int]$DefaultPageSize = 25,
    [string]$DiscoveryQuery = 'a'
)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'

function To-Number {
    param($Value)

    if ($null -eq $Value) { return 0.0 }

    try {
        $number = [double]$Value
        if ($number -lt 0) { return 0.0 }
        return $number
    } catch {
        return 0.0
    }
}

function Get-FoodSearchPage {
    param(
        [Parameter(Mandatory = $true)][string]$SearchText,
        [Parameter(Mandatory = $true)][int]$PageNumber
    )

    $encoded = [uri]::EscapeDataString($SearchText)
    $uri = "$BaseUrl/foods?searchText=$encoded&pageNumber=$PageNumber"
    $raw = curl.exe -s $uri
    if ([string]::IsNullOrWhiteSpace($raw)) {
        return @()
    }

    return $raw | ConvertFrom-Json
}

function Get-FoodDetails {
    param([Parameter(Mandatory = $true)][string]$CrId)

    $uri = "$BaseUrl/foods/details/$CrId"
    $raw = curl.exe -s $uri
    if ([string]::IsNullOrWhiteSpace($raw)) {
        throw "Empty response for CR ID $CrId"
    }

    return $raw | ConvertFrom-Json
}

$seenCrIds = [System.Collections.Generic.HashSet[string]]::new([System.StringComparer]::OrdinalIgnoreCase)
$summaryRecords = New-Object System.Collections.Generic.List[object]

Write-Host "Collecting SGFOCOS summary records using query '$DiscoveryQuery'..."

$page = 1
$knownTotal = 0
$pageSize = $DefaultPageSize

while ($true) {
    $items = @()
    try {
        $items = @(Get-FoodSearchPage -SearchText $DiscoveryQuery -PageNumber $page)
        if ($items.Count -eq 1 -and $items[0] -is [System.Array]) {
            $items = @($items[0])
        }
    } catch {
        Write-Warning "Failed discovery query page ${page}: $($_.Exception.Message)"
        break
    }

    if ($items.Count -eq 0) {
        break
    }

    if (-not $items[0].PSObject.Properties['crId']) {
        Write-Warning "Unexpected discovery response on page ${page}; stopping summary crawl."
        break
    }

    if ($items[0].PSObject.Properties['totalCount']) {
        $knownTotal = [int]$items[0].totalCount
    }

    $pageSize = $items.Count

    foreach ($item in $items) {
        if ($null -eq $item) { continue }
        $crId = if ($item.PSObject.Properties['crId']) { [string]$item.crId } else { '' }
        if ([string]::IsNullOrWhiteSpace($crId)) { continue }

        if ($seenCrIds.Add($crId)) {
            $summaryRecords.Add($item)
        }
    }

    Write-Host "Summary crawl page $page collected unique IDs: $($seenCrIds.Count)"

    if ($knownTotal -gt 0 -and $seenCrIds.Count -ge $knownTotal) {
        break
    }

    if ($items.Count -lt $DefaultPageSize) {
        break
    }

    $page += 1
}

if ($seenCrIds.Count -eq 0) {
    Write-Error 'No SGFOCOS records discovered from API.'
    exit 1
}

Write-Host "Fetching detailed nutrients for $($seenCrIds.Count) records..."

$sgFoods = New-Object System.Collections.Generic.List[object]
$processed = 0

foreach ($summary in $summaryRecords) {
    $crId = [string]$summary.crId
    if ([string]::IsNullOrWhiteSpace($crId)) { continue }

    try {
        $detail = Get-FoodDetails -CrId $crId
    } catch {
        Write-Warning "Skipping ${crId} due to details fetch error: $($_.Exception.Message)"
        continue
    }

    if ($null -eq $detail) { continue }
    if (-not $detail.PSObject.Properties['baseFoodNutrients']) {
        Write-Warning "Skipping ${crId}: detail payload has no baseFoodNutrients."
        continue
    }

    $baseNutrients = $detail.baseFoodNutrients
    if ($null -eq $baseNutrients) { continue }

    $nameEn = [string]$detail.name
    if ([string]::IsNullOrWhiteSpace($nameEn)) {
        $nameEn = [string]$summary.name
    }
    if ([string]::IsNullOrWhiteSpace($nameEn)) { continue }

    $groupL1 = [string]$detail.l1Category
    $groupL2 = [string]$detail.l2Category
    $foodGroup = if ([string]::IsNullOrWhiteSpace($groupL2)) { $groupL1 } else { "$groupL1 > $groupL2" }

    $defaultWeight = To-Number $detail.defaultWeight
    if ($defaultWeight -le 0) { $defaultWeight = 150.0 }

    $small = [Math]::Round([Math]::Max(30.0, $defaultWeight * 0.6), 0)
    $medium = [Math]::Round($defaultWeight, 0)
    $large = [Math]::Round([Math]::Max($medium + 30.0, $defaultWeight * 1.4), 0)

    $terms = New-Object System.Collections.Generic.HashSet[string]([System.StringComparer]::OrdinalIgnoreCase)
    foreach ($piece in @($nameEn, $groupL1, $groupL2, [string]$detail.description, $crId)) {
        if ([string]::IsNullOrWhiteSpace($piece)) { continue }

        $lower = $piece.ToLowerInvariant().Trim()
        if ($lower.Length -gt 0) { [void]$terms.Add($lower) }

        foreach ($token in ($lower -split '[^a-z0-9]+')) {
            if ($token.Length -gt 1) { [void]$terms.Add($token) }
        }
    }

    $record = [ordered]@{
        myfcdCode = $crId
        foodCode = $crId
        nameEn = $nameEn
        nameMy = $nameEn
        nameEnLower = $nameEn.ToLowerInvariant()
        nameMyLower = $nameEn.ToLowerInvariant()
        searchTerms = @($terms)
        foodGroup = $foodGroup
        caloriesPer100g = To-Number $baseNutrients.energy
        proteinPer100g = To-Number $baseNutrients.protein
        carbsPer100g = To-Number $baseNutrients.carbohydrate
        fatsPer100g = To-Number $baseNutrients.fat
        sodiumPer100g = To-Number $baseNutrients.sodium
        sugarPer100g = To-Number $baseNutrients.sugar
        portionSizes = [ordered]@{
            smallGrams = $small
            mediumGrams = $medium
            largeGrams = $large
        }
        source = 'SGFOCOS_2025'
    }

    $sgFoods.Add($record)
    $processed += 1

    if (($processed % 100) -eq 0) {
        Write-Host "Processed details: $processed"
    }
}

if ($sgFoods.Count -eq 0) {
    Write-Error 'No SGFOCOS records could be transformed into output schema.'
    exit 1
}

$outputDir = Split-Path -Path $OutputPath -Parent
if (-not [string]::IsNullOrWhiteSpace($outputDir) -and -not (Test-Path $outputDir)) {
    New-Item -Path $outputDir -ItemType Directory -Force | Out-Null
}

$sgFoods | ConvertTo-Json -Depth 10 | Set-Content -Path $OutputPath -Encoding UTF8
Write-Host "Wrote $($sgFoods.Count) SGFOCOS records to $OutputPath"
