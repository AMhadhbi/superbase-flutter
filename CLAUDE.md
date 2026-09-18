# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Commands

The Flutter SDK is installed at `/root/develop/flutter` but is not on `PATH` in this environment — prefix commands with the full path, or add it to `PATH` first.

```bash
# Install/update dependencies
/root/develop/flutter/bin/flutter pub get

# Static analysis (must be clean before committing)
/root/develop/flutter/bin/flutter analyze

# Run all tests
/root/develop/flutter/bin/flutter test

# Run a single test file
/root/develop/flutter/bin/flutter test test/some_test.dart

# Run the app (device/emulator/web target required)
/root/develop/flutter/bin/flutter run

# Add a dependency
/root/develop/flutter/bin/flutter pub add <package>
```

Flutter will warn about running as root ("Woah! You appear to be trying to run flutter as root") — this is expected in this environment and can be ignored.

## Architecture

This is a Flutter app backed by Supabase (`supabase_flutter`), following the auth flow from Supabase's Flutter quickstart:

- **`lib/main.dart`** — calls `Supabase.initialize` before `runApp`, exposes a module-level `supabase` client instance (`Supabase.instance.client`) that every page imports rather than re-fetching the instance.
- **`lib/pages/splash_page.dart`** — the app's initial route. Checks `supabase.auth.currentSession` and subscribes to `onAuthStateChange` to redirect to `LoginPage` or `AccountPage` accordingly. Any new top-level auth-gated flow should hook into this redirect logic rather than duplicating session checks elsewhere.
- **`lib/pages/login_page.dart`** — magic-link (OTP) email sign-in via `signInWithOtp`; no password field. Also listens to `onAuthStateChange` itself to redirect once the link is followed.
- **`lib/pages/account_page.dart`** — reads/writes the current user's row in the `profiles` table and handles avatar upload: picks an image with `image_picker`, uploads it to the `avatars` Storage bucket under `<user_id>/<timestamp>.<ext>`, stores the storage path (not a public URL) in `profiles.avatar_url`, and displays it via `createSignedUrl` since the bucket is private.
- **`lib/utils/constants.dart`** — Supabase project URL and publishable (`sb_publishable_...`) key, plus the `avatarsBucket` name constant. The publishable key is safe for client code. **Never** put the Postgres connection string or a `service_role` key here or anywhere in this app — only server-side tooling should hold those.

### Backend (Supabase project `yfsgybexuxhbcgjsgijb`)

The Dart code assumes this existing schema — check the live project via the Supabase MCP tools before changing table/bucket names or upload paths:

- `public.profiles` (`id` references `auth.users.id`, `username`, `full_name`, `avatar_url`, `website`, `updated_at`). RLS: anyone can `SELECT`; a user can `INSERT`/`UPDATE` only their own row (`auth.uid() = id`).
- `storage` bucket `avatars` (private, not public). RLS on `storage.objects`: any authenticated caller can `INSERT` into this bucket and can read (`SELECT`) avatar objects — hence the app uses `createSignedUrl` rather than a public URL to render avatars.

Schema/RLS changes belong in Supabase migrations (via the `supabase` MCP tools or the CLI), not as ad hoc SQL — the client code's assumptions above must stay in sync with whatever the migrations produce.
