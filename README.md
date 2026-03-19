# SM - Nhom 6 | Student Manager App

Ung dung quan ly sinh vien su dung Flutter, Provider va Firebase (Auth + Firestore), tap trung vao quan ly ho so sinh vien, diem/GPA, thong ke va canh bao hoc vu theo thoi gian thuc.

## 1. Tong quan tinh nang

- Dang nhap bang Firebase Authentication (Email/Password).
- Dashboard realtime danh sach sinh vien tu Firestore.
- Tim kiem theo ten hoac MSSV.
- Loc theo khoa, khoa hoc, GPA toi thieu, hoc luc.
- Thong ke nhanh:
  - Tong so sinh vien
  - Sinh vien hoc bong
  - Sinh vien canh bao
- Them, sua, xoa sinh vien.
- Quan ly mon hoc cho tung sinh vien (them/sua/xoa).
- Tu dong tinh lai GPA sau khi cap nhat mon hoc.
- Chi tiet sinh vien voi bieu do:
  - Bar chart: diem trung binh theo hoc ky
  - Pie chart: phan bo diem A/B/C/D/F
- Man hinh thong ke nang cao:
  - Loc nang cao theo khoa/khoa hoc/hoc luc
  - Thong bao sinh nhat trong thang
  - Thong bao sinh vien no hoc phi
- Danh sach sinh vien hoc bong va sinh vien canh bao hoc vu.
- Ho tro goi dien nhanh tu dashboard (url_launcher).

## 2. Cong nghe su dung

- Flutter (SDK constraint: ^3.11.1)
- Dart
- Provider
- Firebase Core
- Firebase Auth
- Cloud Firestore
- fl_chart
- intl
- uuid
- flutter_slidable
- url_launcher

## 3. Cau truc thu muc chinh

```text
lib/
	main.dart
	firebase_options.dart
	models/
		student_model.dart
		subject_model.dart
	providers/
		auth_provider.dart
		student_provider.dart
	services/
		auth_service.dart
		firestore_service.dart
	utils/
		app_constants.dart
		gpa_utils.dart
		validators.dart
	views/
		login_screen.dart
		dashboard_screen.dart
		student_upsert_screen.dart
		student_detail_screen.dart
		student_group_screen.dart
		analytics_screen.dart
	widgets/
test/
	widget_test.dart
```

## 4. Kien truc va luong du lieu

- UI layer: cac man hinh trong `views/` + widget tai su dung trong `widgets/`.
- State management: `AuthProvider`, `StudentProvider`.
- Data access:
  - `AuthService`: lam viec voi FirebaseAuth.
  - `FirestoreService`: CRUD sinh vien va mon hoc tren Firestore.
- Domain model:
  - `StudentModel`
  - `SubjectModel`
- Business rules:
  - `GpaUtils` (quy doi GPA, hoc luc, thong ke)
  - `Validators` (validate form).

## 5. Firestore data model

### Collection `students`

Moi document sinh vien gom cac truong chinh:

- `id` (String)
- `name` (String)
- `mssv` (String)
- `email` (String)
- `phone` (String)
- `className` (String)
- `faculty` (String)
- `course` (String)
- `birthDate` (Timestamp)
- `gpa10` (double)
- `gpa4` (double)
- `gender` (String)
- `hasUnpaidTuition` (bool)
- `updatedAt` (server timestamp)

### Subcollection `students/{studentId}/subjects`

Moi document mon hoc gom:

- `id` (String)
- `name` (String)
- `credits` (int)
- `score` (double)
- `semester` (String)

## 6. Quy tac nghiep vu

### 6.1 Quy doi GPA 10 -> GPA 4

| GPA thang 10 | GPA thang 4 |
| ------------ | ----------- |
| >= 8.5       | 4.0         |
| >= 8.0       | 3.5         |
| >= 7.0       | 3.0         |
| >= 6.5       | 2.5         |
| >= 5.5       | 2.0         |
| >= 5.0       | 1.5         |
| >= 4.0       | 1.0         |
| < 4.0        | 0.0         |

### 6.2 Xep loai hoc luc (theo GPA 4)

- Xuat sac: > 3.6
- Gioi: >= 3.2
- Kha: >= 2.5
- Trung binh: >= 1.0
- Yeu: < 1.0

### 6.3 Dieu kien nhom dac biet

- Hoc bong: GPA 4 >= 3.2
- Canh bao hoc vu: GPA 4 < 1.0

### 6.4 Validation chinh

- Email sinh vien phai ket thuc bang `@gmail.com` hoac `@wru.vn`.
- MSSV toi thieu 6 ky tu.
- Mat khau dang nhap toi thieu 6 ky tu.
- Diem/GPA thang 10 nam trong khoang 0 -> 10.

## 7. Huong dan cai dat va chay

### Dieu kien tien quyet

- Flutter SDK phu hop voi `sdk: ^3.11.1`
- Tai khoan Firebase va da bat:
  - Authentication (Email/Password)
  - Cloud Firestore

### Cai dat

1. Tai source code.
2. Cai dependency:

```bash
flutter pub get
```

3. Kiem tra cau hinh Firebase:

- Du an da co `lib/firebase_options.dart` va `android/app/google-services.json`.
- Neu can doi Firebase project khac, chay lai FlutterFire configure.

4. Chay app:

```bash
flutter run
```

### Dang nhap

- Ung dung khong hardcode tai khoan admin.
- Can tao user Email/Password trong Firebase Authentication de dang nhap.

## 8. Kiem thu

Du an hien co smoke test co ban:

```bash
flutter test
```

## 9. Build

Vi du build Android APK:

```bash
flutter build apk
```

Vi du build web:

```bash
flutter build web
```

## 10. Ghi chu

- Ten ung dung hien thi: `SM - Nhom 6`.
- Neu gap loi Firebase luc khoi tao, app se hien man hinh bao loi khoi tao.
- De dam bao realtime update, du lieu Firestore duoc stream truc tiep tu collection `students`.
