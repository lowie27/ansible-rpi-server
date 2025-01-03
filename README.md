# Raspberry Pi Setup Guide with Ansible and Services

This guide walks you through the process of setting up a Raspberry Pi 4 Model B running Raspberry Pi OS Lite (64-bit), installing required tools, configuring services like AdGuard, Portainer, and WireGuard, and managing everything using Ansible.

## Prerequisites

- **Raspberry Pi 4 Model B** running Raspberry Pi OS Lite (64-bit)
- **MicroSD card** to install Raspberry Pi OS
- **Ansible** installed on your host machine (refer to the [Ansible installation guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html))

## Step 1: Flash Raspberry Pi OS on a microSD Card

1. **Install the Raspberry Pi Imager**  
   Download and install the [Raspberry Pi Imager](https://www.raspberrypi.com/software/) on your host machine.

2. **Flash Raspberry Pi OS Lite (64-bit)**  
   Use the Imager to flash Raspberry Pi OS Lite (64-bit) onto the microSD card:

   - **Choose your Raspberry Pi Device**: Select your device (e.g., Raspberry Pi 4).
   - **Choose your OS**:
     - Navigate to the **Raspberry Pi OS (other)** tab.
     - Select **Raspberry Pi OS Lite (64-bit)**.
   - **Choose Storage**: Select your microSD card as the target.

3. **Apply OS Customization Settings**  
   When prompted, click **Yes** to apply OS customization settings and modify the following:

   ### General Settings

   - **Set Hostname**: `rpi.local`
   - **Username**: `admin`
   - **Password**: `admin`
   - **Time Zone**: `Europe/Brussels`
   - **Keyboard Layout**: `be`

   ### Services

   - Enable **SSH**.
   - Use **Password Authentication**.

4. **Start the Flashing Process**  
   Once all settings are configured, start the flashing process and wait for it to complete.

## Step 2: Find the Raspberry Pi's IP Address

To connect to your Raspberry Pi, you need to determine its IP address. Use one of the following methods:

### 1. **Ping the Hostname**

- Open a terminal or command prompt on your host machine.
- Run the following command:
  ```bash
  ping rpi.local
  ```
  This will attempt to resolve the hostname `rpi.local` to an IP address.

### 2. **Use a Network Scanner**

- Download and install a network scanning tool like [Angry IP Scanner](https://angryip.org/download/).
- Scan your network to discover connected devices, and look for your Raspberry Pi's hostname or MAC address.

### 3. **Direct Connection via Monitor**

- Connect a monitor to your Raspberry Pi using a mini HDMI to HDMI cable.
- Once the Raspberry Pi boots up, it will display its IP address on the screen.

### 4. **Check Your Router's Interface**

- Log into your router's web interface (refer to your router’s manual for instructions).
- Locate the list of connected devices.
- Look for your Raspberry Pi by its hostname (`rpi.local`) or default name (`raspberrypi`).

Choose the method that best fits your setup and environment. Once you have the IP address, you can proceed to access your Raspberry Pi remotely.

## Step 3: SSH into Raspberry Pi

1. On your host machine, run the following command to SSH into the Raspberry Pi:
   ```zsh
   ssh username@your-rpi-ip-here
   ```

## Step 4: Setup SSH Keys

1. Generate an SSH key pair on your host machine:
   ```zsh
   ssh-keygen -t ed25519 -C "your-host-machine-name"
   ```
2. Copy the public key to the Raspberry Pi:

   ```zsh
   ssh-copy-id -i generated_key_name.pub admin@your-rpi-ip-here
   ```

3. Simplify SSH Access Using SSH Config File:
   ```zsh
   Host pi
   Hostname your-rpi-ip-here
   User admin
   IdentityFile ~/.ssh/private_keys/generated_key_name
   ```

This allows you to use a simple alias (pi) instead of typing the full SSH command each time.

## Step 5: Configure SSH in Ansible

Add the following configuration to your Ansible [inventory file](/inventory.ini):

```ini
[pi]
pi1 ansible_host=your-rpi-ip-here ansible_user=admin ansible_private_key_file=~/.ssh/private_keys/generated_key_name
```

Make sure to update `your-rpi-ip-here` with the actual IP address of your Raspberry Pi.

## Step 6: Test Ansible Connectivity

Run the following command to test the connection to the Raspberry Pi using Ansible:

```zsh
ansible -i inventory.ini pi -m ping
```

## Step 7: Configuration Files

Before running the Ansible playbook, ensure you modify and include the following configuration files for the services you are setting up (e.g., Traefik and AdGuard). These files need to be correctly updated and placed before proceeding.

### 1. **Environment Variables**: [.env](/files/docker-compose/.env)

Update the Cloudflare email and API key variables. Obtain the API key from the [Cloudflare API Tokens page](https://dash.cloudflare.com/profile/api-tokens) under the **Global API Key** section.

```zsh
CF_API_EMAIL=your-cloudflare-email
CF_API_KEY=your-cloudflare-api-key
```

For WireGuard configuration, update the following:

- **`PEER_DNS_SERVER`**: Point this to your Pi's IP address.
- **`SERVER_URL`**: Provide a public-facing domain name or IP address. If you have a domain name, create an **A Record** in your domain registrar pointing to your public IP.

```zsh
PEER_DNS_SERVER=your-pi-ip-here
SERVER_URL=your-public-ip-or-domain
```

You can find your public IP address using one of the following methods:

1. **Online Tool**:  
   Visit the following website to see your public IP address:  
   [https://whatismyipaddress.com/](https://whatismyipaddress.com/)

2. **Command Line**:  
   Run the following `curl` command in your terminal:
   ```bash
   curl https://ipinfo.io/ip
   ```

---

### 2. **Pi User Variables**: [pi_vars.yml](vars/pi_vars.yml)

This file contains the group and username for the Pi user. Ensure the information here matches your setup. If you need to change the file location, it's recommended to point it to an external hard drive, as the Raspberry Pi's SD card has limited storage capacity.

`Setting Up an External Hard Drive for Raspberry Pi:`

#### Step 1: Identify the External Hard Drive

- Connect the external hard drive to your Raspberry Pi.
- List connected block devices:
  ```bash
  lsblk
  ```
- Find your external drive, typically named `/dev/sdX` (e.g., `/dev/sdb`).

- Get the UUID of the drive:
  ```bash
  sudo blkid /dev/sdX1
  ```

#### Step 2: Create a Mount Point

- Create a directory to serve as the mount point:
  ```bash
  sudo mkdir -p /mnt/external_drive
  ```

#### Step 3: Create a Systemd Mount Unit

- Create a `systemd` mount unit file. Replace `/mnt/external_drive` with your desired mount point.
  The mount path should be translated to a filename with `-` replacing `/`.

  Example:

  - Mount point: `/mnt/external_drive`
  - Unit file: `/etc/systemd/system/mnt-external_drive.mount`

- Open the file for editing:

  ```bash
  sudo nano /etc/systemd/system/mnt-external_drive.mount
  ```

- Add the following content:

  ```ini
  [Unit]
  Description=Mount External Drive
  After=network.target

  [Mount]
  What=/dev/disk/by-uuid/<UUID>
  Where=/mnt/external_drive
  Type=ext4  # Replace with the correct filesystem type
  Options=defaults,noatime

  [Install]
  WantedBy=multi-user.target
  ```

  Replace `<UUID>` with the UUID from the `blkid` command, and update the `Type` field if necessary (e.g., `ntfs` for NTFS).

#### Step 4: Enable and Start the Mount Unit

- Reload `systemd` to recognize the new unit:

  ```bash
  sudo systemctl daemon-reload
  ```

- Enable the mount to start automatically on boot:

  ```bash
  sudo systemctl enable mnt-external_drive.mount
  ```

- Start the mount immediately:

  ```bash
  sudo systemctl start mnt-external_drive.mount
  ```

- Check the status of the mount:
  ```bash
  systemctl status mnt-external_drive.mount
  ```

#### Step 5: Verify and Test

- Reboot your Raspberry Pi to confirm the drive mounts automatically.
- If any issues arise, check the logs with:
  ```bash
  journalctl -xe
  ```

---

By following these steps, you ensure your external hard drive is consistently and securely mounted,
offloading storage demands from your Raspberry Pi's SD card.

### 3. **Homepage Services**: [services.yaml](files/docker-compose/homepage/config/services.yaml)

Update the **href** for the AdGuard service to point to your Pi's IP address:

```yaml
- Adguard:
    icon: adguard-home.png
    href: http://your-pi-ip-here:8080
    description: Advanced DNS Management, Privacy Protection, and Network Control
```

---

### 4. **Traefik Configuration**: [traefik.yml](files/docker-compose/traefik/config/traefik.yml)

Update the email address used for certificate issuance:

```yaml
certificatesResolvers:
  cloudflare:
    acme:
      email: certificate@your.email
      storage: /cloudflare/acme.json
      dnsChallenge:
        provider: cloudflare
        resolvers:
          - "1.1.1.1:53"
          - "1.0.0.1:53"
```

Once complete, you can proceed to the next step.

## Step 8: Run the Ansible Playbook

Once the connectivity test is successful, run the Ansible playbook:

```zsh
ansible-playbook main.yml
```

## Step 9: AdGuard Home Setup

AdGuard Home is a network-wide software for blocking ads and tracking. After you set it up, it'll cover ALL your home devices, and you don't need any client-side software for that.

1. Open the following URL on your Raspberry Pi's IP address to begin the AdGuard setup:

   ```
   http://your-rpi-ip-here:3000/install.html
   ```

2. During the setup, select the correct network interface and configure the following:

   - **Admin Web Interface:** Set to port `8080` (port `80` is in use by Traefik, and port `3000` is used by the temporary dashboard).
   - **DNS Server:** Use port `53` if not already in use.

3. Enter your desired **username** and **password**.

4. Configure DNS in the AdGuard interface:

   - Go to `http://your-rpi-ip-here:8080/#dns`
   - Add upstream DNS servers like:
     - `1.1.1.1`
     - `1.0.0.1`

5. Test and apply the upstream DNS settings.

6. Add DNS rewrites for your custom domain\*\*:

   - Go to `http://your-rpi-ip-here:8080/#dns_rewrites`
   - Add a new DNS rewrite for:
     - **Domain**: `*.local.lowie.xyz`
     - **IP**: `your-rpi-ip-here`

7. Update DNS Settings on Your Machine:

- Change your machine’s DNS server to the Raspberry Pi’s IP address (`your-rpi-ip-here`).
  - On macOS or Windows: Update the DNS settings in your network adapter configuration.
  - On Linux: Edit `/etc/resolv.conf` or update your network manager settings.

Once configured, your custom domain (e.g., `service.local.lowie.xyz`) will correctly resolve through your Raspberry Pi.

## Step 10: Portainer Setup

Portainer is a lightweight management UI that simplifies the deployment and management of Docker containers. It provides an intuitive interface for monitoring, configuring, and controlling your containers and services.

1. To restart Portainer, use the following command if there is a timeout:

   ```zsh
   docker restart portainer
   ```

2. Create an account in the Portainer interface.

3. To generate an API token, visit:

   ```
   https://portainer.local.your.domain/#!/account/tokens/new
   ```

4. Set the API key in your `homepage/config/` directory.

## Step 11: WireGuard Setup

WireGuard is a modern VPN (Virtual Private Network) solution that is fast, secure, and simple to configure. It creates encrypted tunnels to protect your online activity, ensuring privacy and security, whether you're on public Wi-Fi or accessing your home network remotely.

1. **Set up a Domain Name**:
   For WireGuard, configure a **domain name** that points to your Raspberry Pi. Ensure that you forward port `51820` on your router to the Pi’s internal IP address.

2. **Obtain the QR Code**:
   To easily configure the WireGuard client, you can retrieve the necessary QR code by running the following command:

   ```zsh
   docker logs wireguard
   ```

   This will output the QR code, which you can scan using the WireGuard mobile app to configure your client.

## Step 12: Samba Share

Samba is a software suite that allows file sharing between Linux and Windows systems. It enables your Raspberry Pi to share files and directories with other devices on the network, making it accessible for both Linux and Windows users.

Run the following command after running the Ansible playbook to ensure your Samba user admin is set up correctly:

```zsh
sudo smbpasswd -a admin
```

## Troubleshooting

- If any service is not working, verify the configuration, check the logs, and ensure the ports are correctly forwarded on your router.

# Siemens License Server Installation on Raspberry Pi

## Prerequisites

- Raspberry Pi running a supported OS (e.g., Raspberry Pi OS).
- Network connection for the Pi.
- Access to the Siemens License Server installer [`SiemensLicenseServer_vX.X.XX.X_Lnx64_arm.bin`](https://support.sw.siemens.com/en-US/product/1586485382/download/202410063).

## Steps for Installing the Siemens License Server on Raspberry Pi

### 1. Ensure the Raspberry Pi is online

```zsh
ssh pi
```

### 2. Transfer the License Server Installer to the Raspberry Pi

Use `scp` to copy the Siemens License Server installer from the host machine to the Raspberry Pi.

```zsh
scp SiemensLicenseServer_vX.X.X.X_Lnx64_arm.bin pi:/home/admin/license_server.bin
```

### 3. Make the Installer Executable on the Raspberry Pi

SSH into the Raspberry Pi and make the installer executable.

```zsh
chmod +x license_server.bin
```

### 4. Install Required Packages

Ensure `lsof` is installed:

```zsh
sudo apt install lsof
```

### 5. Run the License Server Installer

Execute the installer to begin the installation process.

```zsh
sudo ./license_server.bin
```

### 6. Select Language

You will be prompted to select the language for the installation. Enter the number corresponding to your preferred language. For English:

```
[2] English (United States)
```

### 7. License File Import

Select the action you want to perform. To import a license file, choose option `1`. If you want to skip, choose option `2`.

```
Please choose the action you want to perform:
[1] Import License File
[2] Skip import License File
[3] Cancel
Option Selected [1]:
```

### 8. Installation Directory

Choose the destination folder for the installation. Press `Enter` to use the default directory:

```
Please choose a destination folder for this installation:
Press [Enter] to use the default location, or [C] to cancel:
[/opt/Siemens/LicenseServer] :
```

### 9. License Server Username

Enter the username under which you want to run the license server. Press `Enter` to use the default username:

```
Enter the username under which you want to run the license server [saltd]:
```

### 10. Use the Siemens License Install Manager (SLIM)

Choose whether to use SLIM to facilitate administrative tasks like updating license files, applying patches, and viewing server status/logs.

```
Would you like to use this feature? [y/n]
Option Selected [y]:
```

### 11. Enter Administrator Email

Enter the email of an authorized administrator for this License Server. This email is encrypted and stored locally.

```
Enter a Siemens Account (Webkey), Support Center login, or email of an authorized administrator for this License Server:
```

### 12. Get the Host ID (CID)

Navigate to the Siemens License Server directory and run the `getcid` command to obtain the Host ID (CID).

```zsh
cd /opt/Siemens/LicenseServer
./getcid
```

If you have multiple network adapters, select the first or most appropriate CID based on the active adapter.

Use the `ip a` command to help identify the correct network adapter.
