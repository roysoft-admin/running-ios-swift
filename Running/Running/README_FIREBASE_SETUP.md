# Firebase 설정 가이드

## 1. Firebase 프로젝트 생성

1. [Firebase Console](https://console.firebase.google.com/)에 접속
2. 새 프로젝트 생성 또는 기존 프로젝트 선택
3. iOS 앱 추가
   - Bundle ID: `com.yourcompany.Running` (실제 Bundle ID로 변경)
   - App nickname: Running

## 2. GoogleService-Info.plist 다운로드

1. Firebase Console에서 `GoogleService-Info.plist` 파일 다운로드
2. Xcode 프로젝트의 `Running` 폴더에 추가
3. "Copy items if needed" 체크
4. Target에 추가 확인

## 3. CocoaPods 또는 SPM으로 의존성 추가

### CocoaPods 사용 시:

`Podfile`에 다음 추가:
```ruby
pod 'Firebase/Auth'
pod 'Firebase/Core'
pod 'GoogleSignIn'
```

터미널에서 실행:
```bash
pod install
```

### Swift Package Manager 사용 시:

1. Xcode에서 File > Add Packages...
2. 다음 URL 추가:
   - `https://github.com/firebase/firebase-ios-sdk`
   - `https://github.com/google/GoogleSignIn-iOS`
3. 다음 패키지 선택:
   - FirebaseAuth
   - FirebaseCore
   - GoogleSignIn

## 4. Info.plist 설정

### URL Scheme 추가 (Google Sign-In용)

1. Xcode에서 `Info.plist` 열기
2. `URL Types` 추가:
   - `REVERSED_CLIENT_ID` 값을 `GoogleService-Info.plist`에서 찾아서 추가

또는 `Info.plist`에 직접 추가:
```xml
<key>CFBundleURLTypes</key>
<array>
    <dict>
        <key>CFBundleTypeRole</key>
        <string>Editor</string>
        <key>CFBundleURLSchemes</key>
        <array>
            <string>com.googleusercontent.apps.YOUR_CLIENT_ID</string>
        </array>
    </dict>
</array>
```

## 5. Sign in with Apple 설정

1. Apple Developer Console에서 App ID 설정
   - Capabilities > Sign in with Apple 활성화
2. Xcode에서 프로젝트 설정
   - Signing & Capabilities > + Capability > Sign in with Apple 추가

## 6. RunningApp.swift 수정

`RunningApp.swift`의 `init()` 메서드에서 주석 해제:
```swift
init() {
    FirebaseApp.configure()
}
```

## 7. 테스트

1. 앱 실행
2. Google 로그인 버튼 클릭
3. Apple 로그인 버튼 클릭 (실제 기기에서만 테스트 가능)

## 주의사항

- Google Sign-In은 시뮬레이터에서도 작동합니다
- Apple Sign-In은 실제 기기에서만 테스트 가능합니다
- Firebase Console에서 Authentication > Sign-in method에서 Google과 Apple을 활성화해야 합니다


