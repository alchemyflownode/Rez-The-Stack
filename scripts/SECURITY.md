# REZ HIVE Security Posture

## Architecture
- All inference runs locally via Ollama
- No external API calls
- All data stored on local filesystem
- Audit logging enabled for all actions

## Security Controls
- API key authentication (optional)
- Rate limiting (100 req/hour)
- Input validation (constitutional guards)
- Dependency scanning (weekly)

## Compliance
- GDPR: Data never leaves user's machine
- SOC2: Audit logs maintained
- Privacy: No telemetry, no tracking