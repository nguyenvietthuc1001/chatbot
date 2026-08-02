# Hướng nghiệp AI

Chatbot Flutter trò chuyện bằng tiếng Việt, giúp người học khám phá ngành học phù hợp. Flutter Web gọi Supabase Edge Function; Gemini API key chỉ lưu trong Supabase Secret.

## Chạy ứng dụng

```bash
flutter pub get
flutter run
```

## Kiến trúc bảo mật

```text
Flutter Web / GitHub Pages → Supabase Edge Function → Gemini API
```

- Không có Gemini API key trong Flutter, GitHub Pages hoặc Git.
- Function `gemini-chat` giữ system prompt và gọi Gemini ở phía server.
- Endpoint hiện là public để người dùng chưa đăng nhập có thể chat. Trước khi phát hành rộng rãi, nên thêm Supabase Auth và rate limiting để hạn chế lạm dụng.

## Triển khai Edge Function

```bash
supabase functions deploy gemini-chat --project-ref muygnhhqxsdsmfjrhsag
```
