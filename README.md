Rất hay 💪 — để người khác **clone và chạy project 3 Sành web (Flutter + Firebase)** dễ dàng, bạn nên có một file `README.md` rõ ràng, mô tả đầy đủ setup, build, deploy.
Dưới đây là bản README hoàn chỉnh, mình viết theo format chuẩn GitHub (markdown), có thể copy thẳng vào gốc project:

---

## 📄 **README.md**

```markdown
# 🍻 3 SÀNH – Flutter Web + Firebase Restaurant System

> Elegant restaurant web app for menu browsing, online ordering, and table booking.  
> Built with **Flutter Web**, **Firebase Hosting**, **Firestore**, and **Firebase Auth**.

---

## 🚀 Features

- **Home Page:** Hero banner, menu previews, branch info, recruitment section.  
- **Menu Page:** Regional dishes (North, Central, South) with images and price list.  
- **Order Page:** Choose and print order (with PDF export).  
- **Booking Page:** Reserve tables (area, date, time, guest count).  
- **Admin Page:** View live reservations and metrics.  
- **Realtime Metrics:** Firestore logs daily and total visits.  
- **Firebase Hosting:** Optimized for caching and fast load with skeleton loader.

---

## 🧩 Project Structure

```

client_web/
├── lib/
│   ├── main.dart
│   ├── menu_page.dart
│   ├── order_page.dart
│   ├── booking_page.dart
│   ├── admin_page.dart
│   ├── firebase_options.dart
│   └── dev_seed_menu.dart
├── assets/
│   ├── images/ (backgrounds, hero banners)
│   ├── dishes/ (food images)
│   └── menu/ (region covers)
├── firebase.json
├── pubspec.yaml
└── README.md

````

---

## ⚙️ Setup & Run Locally

### 1️⃣ Requirements
- [Flutter SDK](https://flutter.dev/docs/get-started/install) (>=3.16)
- Firebase CLI  
  ```bash
  npm install -g firebase-tools
````

* Node.js & npm installed (check by `node -v` and `npm -v`)

### 2️⃣ Clone project

```bash
git clone https://github.com/<yourusername>/3sanh_web.git
cd 3sanh_web/client_web
```

### 3️⃣ Install dependencies

```bash
flutter pub get
```

### 4️⃣ Run in dev mode

```bash
flutter run -d chrome
```

You can test with:

```
http://localhost:5000
```

> If you see Firestore or Firebase Auth errors, ensure that you have
> initialized Firebase with your own project credentials.

---

## 🔥 Firebase Setup

### 1️⃣ Initialize Firebase (first time only)

```bash
firebase login
firebase init hosting
# → public directory: build/web
# → configure as SPA (Single Page App)? Yes
```

### 2️⃣ Set your project (already linked)

```bash
firebase use --add
# select sanh-9a3b8
```

### 3️⃣ Build and Deploy

```bash
flutter clean
flutter build web --release
firebase deploy --only hosting --project sanh-9a3b8
```

> Deployment URL:
> 🌐 [https://sanh-9a3b8.web.app](https://sanh-9a3b8.web.app)

---

## 📁 Firestore Rules Summary

```js
service cloud.firestore {
  match /databases/{database}/documents {
    // ====== Metrics ======
    match /metrics/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }

    // ====== Areas ======
    match /areas/{id} {
      allow read: if true;
      allow write: if false;
    }

    // ====== Reservations ======
    match /reservations/{id} {
      allow read: if true;
      allow create: if true;
      allow update, delete: if request.auth != null;
    }

    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## ⚡ Optimization Highlights

* **Deferred imports** for pages → smaller JS bundle.
* **Skeleton loading** for hero/menu section.
* **Precached images** (`precacheImage()`) for smooth transitions.
* **firebase.json** optimized:

  ```json
  {
    "headers": [
      {
        "source": "/**/*.@(js|css|wasm|json)",
        "headers": [
          { "key": "Cache-Control", "value": "public,max-age=31536000,immutable" }
        ]
      },
      { "source": "/index.html", "headers": [{ "key": "Cache-Control", "value": "no-cache" }] },
      { "source": "/flutter_service_worker.js", "headers": [{ "key": "Cache-Control", "value": "no-cache" }] }
    ],
    "rewrites": [{ "source": "**", "destination": "/index.html" }]
  }
  ```

---

## 🧠 Tech Stack

| Layer     | Technology                   |
| --------- | ---------------------------- |
| Frontend  | Flutter (Web)                |
| Routing   | go_router                    |
| Backend   | Firebase Firestore + Auth    |
| Hosting   | Firebase Hosting             |
| CI/CD     | Firebase CLI                 |
| Analytics | Firestore Metrics Collection |

---

## 👨‍💻 Developer Notes

* Anonymous users can view menus and make bookings.
* Only authenticated users (admins) can manage areas/reservations.
* Firestore metrics auto-log daily + total views.
* All image assets are `.webp` for better performance.
* Skeleton loader & caching greatly reduce initial load time.

---

## 🧑‍🍳 Author

**Nguyễn Dương Tùng**
📧 Contact: [[duongtung@example.com](mailto:duongtung@example.com)]
📍 Project ID: `sanh-9a3b8`
🌐 Live site: [https://sanh-9a3b8.web.app](https://sanh-9a3b8.web.app)

---

## 📜 License

This project is licensed under the MIT License – feel free to fork, modify, and deploy your own version.

```

---

## ✅ Hướng dẫn sử dụng
- Copy toàn bộ đoạn trên, lưu vào gốc project với tên **`README.md`**.  
- Khi bạn push lên GitHub, trang repo sẽ tự hiển thị phần hướng dẫn đầy đủ.  
- Nếu muốn, mình có thể giúp bạn tạo **badge đẹp (build, deploy, Flutter version, live demo)** cho phần đầu README để repo nhìn chuyên nghiệp hơn — bạn muốn mình thêm phần đó không?
```
