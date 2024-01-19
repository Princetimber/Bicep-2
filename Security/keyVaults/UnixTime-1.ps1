# Get the current date and time
$currentDate = Get-Date

# Calculate the exp value (1 year from now)
$expDate = $currentDate.AddYears(1)
$exp = [math]::Round(($expDate.ToUniversalTime() - (Get-Date -Year 1970 -Month 1 -Day 1)).TotalSeconds)

# Calculate the nbf value (1 day from now)
$nbfDate = $currentDate.AddDays(1)
$nbf = [math]::Round(($nbfDate.ToUniversalTime() - (Get-Date -Year 1970 -Month 1 -Day 1)).TotalSeconds)

# Output the results
$exp
$nbf