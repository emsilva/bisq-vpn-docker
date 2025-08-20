# Security Configuration

This directory contains security profiles and configurations for container hardening.

## Files

### bisq-seccomp.json
Custom seccomp (Secure Computing Mode) profile for the Bisq container that:
- Restricts system calls to only those needed for normal operation
- Blocks potentially dangerous system calls like `syslog`
- Allows necessary calls for Java applications, networking, and file operations

## Security Features Implemented

### Gluetun Container
- `no-new-privileges`: Prevents privilege escalation
- `seccomp:unconfined`: Required for VPN operations (WireGuard needs low-level network access)
- `apparmor:unconfined`: Required for creating network tunnels

### Bisq Container
- `no-new-privileges`: Prevents privilege escalation
- Custom seccomp profile: Restricts available system calls
- `tmpfs` mounts: Non-executable temporary directories
- Resource limits: CPU and memory constraints

## Security Best Practices

1. **Regular Updates**: Keep base images and packages updated
2. **Minimal Privileges**: Run containers with least required privileges
3. **Network Isolation**: Use dedicated networks for container communication
4. **Secret Management**: Store sensitive data in Docker secrets
5. **Monitoring**: Implement logging and monitoring for security events

## Production Recommendations

For production deployments, consider:
- Using external secret management (HashiCorp Vault, AWS Secrets Manager)
- Implementing network policies
- Regular vulnerability scanning
- Host-level security hardening
- Runtime security monitoring