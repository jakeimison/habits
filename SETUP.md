# Leaderboard setup (one time, about 10 minutes)

The leaderboard, accounts and cloud backup use **Supabase**, a free hosted database.
Only you (the person running the app) do this. Your mates just create an account in the app.

## 1. Create a Supabase project
1. Go to **supabase.com**, then **Start your project**, and sign in with your GitHub account.
2. Click **New project**.
   - Name: `habits`
   - Database password: click **Generate** and save it in your password manager. The app never needs it.
   - Region: **West EU (London)**
3. Click **Create new project** and wait about 2 minutes for it to finish setting up.

## 2. Create the tables
1. In the left sidebar, open **SQL Editor**, then click **New query**.
2. Open `supabase.sql` from this folder, copy all of it, paste it in and click **Run**.
3. You should see **"Success. No rows returned"**. It's safe to run again if you're unsure.

## 3. Sign-in settings
1. Open **Authentication**, then **Sign In / Providers**, then **Email**.
   - Turn **Confirm email** **off** if you want mates to be able to sign up instantly. This is the easiest option for a trial.
   - If you leave it on, people have to tap a link in an email before they can sign in.
2. Open **Authentication**, then **URL Configuration**.
   - Set **Site URL** to your app's address, e.g. `https://YOUR-USERNAME.github.io/habits/`.
   - This makes password-reset and confirmation emails link back to the app.

## 4. Connect the app
1. Open **Project Settings**, then **API** (on newer dashboards this may be under **API Keys** or **Data API**).
2. Copy the **Project URL** (it looks like `https://abcdefgh.supabase.co`).
3. Copy the **anon / public** key. Newer projects call this the **publishable** key, starting `sb_publishable_`. Either works.
   - **Never** use the `service_role` or `secret` key. That one must stay private.
4. Open `config.js` and paste both between the quotes:
   ```js
   window.HABITS_CONFIG = {
     supabaseUrl: "https://abcdefgh.supabase.co",
     supabaseAnonKey: "PASTE-THE-ANON-OR-PUBLISHABLE-KEY"
   };
   ```
5. Upload `config.js` (and the other updated files) to your GitHub repo, then commit.

## 5. Try it
Open the app, go to **Friends**, then **Create account**. You'll get a 6-character friend code to share.
When a mate enters your code, you both appear on each other's leaderboard.

## Good to know
- **Is the key safe to publish?** Yes, the anon/publishable key is designed to be public. The security rules in `supabase.sql` make sure people can only see themselves and their friends, edit only their own scores, and read only their own backup.
- **Free plan pause:** free projects pause after a week with no activity. Daily use keeps it awake. If it ever pauses, open the Supabase dashboard and click **Restore**.
- **Cheating:** scores are calculated on each phone, so a determined person could fake theirs. That's fine among friends; stopping it would need server-side scoring.
- **Deleting someone:** in Supabase, open **Authentication**, then **Users**, and delete them. Their profile, scores and backup are removed with them.
