import http from "node:http";
import { readFile } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";

const root = path.dirname(fileURLToPath(import.meta.url));
const port = Number(process.env.PORT || 4173);
const types = {
  ".html": "text/html;charset=utf-8",
  ".css": "text/css;charset=utf-8",
  ".js": "text/javascript;charset=utf-8",
};

const cache = {
  players: null,
  seasons: null,
  loadedAt: 0,
};

function sendJson(res, status, body) {
  res.writeHead(status, { "Content-Type": "application/json;charset=utf-8" });
  res.end(JSON.stringify(body));
}

async function readJsonBody(req) {
  let body = "";
  for await (const chunk of req) body += chunk;
  return body ? JSON.parse(body) : {};
}

async function fetchJson(url, headers = {}) {
  const response = await fetch(url, { headers });
  if (!response.ok) {
    const text = await response.text();
    throw new Error(`${response.status} ${text}`);
  }
  return response.json();
}

async function loadMeta() {
  const fresh = cache.players && cache.seasons && Date.now() - cache.loadedAt < 1000 * 60 * 60;
  if (fresh) return cache;

  const [players, seasons] = await Promise.all([
    fetchJson("https://open.api.nexon.com/static/fconline/meta/spid.json"),
    fetchJson("https://open.api.nexon.com/static/fconline/meta/seasonid.json"),
  ]);

  cache.players = players;
  cache.seasons = seasons;
  cache.loadedAt = Date.now();
  return cache;
}

function seasonIdFromSpid(spid) {
  return Math.floor(Number(spid) / 1000000);
}

function normalizeSeason(season) {
  return season.className || season.seasonName || season.name || String(season.seasonId);
}

async function handlePlayerSearch(req, res, url) {
  const query = (url.searchParams.get("q") || "").trim().toLowerCase();
  const limit = Math.min(Number(url.searchParams.get("limit") || 10), 20);
  if (!query) return sendJson(res, 400, { message: "검색어가 필요합니다." });

  try {
    const { players, seasons } = await loadMeta();
    const seasonMap = new Map(seasons.map((season) => [Number(season.seasonId), normalizeSeason(season)]));
    const matches = players
      .filter((player) => String(player.name || "").toLowerCase().includes(query))
      .sort((a, b) => {
        const aExact = String(a.name || "").toLowerCase() === query ? 0 : 1;
        const bExact = String(b.name || "").toLowerCase() === query ? 0 : 1;
        return aExact - bExact || Number(b.id) - Number(a.id);
      })
      .slice(0, limit)
      .map((player) => {
        const seasonId = seasonIdFromSpid(player.id);
        return {
          spid: player.id,
          name: player.name,
          seasonId,
          seasonName: seasonMap.get(seasonId) || "",
          imageUrl: `https://open.api.nexon.com/live/externalAssets/common/players/p${player.id}.png`,
        };
      });

    sendJson(res, 200, { players: matches });
  } catch (error) {
    sendJson(res, 502, { message: `넥슨 메타데이터 조회 실패: ${error.message}` });
  }
}

async function handlePrice(req, res) {
  sendJson(res, 501, {
    message: "넥슨 공식 Open API에는 FC온라인 거래소 상한가 조회 엔드포인트가 공개되어 있지 않습니다.",
  });
}

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

async function handleKakaoSend(req, res) {
  try {
    const { kakaoKey, refreshToken, text } = await readJsonBody(req);
    if (!kakaoKey || !refreshToken || !text) {
      return sendJson(res, 400, { message: "kakaoKey, refreshToken, text가 필요합니다." });
    }

    const token = await refreshKakaoAccessToken(kakaoKey, refreshToken);
    const sent = await sendKakaoMemo(token.access_token, text);
    sendJson(res, 200, {
      ok: true,
      result: sent,
      refreshToken: token.refresh_token || null,
    });
  } catch (error) {
    sendJson(res, 502, { message: error.message });
  }
}

async function serveStatic(res, pathname) {
  const requested = pathname === "/" ? "index.html" : pathname.slice(1);
  const file = path.resolve(root, requested);

  if (!file.startsWith(root)) {
    res.writeHead(403);
    res.end("Forbidden");
    return;
  }

  try {
    const body = await readFile(file);
    res.writeHead(200, { "Content-Type": types[path.extname(file)] || "application/octet-stream" });
    res.end(body);
  } catch {
    res.writeHead(404);
    res.end("Not found");
  }
}

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url || "/", `http://127.0.0.1:${port}`);

  if (req.method === "GET" && url.pathname === "/api/players") {
    await handlePlayerSearch(req, res, url);
    return;
  }
  if (req.method === "GET" && url.pathname === "/api/price") {
    await handlePrice(req, res, url);
    return;
  }
  if (req.method === "POST" && url.pathname === "/api/kakao/send") {
    await handleKakaoSend(req, res);
    return;
  }

  await serveStatic(res, url.pathname);
});

server.listen(port, "127.0.0.1", () => {
  console.log(`FC온라인 매물 알림: http://127.0.0.1:${port}`);
});
