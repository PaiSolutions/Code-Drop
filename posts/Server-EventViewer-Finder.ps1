$targetTime = Get-Date "1:47 PM"

$startTime = $targetTime.AddMinutes(-2)
$endTime = $targetTime.AddMinutes(2)

$filter = "*[System[EventID=4624 and TimeCreated[@SystemTime >= '$($startTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ"))' and @SystemTime <= '$($endTime.ToUniversalTime().ToString("yyyy-MM-ddTHH:mm:ss.fffZ"))']]]"

$events = Get-WinEvent -LogName Security -FilterXPath $filter

$events | Select-Object TimeCreated, Id, ProviderName, RecordId, LevelDisplayName, TaskDisplayName, OpcodeDisplayName, Version, Message | Out-File -FilePath "C:\Temp\File-ARTWDC0002.txt"
