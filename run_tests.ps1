$godot = "D:\Users\Ariedis\Downloads\Godot_v4.6.1-stable_win64.exe"
$project = "D:\Coding\Projects\Maze Runner"
$scene = "res://tests/scenes/TestRunnerScene.tscn"
$out = "D:\Coding\Projects\Maze Runner\test_results.txt"

$proc = Start-Process -FilePath $godot `
    -ArgumentList "--headless", "--path", "`"$project`"", $scene `
    -RedirectStandardOutput $out `
    -RedirectStandardError "$out.err" `
    -NoNewWindow -Wait -PassThru

$output = Get-Content $out -ErrorAction SilentlyContinue
$errout = Get-Content "$out.err" -ErrorAction SilentlyContinue

Write-Host "=== STDOUT ==="
$output | ForEach-Object { Write-Host $_ }
Write-Host "=== STDERR ==="
$errout | ForEach-Object { Write-Host $_ }
Write-Host "=== EXIT CODE: $($proc.ExitCode) ==="
