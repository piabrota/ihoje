# Security Practices for iHoje

This document outlines the security practices and measures implemented in the iHoje system, with a focus on authentication and authorization.

## Authentication System

### Overview

The iHoje system uses Supabase for authentication, providing:

1. **OAuth Authentication**: Google authentication for user login
2. **Role-Based Access Control**: Admin vs regular user roles
3. **Protected Routes**: Administrative areas are protected from unauthorized access
4. **Development Testing**: Test credentials for local development only

### Security Measures

#### Token Storage

1. **Production Mode**:
   - Sensitive auth tokens stored in HTTP-only cookies
   - Non-sensitive user information in localStorage for UI purposes
   - CSRF tokens for state verification
   - Server-side token validation
   
2. **Development Mode**:
   - User data, including tokens, stored in localStorage for ease of testing
   - Test credentials only available in debug builds

#### API Security

1. **Request Authentication**:
   - Authentication tokens passed in headers for API calls
   - Session validation on protected endpoints
   - Short token expiry with automatic renewal
   
2. **Role Verification**:
   - Server-side role verification before giving access
   - Role cached client-side but verified on critical operations
   - Admin role determined from Supabase app_metadata

#### HTTP Security Headers

1. **Content Security Policy**: Restricts resource origins
2. **X-Frame-Options**: Prevents clickjacking
3. **X-Content-Type-Options**: Prevents MIME-type sniffing
4. **Referrer-Policy**: Controls referrer information
5. **CORS Headers**: Restricts cross-origin requests

#### Rate Limiting

Rate limiting has been implemented for sensitive endpoints:

1. **Login Attempts**: 5 per minute
2. **Admin Routes**: 20 per minute
3. **API Endpoints**: 30 per minute

Exceeding these limits results in escalating backoff periods.

#### Redirect Validation

1. All redirect URLs are validated against a whitelist
2. Prevents open redirect vulnerabilities
3. Only relative URLs or approved domains are allowed

#### External Resources

1. **Subresource Integrity (SRI)**: Validates external JS resources
2. **Specific Library Versions**: External resources pinned to specific versions
3. **Limited External Dependencies**: Minimal external requirements

#### Security Logging

1. **Authentication Events Logged**: Success/failure logging
2. **Admin Access Logged**: All admin access is recorded
3. **Rate Limit Violations**: All rate limit violations are recorded

## Development vs Production

### Development Mode

- More permissive CSP for local development
- Test credentials available
- Limited rate limiting
- Console-based logging

### Production Mode

- Strict CSP with minimal permissions
- No test credentials available
- Full rate limiting enabled
- File-based security logging
- HTTP-only cookies for tokens
- More restricted CORS

## Recommended Security Enhancements

Future security improvements to consider:

1. **MFA Support**: Add multi-factor authentication option
2. **API Key Rotation**: Implement automatic key rotation
3. **Audit Logging**: Enhanced security event logging
4. **Security Headers**: Additional security headers
5. **Advanced CSRF Protection**: For sensitive operations
6. **IP Geo-blocking**: Block unusual country access
7. **HTTPS Enforcement**: Strict Transport Security

## Security Testing

The following security tests are recommended:

1. **Penetration Testing**: Regular security assessments
2. **OWASP Top 10 Scanning**: Check for common vulnerabilities
3. **Dependency Scanning**: Check for vulnerable dependencies
4. **Authentication Flow Testing**: Test auth vulnerabilities

## Incident Response

In case of security incidents:

1. Revoke compromised tokens
2. Block suspicious IP addresses
3. Notify affected users if necessary
4. Document the incident and mitigation
5. Implement corrective measures

## References

- [Supabase Security Documentation](https://supabase.com/docs/guides/auth)
- [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)
- [MDN Content Security Policy](https://developer.mozilla.org/en-US/docs/Web/HTTP/CSP)