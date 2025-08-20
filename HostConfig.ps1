# Install NuGet provider, which is required for managing packages
Install-PackageProvider -Name NuGet -Force

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
New-Item -Path "F:\Downloads\AzureMigrateAppliance" -ItemType Directory -Force
New-Item -Path "F:\Downloads" -ItemType Directory -Force
New-Item -Path "F:\VMS" -ItemType Directory -Force
New-Item -Path "F:\VMS\ISO" -ItemType Directory -Force
New-Item -Path "F:\VMS\Disks" -ItemType Directory -Force
New-Item -Path "F:\VMS\Templates" -ItemType Directory -Force

# Configure the VM host to use the created directories and enable Enhanced Session Mode
Set-VMHost -VirtualMachinePath "F:\VMS" -VirtualHardDiskPath "F:\VMS\Disks" -EnableEnhancedSessionMode $true

### Download Windows Server Evaluation ISO ###
$win2016Url = "https://go.microsoft.com/fwlink/p/?LinkID=2195174&clcid=0x409&culture=en-us&country=US"
$win2019Url = "https://go.microsoft.com/fwlink/p/?LinkID=2195167&clcid=0x409&culture=en-us&country=US"
$win2022Url = "https://go.microsoft.com/fwlink/p/?LinkID=2195280&clcid=0x409&culture=en-us&country=US"
$Win2025Url = "https://go.microsoft.com/fwlink/?linkid=2293312&clcid=0x409&culture=en-us&country=us"

### Download Azure Migrate Hyper-V VHD ###
$AZMigHyperVUrl = "https://go.microsoft.com/fwlink/?linkid=2191848"

# The destination path for the downloaded ISO
$win2016IsoPath = "F:\VMS\ISO\WindowsServer2016Eval.iso"
$win2019IsoPath = "F:\VMS\ISO\WindowsServer2019Eval.iso"
$win2022IsoPath = "F:\VMS\ISO\WindowsServer2022Eval.iso"
$win2025IsoPath = "F:\VMS\ISO\WindowsServer2025Eval.iso"

# The destination path for the Azure Migrate Hyper-V VHD
$azMigHyperVZipPath = "F:\Downloads\AzureMigrateHyperV.zip"
$azMigAppliancePath = "F:\Downloads\AzureMigrateAppliance"

# Download the ISO file and save it to the specified location
Start-BitsTransfer -Source $win2016Url -Destination $win2016IsoPath
Start-BitsTransfer -Source $win2019Url -Destination $win2019IsoPath
Start-BitsTransfer -Source $win2022Url -Destination $win2022IsoPath
Start-BitsTransfer -Source $win2025Url -Destination $win2025IsoPath
Start-BitsTransfer -Source $azMigHyperVUrl -Destination $azMigHyperVZipPath

# Extract the Azure Migrate Hyper-V VHD and delete the zip file
Expand-Archive -LiteralPath $azMigHyperVZipPath -DestinationPath $azMigAppliancePath -Force
Remove-Item -Path $azMigHyperVZipPath -Force

### Create Desktop Shortcuts ###
# Create a COM object to manage desktop shortcuts
$Shell = New-Object -ComObject ("WScript.Shell")

# Copy the Hyper-V Manager shortcut to the desktop
Copy-Item -Path "C:\ProgramData\Microsoft\Windows\Start Menu\Programs\Administrative Tools\Hyper-V Manager.lnk" -Destination "C:\Users\Public\Desktop\Hyper-V Manager.lnk"