# INJAZ Lebanon — Khuta Career Portal
## Cloudflare Pages Deployment (100% Free)

## File Structure
  index.html              Full portal
  supabase_schema.sql     Run once in Supabase SQL editor
  functions/
    claude.js             Proxies Anthropic AI (keeps key secret)
    config.js             Serves Supabase credentials securely

---

## STEP 1 — Upload to GitHub
1. Go to your GitHub repo (fouadmansour30788-maker/injaz-lebanon-portal)
2. Delete all existing files
3. Upload all files from this package (including the functions/ folder)
4. Commit changes

## STEP 2 — Deploy on Cloudflare Pages
1. Go to pages.cloudflare.com → sign up free
2. Create a project → Connect to Git → Connect GitHub
3. Select injaz-lebanon-portal repository
4. Build settings:
   - Build command: (leave empty)
   - Output directory: .  (just a dot)
5. Click Save and Deploy

## STEP 3 — Add Environment Variables
1. Cloudflare Pages → your project → Settings → Environment variables
2. Add these 3 variables (for Production):

   ANTHROPIC_API_KEY   =  sk-ant-your-key
   SUPABASE_URL        =  https://your-project.supabase.co
   SUPABASE_ANON_KEY   =  eyJ... (publishable key)

3. Click Save → go to Deployments → Retry deployment

## STEP 4 — Create Your Admin Account
1. Open your live site (yoursite.pages.dev)
2. Click Join Program → register with your email
3. Go to Supabase Dashboard → Table Editor → profiles
4. Find your row → change role to: admin
5. Log out and log back in

## Free Tier Limits
   Cloudflare Pages    Unlimited bandwidth, 500 builds/month
   Supabase DB         500MB storage
   Supabase Auth       50,000 users/month
   Anthropic AI        $5 free credit
   Total cost          $0/month
