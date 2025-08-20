# Secrets Management

This directory contains sensitive VPN credentials that should never be committed to version control.

## Setup

1. Create the secret files:
   ```bash
   echo "YOUR_PRIVATE_KEY_HERE" > secrets/wireguard_private_key.txt
   echo "YOUR_PRESHARED_KEY_HERE" > secrets/wireguard_preshared_key.txt
   ```

2. Secure the files:
   ```bash
   chmod 600 secrets/*.txt
   ```

3. Use the secrets-enabled compose file:
   ```bash
   docker compose -f docker-compose.yml -f docker-compose.secrets.yml up -d
   ```

## Security Notes

- These files contain sensitive cryptographic keys
- Never commit them to version control
- Use proper file permissions (600)
- Consider using external secret management in production (HashiCorp Vault, AWS Secrets Manager, etc.)

## File Descriptions

- `wireguard_private_key.txt` - Your WireGuard private key
- `wireguard_preshared_key.txt` - Your WireGuard preshared key (if used)