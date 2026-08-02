# Hướng nghiệp AI

Chatbot Flutter trò chuyện bằng tiếng Việt, giúp người học khám phá ngành học phù hợp. Ứng dụng dùng Supabase Auth và gọi Gemini qua Supabase Edge Function.

## Chạy ứng dụng

```bash
flutter pub get
flutter run
```

## Đăng nhập và đăng ký

- Người dùng phải đăng nhập trước khi vào chatbot.
- Đăng ký bằng email, mật khẩu và xác nhận mật khẩu.
- Nếu Supabase bật xác nhận email, người dùng cần mở email xác nhận trước khi đăng nhập.
- Phiên đăng nhập được Supabase lưu và tự khôi phục ở lần mở app tiếp theo.
- Nút đăng xuất nằm trên thanh tiêu đề của màn hình chat.

## Kiến trúc bảo mật

```text
Flutter Web / GitHub Pages → Supabase Auth + Edge Function → Gemini API
```

- Publishable key của Supabase là định danh công khai dành cho ứng dụng phía client.
- Gemini API key không nằm trong Flutter, GitHub Pages hoặc Git; key chỉ được lưu trong Supabase Secret.
- Function `gemini-chat` yêu cầu JWT của người dùng đã đăng nhập.
- Function giữ system prompt và gọi Gemini ở phía server.

## Triển khai Edge Function

```bash
supabase functions deploy gemini-chat --project-ref muygnhhqxsdsmfjrhsag
```

Trong Supabase Dashboard, bảo đảm Email provider đang bật tại **Authentication → Providers**.
