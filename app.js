const storageKey = "fconline-market-watch";

const state = {
  items: [],
  logs: [],
  selectedPlayer: null,
  settings: {
    nexonKey: "",
    kakaoKey: "",
    refreshToken: "",
    intervalSeconds: 30,
  },
  timer: null,
};

const els = {
  form: document.querySelector("#searchForm"),
  playerName: document.querySelector("#playerName"),
  searchPlayers: document.querySelector("#searchPlayers"),
  searchResults: document.querySelector("#searchResults"),
  seasonName: document.querySelector("#seasonName"),
  grade: document.querySelector("#grade"),
  upperPrice: document.querySelector("#upperPrice"),
  threshold: document.querySelector("#threshold"),
  watchRows: document.querySelector("#watchRows"),
  emptyState: document.querySelector("#emptyState"),
  rowTemplate: document.querySelector("#rowTemplate"),
  checkButton: document.querySelector("#checkButton"),
  toggleRunButton: document.querySelector("#toggleRunButton"),
  runStatus: document.querySelector("#runStatus"),
  nexonKey: document.querySelector("#nexonKey"),
  kakaoKey: document.querySelector("#kakaoKey"),
  refreshToken: document.querySelector("#refreshToken"),
  intervalSeconds: document.querySelector("#intervalSeconds"),
  saveSettings: document.querySelector("#saveSettings"),
  sampleButton: document.querySelector("#sampleButton"),
  alertLog: document.querySelector("#alertLog"),
  clearLog: document.querySelector("#clearLog"),
};

function load() {
  const saved = localStorage.getItem(storageKey);
  if (!saved) return;

  try {
    const parsed = JSON.parse(saved);
    state.items = parsed.items || [];
    state.logs = parsed.logs || [];
    state.settings = { ...state.settings, ...(parsed.settings || {}) };
  } catch {
    state.logs = [{ time: new Date().toISOString(), text: "저장된 설정을 읽지 못했습니다." }];
  }
}

function save() {
  localStorage.setItem(storageKey, JSON.stringify({
    items: state.items,
    logs: state.logs,
    settings: state.settings,
  }));
}

function formatBp(value) {
  const number = Number(value);
  if (!Number.isFinite(number)) return "0 BP";

  const jo = Math.floor(number / 1000000000000);
  const eok = Math.floor((number % 1000000000000) / 100000000);

  if (jo > 0 && eok > 0) return `${jo}조 ${eok.toLocaleString("ko-KR")}억 BP`;
  if (jo > 0) return `${jo}조 BP`;
  if (eok > 0) return `${eok.toLocaleString("ko-KR")}억 BP`;
  return `${number.toLocaleString("ko-KR")} BP`;
}

function parsePrice(value) {
  return Number(String(value).replace(/[^\d]/g, ""));
}

function thresholdReached(item) {
  const diff = item.currentPrice - item.basePrice;
  if (diff <= 0) return false;
  if (item.threshold === "1") return diff >= 1;
  const percent = Number(item.threshold.replace("p", ""));
  return diff / item.basePrice * 100 >= percent;
}

function changeText(item) {
  const diff = item.currentPrice - item.basePrice;
  if (diff === 0) return "변화 없음";
  const sign = diff > 0 ? "+" : "-";
  const percent = Math.abs(diff / item.basePrice * 100).toFixed(2);
  return `${sign}${formatBp(Math.abs(diff))} (${percent}%)`;
}

function addLog(text) {
  state.logs.unshift({ time: new Date().toISOString(), text });
  state.logs = state.logs.slice(0, 30);
  save();
  renderLogs();
}

