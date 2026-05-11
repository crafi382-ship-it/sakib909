# ChatApp — Flutter Real-Time Chat

A full-featured WhatsApp-style chat app built with Flutter, Supabase, and ZegoCloud.

## What's Included

- Email/OTP signup + login
- **Permanent session** — never logged out (credentials stored securely)
- **Forgot Password** — email OTP → set new password
- Real-time 1:1 messaging (Supabase Realtime)
- **Voice calls** via ZegoCloud
- **Video calls** via ZegoCloud
- Image, video, audio, PDF, document sharing
- Typing indicators + read receipts (double blue tick)
- Message reply + delete for me / everyone
- Offline message queue (auto-sends when back online)
- Push notifications via OneSignal
- Dark mode
- Online/last seen status

## Build Steps

```bash
flutter clean
flutter pub get
flutter build apk
```

APK → `build/app/outputs/flutter-apk/app-release.apk`

## Supabase Setup

1. Create project at [supabase.com](https://supabase.com)
2. SQL Editor → paste `supabase_setup.sql` → Run
3. Storage → create two **Public** buckets: `profile-images` and `chat-files`
4. Authentication → Settings → enable **Email OTP** (for forgot password to send 6-digit codes)

## local.properties (adjust paths to match your machine)

```
sdk.dir=C:\Android\Sdk
flutter.sdk=C:\flutter
```

## ZegoCloud Calls

AppID and AppSign are already configured in `lib/constants/supabase_constants.dart`.

- Voice call: tap the phone icon in any chat
- Video call: tap the video icon in any chat

Both users must be in the app for the call to connect (no call invitation ring yet).

## Gradle Versions

- Android Gradle Plugin: **8.9.1**
- Kotlin: **2.1.0**
- Gradle wrapper: **8.13**

## OneSignal Push

1. Sign up at [onesignal.com](https://onesignal.com) → create Android app
2. Copy App ID into `supabase_constants.dart` (already set)
3. Copy REST API Key into `restApiKey` field in the same file
