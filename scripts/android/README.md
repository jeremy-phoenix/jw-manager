# Android signing helpers

These scripts create and reuse the Android upload keystore used by local release builds and GitHub Actions.

Run from the repository root:

```powershell
.\scripts\android\New-AndroidUploadKeystore.ps1
```

The script creates:

- `congregation_manager/android/app/upload-keystore.p12`
- `congregation_manager/android/key.properties`

Both files are ignored by the existing Android `.gitignore` and should stay private.

Add these GitHub repository secrets under `Settings` > `Secrets and variables` > `Actions`:

```text
ANDROID_KEYSTORE_BASE64
ANDROID_KEYSTORE_PASSWORD
ANDROID_KEY_ALIAS
ANDROID_KEY_PASSWORD
```

`New-AndroidUploadKeystore.ps1` copies `ANDROID_KEYSTORE_BASE64` to the clipboard after creating the keystore. To copy it again later, run:

```powershell
.\scripts\android\Copy-AndroidKeystoreSecret.ps1
```

Keep a private backup of `upload-keystore.p12` and the passwords. If you publish through Google Play App Signing, this should usually be your upload key.