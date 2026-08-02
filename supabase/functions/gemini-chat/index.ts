const allowedOrigins = new Set([
  'https://nguyenvietthuc1001.github.io',
]);

const systemPrompt = `Bạn là tư vấn viên hướng nghiệp cho học sinh, sinh viên tại Việt Nam. Luôn trả lời bằng tiếng Việt, thân thiện và thực tế.

Trước khi đưa ra kết luận hoặc gợi ý ngành, hãy hỏi ngược để hiểu ít nhất các thông tin còn thiếu về: sở thích, môn học thế mạnh và tính cách/phong cách làm việc. Mỗi lượt chỉ nên hỏi 1–3 câu rõ ràng, không lặp lại điều người học đã nói.

Khi đã đủ thông tin, gợi ý đúng 2–3 ngành học. Với từng ngành, nêu lý do phù hợp và các khối xét tuyển phổ biến tại Việt Nam; nhắc người học kiểm tra đề án tuyển sinh chính thức vì tổ hợp có thể thay đổi. Không khẳng định chắc chắn về điểm chuẩn, việc làm hoặc khả năng trúng tuyển.

Chỉ tư vấn các nội dung liên quan đến hướng nghiệp, ngành học, năng lực, lựa chọn nghề và lộ trình học. Nếu người dùng hỏi chủ đề ngoài phạm vi này, hãy lịch sự từ chối ngắn gọn và mời họ quay lại với một câu hỏi hướng nghiệp.`;

type ConversationMessage = {
  role: 'user' | 'model';
  text: string;
};

function corsHeaders(request: Request) {
  const origin = request.headers.get('origin') ?? '';
  const isLocalhost = /^http:\/\/localhost(?::\d+)?$/.test(origin);
  const allowedOrigin =
    allowedOrigins.has(origin) || isLocalhost
      ? origin
      : 'https://nguyenvietthuc1001.github.io';

  return {
    'Access-Control-Allow-Origin': allowedOrigin,
    'Access-Control-Allow-Headers': 'authorization, apikey, content-type',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    Vary: 'Origin',
  };
}

function json(
  request: Request,
  payload: Record<string, unknown>,
  status = 200,
) {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders(request),
      'Content-Type': 'application/json; charset=utf-8',
    },
  });
}

function isValidMessage(value: unknown): value is ConversationMessage {
  if (typeof value !== 'object' || value === null) return false;
  const message = value as Record<string, unknown>;
  return (
    (message.role === 'user' || message.role === 'model') &&
    typeof message.text === 'string' &&
    message.text.trim().length > 0 &&
    message.text.length <= 2000
  );
}

Deno.serve(async (request) => {
  if (request.method === 'OPTIONS') {
    return new Response('ok', { headers: corsHeaders(request) });
  }

  if (request.method !== 'POST') {
    return json(request, { error: 'Chỉ hỗ trợ yêu cầu POST.' }, 405);
  }

  try {
    const body = await request.json();
    const messages = body?.messages;
    if (
      !Array.isArray(messages) ||
      messages.length == 0 ||
      messages.length > 20 ||
      !messages.every(isValidMessage)
    ) {
      return json(request, { error: 'Dữ liệu hội thoại không hợp lệ.' }, 400);
    }

    const geminiKey = Deno.env.get('GEMINI_API_KEY');
    if (!geminiKey) {
      console.error('GEMINI_API_KEY is not configured.');
      return json(request, { error: 'Máy chủ chưa được cấu hình AI.' }, 500);
    }

    const geminiResponse = await fetch(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-3.1-flash-lite:generateContent',
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          'x-goog-api-key': geminiKey,
        },
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: systemPrompt }] },
          contents: messages.map((message) => ({
            role: message.role,
            parts: [{ text: message.text }],
          })),
          generationConfig: { temperature: 0.7, maxOutputTokens: 700 },
        }),
      },
    );

    const geminiBody = await geminiResponse.json();
    if (!geminiResponse.ok) {
      console.error('Gemini request failed:', geminiBody);
      const upstreamMessage =
        geminiBody?.error?.message ?? 'Gemini không thể xử lý yêu cầu này.';
      return json(request, { error: upstreamMessage }, geminiResponse.status);
    }

    const text = geminiBody?.candidates?.[0]?.content?.parts
      ?.map((part: { text?: string }) => part.text ?? '')
      .join('')
      .trim();

    if (!text) {
      return json(
        request,
        { error: 'Gemini chưa trả về phản hồi phù hợp.' },
        502,
      );
    }

    return json(request, { text });
  } catch (error) {
    console.error('gemini-chat failed:', error);
    return json(
      request,
      { error: 'Không thể xử lý yêu cầu. Bạn thử lại nhé.' },
      500,
    );
  }
});
