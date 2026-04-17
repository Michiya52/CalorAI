$ErrorActionPreference = 'Stop'

function Get-MyfcdList($module, $listMode) {
  if ($listMode -eq 'industry') {
    $uri = "https://myfcd.moh.gov.my/$module/static/DataTables-1.10.12/examples/server_side/scripts/server_processing.php"
    $body = @{
      'postData[start]' = '0'
      'postData[length]' = '-1'
      'postData[my_food_group]' = '0'
      'postData[my_manufacturer]' = '0'
    }
    $resp = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType 'application/x-www-form-urlencoded'
  } else {
    $uri = "https://myfcd.moh.gov.my/$module/index.php/ajax/datatable_data"
    $body = @{ postData = @{ start = 0; length = -1; my_food_group = 0; my_manufacturer = 0 } } | ConvertTo-Json -Depth 5
    $resp = Invoke-RestMethod -Uri $uri -Method Post -Body $body -ContentType 'application/json'
  }

  $rows = @()
  foreach ($d in $resp.data) {
    $vals = $null
    if ($d -is [System.Array]) {
      $vals = $d
    } elseif ($null -ne $d -and $d.PSObject.Properties.Name -contains 'value') {
      $vals = $d.value
    }
    if ($null -eq $vals -or $vals.Count -lt 3) {
      continue
    }
    $rows += [pscustomobject]@{
      id = [string]$vals[0]
      nameEn = [string]$vals[1]
      foodGroupCode = [string]$vals[2]
      module = $module
    }
  }
  return $rows
}

function Get-MyfcdNutrientsFromDetailPage($module, $id) {
  $uri = "https://myfcd.moh.gov.my/$module/index.php/site/detail_product/$id/0/10/-1/0/0/"
  $html = (Invoke-WebRequest -UseBasicParsing -Uri $uri).Content
  $match = [regex]::Match(
    $html,
    'var\s+product_nutrients\s*=\s*(\{.*?\}|\[.*?\])\s*;',
    [System.Text.RegularExpressions.RegexOptions]::Singleline
  )
  if (-not $match.Success) {
    return $null
  }

  return ($match.Groups[1].Value | ConvertFrom-Json)
}

function Get-NutrientValue($nutrients, $name) {
  if ($null -eq $nutrients) {
    return $null
  }

  if ($nutrients -is [System.Array]) {
    foreach ($item in $nutrients) {
      if ($null -ne $item -and $item.name -eq $name) {
        $parsedArray = 0.0
        if ([double]::TryParse([string]$item.value, [ref]$parsedArray)) {
          return $parsedArray
        }
      }
    }
    return $null
  }

  if ($nutrients.PSObject.Properties.Name -contains $name) {
    $raw = $nutrients.$name.value
    $parsedObject = 0.0
    if ([double]::TryParse([string]$raw, [ref]$parsedObject)) {
      return $parsedObject
    }
  }

  return $null
}

$all = @()
$sources = @(
  @{ module = 'myfcdcurrent'; listMode = 'ajax'; source = 'MyFCD_Current' },
  @{ module = 'myfcd97'; listMode = 'ajax'; source = 'MyFCD_1997' },
  @{ module = 'myfcdindustri'; listMode = 'industry'; source = 'MyFCD_Industry' }
)

foreach ($sourceCfg in $sources) {
  $module = [string]$sourceCfg.module
  $listMode = [string]$sourceCfg.listMode
  $sourceLabel = [string]$sourceCfg.source
  $list = Get-MyfcdList $module $listMode
  Write-Output ("$module items=" + $list.Count)

  for ($i = 0; $i -lt $list.Count; $i++) {
    $base = $list[$i]
    $pn = Get-MyfcdNutrientsFromDetailPage $module $base.id
    if ($null -eq $pn) {
      continue
    }

    $energy = Get-NutrientValue $pn 'Energy'
    if ($null -eq $energy) {
      continue
    }

    $protein = Get-NutrientValue $pn 'Protein'
    if ($null -eq $protein) { $protein = 0 }
    $fat = Get-NutrientValue $pn 'Fat'
    if ($null -eq $fat) { $fat = 0 }
    $carb = Get-NutrientValue $pn 'Carbohydrate'
    if ($null -eq $carb) { $carb = 0 }
    $sodium = Get-NutrientValue $pn 'Sodium'
    if ($null -eq $sodium) { $sodium = 0 }
    $sugar = Get-NutrientValue $pn 'Total sugars'
    if ($null -eq $sugar) { $sugar = 0 }

    $name = $base.nameEn.Trim()
    $tokens = @($name.ToLower().Split(' ', [System.StringSplitOptions]::RemoveEmptyEntries) | Select-Object -Unique)
    $tokens += $name.ToLower()
    $tokens = @($tokens | Select-Object -Unique)

    $all += [ordered]@{
      myfcdCode = $base.id
      nameEn = $name
      nameMy = $name
      nameEnLower = $name.ToLower()
      nameMyLower = $name.ToLower()
      searchTerms = $tokens
      foodGroup = ("Group " + $base.foodGroupCode)
      caloriesPer100g = [Math]::Round($energy, 2)
      proteinPer100g = [Math]::Round($protein, 2)
      carbsPer100g = [Math]::Round($carb, 2)
      fatsPer100g = [Math]::Round($fat, 2)
      sodiumPer100g = [Math]::Round($sodium, 2)
      sugarPer100g = [Math]::Round($sugar, 2)
      portionSizes = @{ smallGrams = 100; mediumGrams = 150; largeGrams = 250 }
      source = $sourceLabel
    }

    if ((($i + 1) % 50) -eq 0 -or ($i + 1) -eq $list.Count) {
      Write-Output ("$module processed " + ($i + 1) + "/" + $list.Count)
    }
  }
}

$distinct = @{}
foreach ($food in $all) {
  $distinct[$food.myfcdCode] = $food
}

$final = @($distinct.Values)
New-Item -ItemType Directory -Force -Path assets/data | Out-Null
$final | ConvertTo-Json -Depth 8 | Set-Content -Path assets/data/myfcd_full.json -Encoding UTF8
Write-Output ("myfcd_full.json items=" + $final.Count)
