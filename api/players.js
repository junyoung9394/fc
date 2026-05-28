const cache = {
  players: null,
  seasons: null,
  loadedAt: 0,
};

async function fetchJson(url) {
  const response = await fetch(url);
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

export default async function handler(req, res) {
  const query = String(req.query.q || "").trim().toLowerCase();
  const limit = Math.min(Number(req.query.limit || 10), 20);

  if (!query) {
    res.status(400).json({ message: "검색어가 필요합니다." });
    return;
  }

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

    res.status(200).json({ players: matches });
  } catch (error) {
    res.status(502).json({ message: `넥슨 메타데이터 조회 실패: ${error.message}` });
  }
}