function renderRows() {
  els.watchRows.innerHTML = "";
  els.emptyState.classList.toggle("visible", state.items.length === 0);

  state.items.forEach((item) => {
    const row = els.rowTemplate.content.firstElementChild.cloneNode(true);
    const isUp = thresholdReached(item);

    row.querySelector('[data-field="title"]').textContent = item.playerName;
    row.querySelector('[data-field="meta"]').textContent = `${item.seasonName || "시즌 미지정"} · ${item.grade}강`;
    row.querySelector('[data-field="basePrice"]').textContent = formatBp(item.basePrice);
    row.querySelector('[data-field="currentInput"]').value = item.currentPrice;
    row.querySelector('[data-field="change"]').textContent = changeText(item);

    const badge = row.querySelector('[data-field="state"]');
    badge.textContent = isUp ? "상승 감지" : "대기중";
    badge.classList.toggle("up", isUp);

    row.querySelector('[data-field="currentInput"]').addEventListener("change", (event) => {
      item.currentPrice = parsePrice(event.target.value);
      item.updatedAt = new Date().toISOString();
      save();
      renderRows();
    });

    row.querySelector('[data-action="remove"]').addEventListener("click", () => {
      state.items = state.items.filter((candidate) => candidate.id !== item.id);
      save();
      renderRows();
    });

    els.watchRows.appendChild(row);
  });
}

function renderLogs() {
  els.alertLog.innerHTML = "";
  state.logs.forEach((log) => {
    const li = document.createElement("li");
    const time = new Intl.DateTimeFormat("ko-KR", {
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    }).format(new Date(log.time));
    li.textContent = `${time} · ${log.text}`;
    els.alertLog.appendChild(li);
  });
}

function renderSettings() {
  els.nexonKey.value = state.settings.nexonKey;
  els.kakaoKey.value = state.settings.kakaoKey;
  els.refreshToken.value = state.settings.refreshToken;
  els.intervalSeconds.value = String(state.settings.intervalSeconds);
}

function renderRunState() {
  const running = Boolean(state.timer);
  els.runStatus.textContent = running ? "감시 중" : "감시 대기";
  els.runStatus.classList.toggle("running", running);
  els.toggleRunButton.textContent = running ? "자동 감시 중지" : "자동 감시 시작";
}

function render() {
  renderRows();
  renderLogs();
  renderSettings();
  renderRunState();
}

function addItem(formData) {
  const basePrice = parsePrice(formData.get("upperPrice"));
  if (!basePrice) {
    addLog("상한가를 숫자로 입력해 주세요.");
    return;
  }

  const playerName = formData.get("playerName").trim();
  const grade = formData.get("grade");
  const seasonName = formData.get("seasonName").trim();

  state.items.unshift({
    id: crypto.randomUUID(),
    spid: state.selectedPlayer?.spid || null,
    playerName,
    seasonName,
    grade,
    basePrice,
    currentPrice: basePrice,
    threshold: formData.get("threshold"),
    createdAt: new Date().toISOString(),
    updatedAt: new Date().toISOString(),
    alertedAtPrice: null,
  });

  state.selectedPlayer = null;
  els.searchResults.innerHTML = "";
  addLog(`${playerName} ${grade}강 매물을 등록했습니다.`);
  save();
  renderRows();
}

async function searchPlayers() {
  const query = els.playerName.value.trim();
  if (!query) {
    addLog("검색할 선수명을 입력해 주세요.");
    return;
  }

  els.searchResults.textContent = "검색 중...";
  try {
    const response = await fetch(`/api/players?q=${encodeURIComponent(query)}&limit=8`, {
      headers: state.settings.nexonKey ? { "x-nxopen-api-key": state.settings.nexonKey } : {},
    });
    const data = await response.json();
    if (!response.ok) throw new Error(data.message || "선수 검색 실패");
    renderSearchResults(data.players || []);
  } catch (error) {
    els.searchResults.textContent = "";
    addLog(`선수 검색 실패: ${error.message}`);
  }
}

function renderSearchResults(players) {
  els.searchResults.innerHTML = "";
  if (players.length === 0) {
    els.searchResults.textContent = "검색 결과가 없습니다.";
    return;
  }

  players.forEach((player) => {
    const button = document.createElement("button");
    button.className = "result-button";
    button.type = "button";
    button.innerHTML = `
      <img src="${player.imageUrl}" alt="" />
      <div>
        <strong>${player.name}</strong>
        <span>${player.seasonName || "시즌 정보 없음"} · SPID ${player.spid}</span>
      </div>
    `;
    button.addEventListener("click", () => {
      state.selectedPlayer = player;
      els.playerName.value = player.name;
      els.seasonName.value = player.seasonName || "";
      addLog(`${player.name} ${player.seasonName || ""} 선수를 선택했습니다.`);
    });
    els.searchResults.appendChild(button);
  });
}

