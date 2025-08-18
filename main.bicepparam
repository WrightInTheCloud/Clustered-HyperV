using './main.bicep'

param location = resourceGroup().location
param computerName = 'HyperVHost'
param AdminUsername = 'bob'
param AdminPassword = 'TestD3ploy123!'
param VirtualMachineSize = 'Standard_D8s_v5'
param vnetName = 'vnet-hypervlab-01'
param vnetaddressPrefix = '192.168.0.0/24'
param subnetName = 'snet-hypervlab-01'
param subnetPrefix = '192.168.0.0/28'

