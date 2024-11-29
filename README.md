
# Raspberry Pi Setup Guide with Ansible and Services

This guide walks you through the process of setting up a Raspberry Pi 4 Model B running Raspberry Pi OS Lite (64-bit), installing required tools, configuring services like AdGuard, Portainer, and WireGuard, and managing everything using Ansible.

## Prerequisites

- **Raspberry Pi 4 Model B** running Raspberry Pi OS Lite (64-bit)
- **MicroSD card** to install Raspberry Pi OS
- **Ansible** installed on your host machine (refer to the [Ansible installation guide](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html))

## Step 1: Flash Raspberry Pi OS on a microSD Card

1. Install [Raspberry Pi Imager](https://www.raspberrypi.com/software/) on your host machine.
2. Use the Imager to flash Raspberry Pi OS Lite (64-bit) onto the microSD card.

## Step 2: Find the IP Address of the Raspberry Pi

Find the IP address of your Raspberry Pi using your router's web interface or network scanning tool.

## Step 3: SSH into Raspberry Pi

1. On your host machine, run the following command to SSH into the Raspberry Pi:
   ```bash
   ssh username@your-rpi-ip-here
   ```

## Step 4: Setup SSH Keys

1. Generate an SSH key pair on your host machine:
   ```bash
   ssh-keygen -t ed25519 -C "your-host-machine-name"
   ```
2. Copy the public key to the Raspberry Pi:
   ```bash
   ssh-copy-id -i generated_key_name.pub admin@your-rpi-ip-here
   ```

## Step 5: Configure SSH in Ansible

Add the following configuration to your Ansible inventory file:

```ini
[pi]
pi1 ansible_host=your-rpi-ip-here ansible_user=admin ansible_private_key_file=~/.ssh/private_keys/generated_key_name
```

Make sure to update `your-rpi-ip-here` with the actual IP address of your Raspberry Pi.

## Step 6: Test Ansible Connectivity

Run the following command to test the connection to the Raspberry Pi using Ansible:

```bash
ansible -i inventory.ini pi -m ping
```

## Step 7: Configuration Files

Before running the Ansible playbook, you need to modify and include the following configuration files for the services you are setting up (such as Traefik, Portainer, and AdGuard):

- [**.env**](/files/docker-compose/.env)
- [**services.yaml**](files/docker-compose/homepage/config/services.yaml)
- [**traefik.yml**](files/docker-compose/traefik/config/traefik.yml)
- [**pi_vars.yml**](vars/pi_vars.yml)

Ensure these configuration files are updated and correctly placed before continuing to the next step.

## Step 8: Run the Ansible Playbook

Once the connectivity test is successful, run the Ansible playbook:

```bash
ansible-playbook main.yml
```

## Step 9: AdGuard Home Setup

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

6. Add DNS rewrites for your custom domain:
   - Go to `http://your-rpi-ip-here:8080/#dns_rewrites`
   - Add a new DNS rewrite for:
     - **Domain**: `*.local.your.domain`
     - **IP**: `your-rpi-ip-here`

   Once your DNS is set to `your-rpi-ip-here`, you can access other services.

## Step 10: Portainer Setup

1. To restart Portainer, use the following command if there is a timeout:
   ```bash
   docker restart portainer
   ```

2. Create an account in the Portainer interface.

3. To generate an API token, visit:
   ```
   https://portainer.local.your.domain/#!/account/tokens/new
   ```

4. Set the API key in your `homepage/config/` directory.

## Step 11: WireGuard Setup

1. For WireGuard, set up a **domain name** and forward port `51820` on your router to the Raspberry Pi.

## Troubleshooting

- If any service is not working, verify the configuration, check the logs, and ensure the ports are correctly forwarded on your router.
