/// Supabase project credentials.
///
/// The publishable key is safe to ship in client code — it only allows
/// what your Row Level Security policies permit. Never put the Postgres
/// connection string or a service_role key in this app.
const supabaseUrl = 'https://yfsgybexuxhbcgjsgijb.supabase.co';
const supabasePublishableKey = 'sb_publishable_Zm87h5-i3B5GcJGqHnSpkw_AG9jpTST';

const avatarsBucket = 'avatars';

/// Custom URL scheme registered in ios/Runner/Info.plist (CFBundleURLTypes)
/// and android/app/src/main/AndroidManifest.xml, used to deep-link back into
/// the app from the magic-link email.
const authCallbackUrl = 'com.example.supabasephotoapp://login-callback/';
