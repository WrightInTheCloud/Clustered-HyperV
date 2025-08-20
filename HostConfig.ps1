# Install NuGet provider, which is required for managing packages
Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force

### Hyper-V Specific Configuration ###
# Create a new internal virtual switch named "Nat-Switch"
New-VMSwitch -Name "Nat-Switch" -SwitchType Internal

# Assign an IP address to the virtual switch for NAT configuration
New-NetIPAddress -IPAddress 172.16.0.1 -PrefixLength 24 -InterfaceAlias "vEthernet (Nat-Switch)"

# Create a NAT network using the virtual switch
New-NetNat -Name "Nat-Switch" -InternalIPInterfaceAddressPrefix 172.16.0.0/24

# Add the DHCP Server security group to the system
Add-DhcpServerSecurityGroup

# Create a DHCP scope for the nested VMs with a specified IP range
Add-DhcpServerv4Scope -Name "Nested VMs" -StartRange 172.16.0.10 -EndRange 172.16.0.100 -SubnetMask 255.255.255.0

# Set DNS server and default gateway options for the DHCP scope
Set-DhcpServerv4OptionValue -DnsServer 168.63.129.16 -Router 172.16.0.1

# Configure the DHCP server role to be in a ready state
Set-ItemProperty -Path HKLM:\SOFTWARE\Microsoft\ServerManager\Roles\12 -Name ConfigurationState -Value 2

# Restart the DHCP server service to apply changes
Restart-Service -Name DHCPServer -Force

### Disk and Directory Setup ###
# Initialize any RAW disks, format them with ReFS, and assign the drive letter F
Get-Disk | Where-Object -Property PartitionStyle -EQ "RAW" | Initialize-Disk -PartitionStyle GPT -PassThru | New-Volume -FileSystem REFS -AllocationUnitSize 65536 -DriveLetter F -FriendlyName "VMS"

# Create necessary directories for VM configurations, ISOs, disks, and templates
New-Item -Path "F:\VMS" -ItemType Directory
New-Item -Path "F:\VMS\ISO" -ItemType Directory
New-Item -Path "F:\VMS\Disks" -ItemType Directory
New-Item -Path "F:\VMS\Templates" -ItemType Directory

# Configure the VM host to use the created directories and enable Enhanced Session Mode
Set-VMHost -VirtualMachinePath "F:\VMS" -VirtualHardDiskPath "F:\VMS\Disks" -EnableEnhancedSessionMode $true

### Download Required ISOs and VHDs ###

### Download Windows Server Evaluation ISO ###
$Win2016 = "https://go.microsoft.com/fwlink/p/?LinkID=2195174&clcid=0x409&culture=en-us&country=US"
$Win2019 = "https://go.microsoft.com/fwlink/p/?LinkID=2195167&clcid=0x409&culture=en-us&country=US"
$Win2022 = "https://go.microsoft.com/fwlink/p/?LinkID=2195280&clcid=0x409&culture=en-us&country=US"
$Win2025 = "https://go.microsoft.com/fwlink/?linkid=2293312&clcid=0x409&culture=en-us&country=us"
### Download Azure Migrate Hyper-V VHD ###
$AZMigHyperV = "https://go.microsoft.com/fwlink/?linkid=2191848"
###
$PS752 = "https://github.com/PowerShell/PowerShell/releases/download/v7.5.2/PowerShell-7.5.2-win-x64.msi"

# The destination path for the downloaded ISO
$iso2016 = "F:\VMS\ISO\WindowsServer2016Eval.iso"
$iso2019 = "F:\VMS\ISO\WindowsServer2019Eval.iso"
$iso2022 = "F:\VMS\ISO\WindowsServer2022Eval.iso"
$iso2025 = "F:\VMS\ISO\WindowsServer2025Eval.iso"
# The destination path for the Azure Migrate Hyper-V VHD
$AZMigHyperVDest = "F:\VMS\Disks\AzureMigrateHyperV.zip"
# The destination path for PowerShell 7.5.2 installer
$PS752Dest = "F:\PowerShell-7.5.2-win-x64.msi"

# Download the ISO file and save it to the specified location
Start-BitsTransfer -Source $Win2016 -Destination $iso2016
Start-BitsTransfer -Source $Win2019 -Destination $iso2019
Start-BitsTransfer -Source $Win2022 -Destination $iso2022
Start-BitsTransfer -Source $Win2025 -Destination $iso2025
Start-BitsTransfer -Source $AZMigHyperV -Destination $AZMigHyperVDest
Start-BitsTransfer -Source $PS752 -Destination $PS752Dest

# Install PowerShell 7.5.2 from the downloaded MSI file
Start-Process -FilePath $PS752Dest -ArgumentList "/quiet" -Wait

### Retrieve and Install Required Software ###
# Install various tools and utilities using Winget
winget install --id "Microsoft.Azure.StorageExplorer" --silent --accept-source-agreements --accept-package-agreements   # Azure Storage Explorer
winget install --id "Microsoft.PowerShell" --silent --accept-source-agreements --accept-package-agreements              # Powershell 7
winget install --id "Microsoft.Azure.AZCopy.10" --silent --accept-source-agreements --accept-package-agreements         # AzCopy Utility
winget install --id "Microsoft.WindowsAdminCenter" --silent --accept-source-agreements --accept-package-agreements      # Windows Admin Center
winget install --id "Microsoft.AzureCLI" --silent --accept-source-agreements --accept-package-agreements                # Azure CLI

### Create Desktop Shortcuts ###
# Create a COM object to manage desktop shortcuts
$Shell = New-Object -ComObject ("WScript.Shell")

# Create a shortcut for Windows Admin Center
$Shortcut1 = $Shell.CreateShortcut("C:\Users\Public\Desktop\Windows Admin Center.url")
$Shortcut1.TargetPath = "https://localhost:6516"  # URL for Windows Admin Center
$Shortcut1.Save()

# Copy the Hyper-V Manager shortcut to the desktop
Copy-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Administrative Tools\Hyper-V Manager.lnk" -Destination "C:\Users\Public\Desktop\Hyper-V Manager.lnk"