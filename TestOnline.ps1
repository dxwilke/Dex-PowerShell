PS C:\Users\dwwilke\Desktop\PS> $names = Get-content "hnames.txt"

foreach ($name in $names){
  if (Test-Connection -ComputerName $name -Count 1 -ErrorAction SilentlyContinue){
    Write-Host "$name,up"
  }
  else{
    Write-Host "$name,down"
  }
}