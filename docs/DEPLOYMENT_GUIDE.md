# Production Deployment Guide

## Pre-Deployment Checklist

### 1. Environment Setup
- [ ] Copy `.env.example` to `.env.production`
- [ ] Set `NEXT_PUBLIC_API_URL` to production API URL
- [ ] Set `OLLAMA_BASE_URL` to production Ollama instance
- [ ] Generate secure `SEARXNG_SECRET_KEY` (at least 32 random characters)
- [ ] Verify all environment variables are set (no `localhost` URLs)

### 2. Build & Testing
```bash
# Install dependencies
npm ci

# Type checking
npx tsc --noEmit

# Linting
npm run lint

# Build production bundle
npm run build

# Verify build succeeded
ls -la .next/
```

### 3. Security Validation
- [ ] No hardcoded API URLs in source code
- [ ] No hardcoded secrets in source code
- [ ] CI/CD pipeline passed all checks
- [ ] No console.log statements in bundle
- [ ] CORS headers configured for backend
- [ ] Rate limiting enabled on API endpoints

### 4. Database & Storage
- [ ] Database migrations applied
- [ ] Seed data loaded if needed
- [ ] Backup strategy tested
- [ ] ChromaDB persistence configured

### 5. Monitoring & Logging
- [ ] Error tracking (Sentry, etc) configured
- [ ] Analytics (Google Analytics, etc) configured
- [ ] Logging endpoint configured
- [ ] Health check endpoint tested
- [ ] Uptime monitoring configured

### 6. Performance
- [ ] Bundle size reviewed (should be < 500KB main bundle)
- [ ] Load testing completed
- [ ] Caching headers configured
- [ ] CDN configured for static assets
- [ ] Image optimization enabled

### 7. DNS & SSL
- [ ] DNS records updated
- [ ] SSL certificate installed
- [ ] HTTP → HTTPS redirect configured
- [ ] Certificate renewal automated

## Deployment Steps

### Step 1: Prepare Production Environment
```bash
# 1. SSH to production server
ssh user@production.example.com

# 2. Clone repository
git clone https://github.com/your-org/rez-hive.git
cd rez-hive

# 3. Create environment file
nano .env.production
# Add all required environment variables

# 4. Install dependencies
npm ci --only=production
```

### Step 2: Build Application
```bash
# Set production NODE_ENV
export NODE_ENV=production

# Build Next.js application
npm run build

# Verify build artifacts
ls -la .next/
```

### Step 3: Start Application
```bash
# Option A: Using npm
npm start

# Option B: Using PM2 (recommended for production)
npm install -g pm2
pm2 start npm --name "rez-hive" -- start
pm2 save
pm2 startup

# Option C: Using Docker
docker build -t rez-hive:latest .
docker run -d \
  --name rez-hive \
  -p 3000:3000 \
  --env-file .env.production \
  rez-hive:latest
```

### Step 4: Verify Deployment
```bash
# Check application is running
curl http://localhost:3000

# Check logs
pm2 logs rez-hive

# Monitor performance
pm2 monit
```

## Post-Deployment

### Smoke Testing
- [ ] Frontend loads without errors
- [ ] Can send messages to kernel
- [ ] API responses working
- [ ] Search functionality working
- [ ] Error tracking logs properly

### Monitoring
- [ ] Check error tracking service (Sentry)
- [ ] Review application performance monitoring (APM)
- [ ] Verify logging is flowing to backend
- [ ] Monitor system resources (CPU, memory, disk)

### Rollback Plan
If issues occur:
```bash
# Rollback to previous version
git rollback <commit-hash>
npm ci
npm run build
pm2 restart rez-hive

# Or switch to backup instance
# Update DNS to point to backup
```

## Scaling in Production

### Horizontal Scaling
- Use load balancer (NGINX, HAProxy)
- Run multiple instances of application
- Use sticky sessions if needed
- Monitor backend API capacity

### Vertical Scaling
- Increase server CPU/RAM
- Optimize database queries
- Enable caching layer (Redis)
- Implement request queuing

### Database Considerations
- Enable read replicas for ChromaDB
- Implement query optimization
- Setup automated backups
- Monitor query performance

## Security in Production

### API Security
- [ ] CORS headers configured
- [ ] Rate limiting enabled
- [ ] Input validation on all endpoints
- [ ] SQL injection prevention (if applicable)
- [ ] XSS protection headers

### Infrastructure Security
- [ ] Firewall rules configured
- [ ] DDoS protection enabled
- [ ] WAF (Web Application Firewall) rules
- [ ] Regular security audits scheduled
- [ ] Penetration testing completed

### Data Protection
- [ ] Data encrypted in transit (HTTPS)
- [ ] Data encrypted at rest
- [ ] Sensitive logs sanitized
- [ ] GDPR/privacy compliance verified
- [ ] Regular backups tested

## Maintenance

### Regular Tasks
- [ ] Review logs weekly
- [ ] Monitor performance metrics
- [ ] Update dependencies monthly
- [ ] Security patches immediately
- [ ] Full backup weekly

### Incident Response
1. **Detect:** Monitor alerts
2. **Respond:** Page on-call engineer
3. **Mitigate:** Rollback or scale up
4. **Resolve:** Fix root cause
5. **Learn:** Post-mortem

## Contact & Support

- **On-call:** [team-email]
- **Slack:** #rez-hive-incidents
- **Status Page:** https://status.example.com
- **Documentation:** [link to wiki]
