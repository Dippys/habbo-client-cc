# Troubleshooting

Guide for diagnosing and resolving common issues in the Habbo client.

## Common Issues

### Connection Issues

- **Unable to connect to server**: Check network connectivity and firewall settings. Verify server address in configuration.
- **Connection timeout**: Increase timeout values in network settings or check server availability.
- **SSL/TLS errors**: Ensure certificates are valid and up to date.

### Rendering Glitches

- **Missing textures**: Clear cache and verify asset files are present in the resources directory.
- **Flickering graphics**: Update display drivers or try disabling hardware acceleration in settings.
- **Performance slowdowns**: Reduce graphics quality settings or check for memory leaks in the room renderer.

### Login Problems

- **Invalid credentials**: Clear saved credentials and re-enter login details.
- **Session expired**: Implement automatic reconnection logic or prompt user to log in again.
- **Two-factor authentication issues**: Ensure time-based codes are synced with server time.

## Debugging Tips

- Enable debug logging in config settings
- Check browser console for JavaScript errors
- Use network inspector to monitor message traffic

---

*This page is under construction.*
