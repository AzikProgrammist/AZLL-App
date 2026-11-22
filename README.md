# AZ Language Learning 🌐

## 1) Supabase (bir marta)
1. supabase.com → New project
2. SQL Editor → `supabase_setup.sql` ni paste qiling → Run
3. Settings → API: `Project URL` va `anon public` key ni `public/index.html` tepasidagi
   `SUPABASE_URL` va `SUPABASE_ANON` ga yozing
4. Authentication → URL Configuration: Site URL = GitHub Pages manzilingiz
5. Admin: `azimbekusmonov0919@gmail.com` bilan o'zingiz ro'yxatdan o'ting (parolni o'zingiz tanlaysiz),
   emailni tasdiqlang — shundan keyin ⚙️ Admin tugmasi chiqadi

## 2) GitHub Pages (veb + PWA)
Repo → Settings → Pages → Source: **GitHub Actions**. `main` ga push qilsangiz avtomatik deploy bo'ladi.

## 3) APK (Play Market'siz, o'zingiz tarqatish uchun)
1. Hamma fayllarni GitHub repo'ga push qiling
2. Repo → **Actions** → **Build Android APK** → **Run workflow**
3. ~5-8 daqiqadan keyin repo → **Releases** → `AZ-Learn.apk` ni yuklab oling
4. Telefonga yuboring (Telegram ham bo'ladi) → ochganda "Noma'lum manbalardan o'rnatish" ruxsatini bering → O'rnating

Eslatma: APK ichida email/parol bilan kirish ishlaydi. Google bilan kirish APK da qo'shimcha sozlash talab qiladi.