async function fetchLatestPrice(item) {
  if (!item.spid) return null;

  const response = await fetch(`/api/price?spid=${encodeURIComponent(item.spid)}&grade=${encodeURIComponent(item.grade)}`, {
    headers: state.settings.nexonKey ? { "x-nxopen-api-key": state.settings.nexonKey } : {},
  });
  const data = await response.json();
  if (!response.ok) {
    if (response.status !== 501) throw new Error(data.message || "상한가 조회 실패");
    return null;
  }
  return Number(data.upperPrice);
}

async function sendKakaoMessage(text) {
  if (!state.settings.kakaoKey || !state.settings.refreshToken) {
    addLog("카카오 키 또는 refresh token이 없어 메시지는 기록에만 남겼습니다.");
    return;
  }

  const response = await fetch("/api/kakao/send", {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      kakaoKey: state.settings.kakaoKey,
      refreshToken: state.settings.refreshToken,
      text,
    }),
  });
  const data = await response.json();
  if (!response.ok) throw new Error(data.message || "카카오 메시지 전송 실패");

  if (data.refreshToken && data.refreshToken !== state.settings.refreshToken) {
    state.settings.refreshToken = data.refreshToken;
    save();
    renderSettings();
    addLog("새 refresh token을 저장했습니다.");
  }
}

async function checkItems() {
  if (state.items.length === 0) {
    addLog("확인할 매물이 없습니다.");
    return;
  }

  let detected = 0;
  let priceUnavailable = false;

  for (const item of state.items) {
    try {
      const latestPrice = await fetchLatestPrice(item);
      if (latestPrice) {
        item.currentPrice = latestPrice;
        item.updatedAt = new Date().toISOString();
      } else if (item.spid) {
        priceUnavailable = true;
      }
    } catch (error) {
      addLog(`${item.playerName} 가격 조회 실패: ${error.message}`);
    }

    const up = thresholdReached(item);
    if (up && item.alertedAtPrice !== item.currentPrice) {
      item.alertedAtPrice = item.currentPrice;
      detected += 1;
      const message = `${item.playerName} ${item.grade}강 상한가 상승: ${formatBp(item.basePrice)} → ${formatBp(item.currentPrice)}`;
      addLog(message);
      try {
        await sendKakaoMessage(message);
      } catch (error) {
        addLog(`카카오 알림 실패: ${error.message}`);
      }
    }
  }

  if (priceUnavailable) {
    addLog("공식 넥슨 API에는 거래소 상한가 조회가 없어 현재 입력값 기준으로 확인했습니다.");
  }
  if (detected === 0) {
    addLog("상한가 상승 매물이 없습니다.");
  }

  save();
  renderRows();
}

function toggleRun() {
  if (state.timer) {
    clearInterval(state.timer);
    state.timer = null;
    addLog("자동 감시를 중지했습니다.");
    renderRunState();
    return;
  }

  checkItems();
  state.timer = setInterval(checkItems, Number(state.settings.intervalSeconds) * 1000);
  addLog(`${state.settings.intervalSeconds}초 주기로 자동 감시를 시작했습니다.`);
  renderRunState();
}

els.form.addEventListener("submit", (event) => {
  event.preventDefault();
  addItem(new FormData(event.currentTarget));
  event.currentTarget.reset();
  els.grade.value = "1";
  els.threshold.value = "1";
});

els.searchPlayers.addEventListener("click", searchPlayers);
els.checkButton.addEventListener("click", checkItems);
els.toggleRunButton.addEventListener("click", toggleRun);

els.saveSettings.addEventListener("click", () => {
  state.settings.nexonKey = els.nexonKey.value.trim();
  state.settings.kakaoKey = els.kakaoKey.value.trim();
  state.settings.refreshToken = els.refreshToken.value.trim();
  state.settings.intervalSeconds = Number(els.intervalSeconds.value);
  save();
  addLog("알림 설정을 저장했습니다.");
});

els.sampleButton.addEventListener("click", () => {
  els.playerName.value = "손흥민";
  els.seasonName.value = "24TOTY";
  els.grade.value = "5";
  els.upperPrice.value = "1240000000000";
});

els.clearLog.addEventListener("click", () => {
  state.logs = [];
  save();
  renderLogs();
});

load();
render();
