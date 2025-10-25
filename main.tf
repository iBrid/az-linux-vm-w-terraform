terraform {
  required_version = ">=1.3.8"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.48.0"
    }
  }
  cloud {
    organization = "DatacentR"
    workspaces {
      name = "linux-vm-w-terraform"
    }
  }
}

provider "azurerm" {
  features {}
  skip_provider_registration = true
}

resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
}

resource "azurerm_virtual_network" "vnet" {
  name                = "mylin-vnet"
  address_space       = ["172.16.0.0/16"]
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    environment = "Dev"
  }
}

resource "azurerm_subnet" "snet" {
  name                 = "mylin-snet"
  address_prefixes     = ["172.16.1.0/24"]
  virtual_network_name = azurerm_virtual_network.vnet.name
  resource_group_name  = var.resource_group_name
}

resource "azurerm_network_interface" "nic" {
  name                = "mylin-nic"
  resource_group_name = var.resource_group_name
  location            = var.location

  ip_configuration {
    name                          = "ip_config"
    private_ip_address_allocation = "Dynamic"
    subnet_id                     = azurerm_subnet.snet.id
    public_ip_address_id          = azurerm_public_ip.pip.id
  }
}

resource "azurerm_network_security_group" "nsg" {
  name                = "mylin-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  tags = {
    environment = "Dev"
  }
}

resource "azurerm_public_ip" "pip" {
  name                = "mylinux-pip"
  allocation_method   = "Static"
  resource_group_name = var.resource_group_name
  location            = var.location
}

resource "azurerm_network_security_rule" "SSH" {
  name                        = "AllowSSH"
  protocol                    = "Tcp"
  access                      = "Allow"
  priority                    = 100
  direction                   = "Inbound"
  source_port_range           = "*"
  destination_port_range      = "22"
  source_address_prefix       = "Internet"
  destination_address_prefix  = "*"
  resource_group_name         = var.resource_group_name
  network_security_group_name = azurerm_network_security_group.nsg.name
}

resource "azurerm_network_interface_security_group_association" "nic_nsg_assoc" {
  network_interface_id      = azurerm_network_interface.nic.id
  network_security_group_id = azurerm_network_security_group.nsg.id
}

resource "tls_private_key" "ssh_key_pair" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "vm" {
  name                            = "mylin-vm"
  admin_username                  = "azureuser"
  size                            = "Standard_F2s_v2"
  disable_password_authentication = true
  network_interface_ids           = [azurerm_network_interface.nic.id]
  resource_group_name             = var.resource_group_name
  location                        = var.location

  admin_ssh_key {
    username   = "azureuser"
    public_key = tls_private_key.ssh_key_pair.public_key_openssh
  }


  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    offer     = "0001-com-ubuntu-server-focal"
    publisher = "Canonical"
    version   = "latest"
    sku       = "20_04-lts-gen2"
  }
}