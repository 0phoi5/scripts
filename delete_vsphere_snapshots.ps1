#!/usr/bin/pwsh

$vs_servers = @("server1.domain.co.uk","server2.domain.co.uk")

ForEach ($vs_server in $vs_servers) {
  Write_host "Connecting to $vs_server"
  Connect-VIServer $vs_server -User USERNAME -Password PASSWORD

    Get-VM |
    Get-Snapshot |
    Where-Object Name -like *"YOUR SEARCH TERM HERE"* |
    Remove-Snapshot -Confirm:$false

  Disconnect-VIServer -Confirm:$false
}
