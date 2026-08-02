# Hướng nghiệp AI

Chatbot Flutter trò chuyện bằng tiếng Việt, giúp người học khám phá ngành học phù hợp. Ứng dụng gọi trực tiếp Gemini API qua HTTP và duy trì lịch sử hội thoại theo role `user` / `model`.

## Chạy dự án

1. Tạo API key trong [Google AI Studio](https://aistudio.google.com/app/apikey).
2. Cài dependencies:

   ```bash
   flutter pub get
   ```

3. Chạy app với API key qua Dart define:

   ```bash
   flutter run --dart-define=GEMINI_API_KEY=your_key
   ```

Tùy chọn đổi model:

```bash
flutter run --dart-define=GEMINI_API_KEY=your_key --dart-define=GEMINI_MODEL=gemini-3.1-flash-lite
```

> Không ghi hoặc commit API key vào source. Khi phát hành ứng dụng, hãy chuyển cuộc gọi Gemini qua backend an toàn.

## Tính năng

- Tin nhắn bong bóng phân biệt người học và trợ lý.
- Trợ lý hỏi về sở thích, môn học thế mạnh và tính cách trước khi gợi ý 2–3 ngành học kèm lý do, khối xét tuyển phổ biến.
- Từ chối lịch sự các nội dung ngoài phạm vi hướng nghiệp.
- Loading trong khi Gemini phản hồi; ô nhập và nút gửi được khóa trong lúc chờ.
- Tự cuộn đến tin nhắn mới nhất, có thông báo lỗi dễ hiểu và không làm ứng dụng crash.
