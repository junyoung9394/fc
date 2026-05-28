async function refreshKakaoAccessToken(kakaoKey, refreshToken) {
  const body = new URLSearchParams({
    grant_type: "refresh_token",
    client_id: kakaoKey,
    refresh_token: refreshToken,
  });

  const response = await fetch("https://kauth.kakao.com/oauth/token", {
    method: "POST",
    headers: { "Content-Type": "application/x-www-form-urlencoded;charset=utf-8" },
    body,
  });
  const data = await response.json();
  if (!response.ok) throw new Error(data.error_description || "access token 갱신 실패");
  return data;
}

async function sendKakaoMemo(accessToken, text) {
  const template = {
    object_type: "text",
    text,
    link: {
      web_url: "https://fconline.nexon.com",
      mobile_web_url: "https://fconline.nexon.com",
    },
    button_title: "FC온라인 열기",
  };

  const body = new URLSearchParams({
    template_object: JSON.stringify(template),
  });

  const response = await fetch("https://kapi.kakao.com/v2/api/talk/memo/default/send", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${accessToken}`,
      "Content-Type": "application/x-www-form-urlencoded;charset=utf-8",
    },
    body,
  });
  const data = await response.json();
  if (!response.ok) throw new Error(data.msg || data.message || "카카오 메시지 전송 실패");
  return data;
}

export default async function handler(req, res) {
  if (req.method !== "POST") {
    res.status(405).json({ message: "POST만 지원합니다." });
    return;
  }

  try {
    const { text } = req.body || {};
    const kakaoKey = process.env.KAKAO_REST_API_KEY;
    const refreshToken = process.env.KAKAO_REFRESH_TOKEN;
    if (!kakaoKey || !refreshToken || !text) {
      res.status(400).json({ message: "서버에 카카오 환경값이 설정되어 있지 않습니다." });
      return;
    }

    const token = await refreshKakaoAccessToken(kakaoKey, refreshToken);
    const sent = await sendKakaoMemo(token.access_token, text);
    res.status(200).json({
      ok: true,
      result: sent,
      refreshToken: token.refresh_token || null,
    });
  } catch (error) {
    res.status(502).json({ message: error.message });
  }
}
