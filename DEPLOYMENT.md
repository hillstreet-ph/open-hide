# Railway Deployment Checklist - open-hide

## Prerequisites
- ✅ Railway account with project access
- ✅ Supabase project with database credentials
- ✅ GitHub fork: hillstreet-ph/open-hide
- ✅ All exposed credentials rotated (see Security Notice)

---

## Step 1: Commit Configuration Changes

```bash
# In your local clone of hillstreet-ph/open-hide
git add railway.json .env.railway
git commit -m "Update railway config for fork and external database"
git push origin main
```

---

## Step 2: Railway Project Setup

### A. Create New Project (if not already done)
1. Go to [railway.com/dashboard](https://railway.com/dashboard)
2. Click **New Project**
3. Select **Deploy from GitHub repo**
4. Choose: `hillstreet-ph/open-hide`
5. Select branch: `main`
6. Click **Deploy**

### B. Configure Environment Variables
1. In your Railway project, go to the **app** service
2. Click **Variables** tab
3. Add all variables from `.env.railway` with your actual values:

| Variable | Source | Notes |
|---|---|---|
| `DATABASE_URL` | Supabase | Use pooler URL if available |
| `JWT_SECRET` | Generate | `openssl rand -hex 32` |
| `ENCRYPTION_KEY` | Generate | Exactly 32 chars |
| `NEXTAUTH_SECRET` | Generate | `openssl rand -hex 32` |
| `FRONTEND_URL` | Railway | Auto-filled after deploy |
| `NEXTAUTH_URL` | Railway | Same as FRONTEND_URL |
| `CORS_ORIGIN` | Railway | Same as FRONTEND_URL |
| `SERVER_URL` | Railway | Same as FRONTEND_URL |
| `MCP_AUTH_MODE` | Manual | `both` recommended |

### C. Update URLs After First Deploy
1. Wait for first deployment to complete
2. Copy your Railway public domain (e.g., `https://open-hide-production.up.railway.app`)
3. Update these variables:
   - `FRONTEND_URL`
   - `NEXTAUTH_URL`
   - `CORS_ORIGIN`
   - `SERVER_URL`
4. Click **Redeploy**

---

## Step 3: Supabase Configuration

### A. Get Connection String
1. Go to [supabase.com/dashboard](https://supabase.com/dashboard)
2. Select your project: `fhmshcgkykosprstnblx`
3. Go to **Settings → Database**
4. Under **Connection string**, copy the **URI**
5. Format should be: `postgresql://postgres:[password]@fhmshcgkykosprstnblx.supabase.co:5432/postgres`

### B. Enable Required Extensions (if needed)
Prisma may require these PostgreSQL extensions. Run in Supabase SQL Editor:
```sql
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
```

---

## Step 4: Verify Deployment

### A. Health Check
```bash
curl https://your-app.up.railway.app/health
# Should return: {"status":"ok"}
```

### B. First User Registration
1. Visit your frontend URL
2. Register the first user - this user becomes **admin**
3. Verify you can log in

### C. Database Verification
1. In Supabase dashboard, go to **Table Editor**
2. Verify tables were created by Prisma migrations:
   - `User`
   - `Session`
   - `Account`
   - `VerificationToken`
   - And other application tables

---

## Step 5: Optional Configuration

### A. Redis (for rate limiting)
1. In Railway, click **New** → **Service**
2. Select **Redis**
3. Add to your project
4. Set `REDIS_URL` variable to `${{redis.REDIS_URL}}`
5. Redeploy

### B. Email (SMTP)
Set these variables if you need email functionality:
- `SMTP_HOST`
- `SMTP_PORT`
- `SMTP_USER`
- `SMTP_PASS`
- `SMTP_FROM`
- `SMTP_FROM_NAME`

---

## Troubleshooting

### Database Connection Issues
- **Error**: `PrismaClientInitializationError`
- **Fix**: Verify `DATABASE_URL` format and credentials. Test connection with:
  ```bash
  psql postgresql://postgres:[password]@fhmshcgkykosprstnblx.supabase.co:5432/postgres
  ```

### Migration Errors
- **Error**: Migration failed
- **Fix**: The `start.sh` runs `npx prisma migrate deploy` automatically. If it fails:
  1. Check Supabase logs for connection issues
  2. Verify the database user has proper permissions
  3. Manually run migrations: `npx prisma migrate deploy`

### CORS Issues
- **Error**: CORS blocked requests
- **Fix**: Ensure `CORS_ORIGIN` matches your frontend URL exactly (including https://)

---

## Security Reminders

1. **Never commit `.env` files** with actual values
2. **Use Railway's secret generator** for JWT_SECRET, ENCRYPTION_KEY, NEXTAUTH_SECRET
3. **Rotate all exposed credentials** immediately
4. **Enable Railway environment variable encryption** for sensitive values
5. **Restrict Railway project access** to only necessary team members

---

## Useful Commands

### Generate Secrets Locally
```bash
# JWT_SECRET (64-char hex)
openssl rand -hex 32

# ENCRYPTION_KEY (exactly 32 chars)
openssl rand -base64 32 | head -c 32

# NEXTAUTH_SECRET (64-char hex)
openssl rand -hex 32
```

### Test Database Connection
```bash
# Install psql if needed
# Ubuntu/Debian: sudo apt-get install postgresql-client
# Mac: brew install postgresql

psql postgresql://postgres:[YOUR_PASSWORD]@fhmshcgkykosprstnblx.supabase.co:5432/postgres
```

---

## Support

If you encounter issues:
1. Check Railway service logs
2. Check Supabase database logs
3. Verify all environment variables are set correctly
4. Ensure your fork is up to date with upstream changes
