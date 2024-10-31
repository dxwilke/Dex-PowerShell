$ErrorActionPreference = "Stop"
$TPM = Get-WmiObject win32_tpm -Namespace root\cimv2\security\microsofttpm | where {$_.IsEnabled().Isenabled -eq 'True'} -ErrorAction SilentlyContinue
if (!$TPM) {
Write-Error "TPM IS NOT PRESENT, CHECK BIOS SETTING"
exit
}
$SystemDriveBitLockerRDY = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction SilentlyContinue
if ((($SystemDriveBitLockerRDY.KeyProtector.KeyProtectorType -contains "Tpm") -or ($SystemDriveBitLockerRDY.KeyProtector.KeyProtectorType -contains "RecoveryPassword"))-and("Off" -eq $SystemDriveBitLockerRDY.ProtectionStatus))
{
Write-Error "Bitlocker already enabled, but suspended, possibly for driver update"
exit
}
$WindowsVer = Get-WmiObject -Query 'select * from Win32_OperatingSystem where (Version like "10.0%") and ProductType = "1"' -ErrorAction SilentlyContinue
#Don't worry about this bit, Windows recognizes SSDs automatically and sets them to TRIM instead of actual defrag.
if ($WindowsVer -and $tpm -and !$SystemDriveBitLockerRDY) {
   Get-Service -Name defragsvc -ErrorAction SilentlyContinue | Set-Service -Status Running -ErrorAction SilentlyContinue
   BdeHdCfg -target $env:SystemDrive shrink -quiet
   }
$TPM = Get-WmiObject win32_tpm -Namespace root\cimv2\security\microsofttpm | where {$_.IsEnabled().Isenabled -eq 'True'} -ErrorAction SilentlyContinue
$WindowsVer = Get-WmiObject -Query 'select * from Win32_OperatingSystem where (Version like "10.0%") and ProductType = "1"' -ErrorAction SilentlyContinue
$BitLockerReadyDrive = Get-BitLockerVolume -MountPoint $env:SystemDrive -ErrorAction SilentlyContinue

#If all of the above prequisites are met, then create the key protectors, then enable BitLocker and backup the Recovery key to AD.
if ($WindowsVer -and $TPM -and $BitLockerReadyDrive) {
#Creating the recovery key
Add-BitLockerKeyProtector -MountPoint $env:SystemDrive -RecoveryPasswordProtector
#Adding TPM key
Add-BitLockerKeyProtector -MountPoint $env:SystemDrive -TpmProtector
#Get Recovery Keys
$AllProtectors = (Get-BitlockerVolume -MountPoint $env:SystemDrive).KeyProtector
$RecoveryProtector = ($AllProtectors | where-object { $_.KeyProtectorType -eq "RecoveryPassword" })
#Enabling Encryption
Resume-BitLocker -MountPoint $env:SystemDrive
}