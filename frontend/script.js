// Configuration for different AI platforms
const platformsData = {
  'ChatGPT': {
    url: 'chatgpt.com',
    logo: 'ChatGPT',
    model: 'GPT-4o',
    avatar: 'C',
    avatarColor: '#10a37f',
    answer: 'Ya, berbagai penelitian menunjukkan hubungan signifikan antara penggunaan media sosial berlebihan dengan penurunan kesehatan mental. Penggunaan lebih dari 3 jam per hari meningkatkan risiko depresi. Perempuan cenderung lebih rentan. Platform berbasis gambar seperti Instagram dinilai lebih berdampak negatif...'
  },
  'Gemini': {
    url: 'gemini.google.com',
    logo: 'Gemini',
    model: 'Gemini 1.5 Pro',
    avatar: 'G',
    avatarColor: '#1a73e8',
    answer: 'Berdasarkan data riset psikologis terkini, media sosial memiliki korelasi kuat dengan kecemasan dan gangguan tidur pada remaja. Algoritma pembandingan sosial (social comparison) memicu distorsi citra diri (body image issues), terutama pada kelompok umur 12-16 tahun...'
  },
  'Claude': {
    url: 'claude.ai',
    logo: 'Claude',
    model: 'Claude 3.5 Sonnet',
    avatar: 'C',
    avatarColor: '#d97706',
    answer: 'Analisis komprehensif menunjukkan efek media sosial pada mental remaja bersifat multifaktorial. Meskipun memfasilitasi koneksi sosial, paparan konten terkurasi memicu sindrom FOMO (Fear Of Missing Out) dan mengganggu siklus tidur yang penting bagi perkembangan otak...'
  },
  'DeepSeek': {
    url: 'deepseek.com',
    logo: 'DeepSeek',
    model: 'DeepSeek-V3',
    avatar: 'D',
    avatarColor: '#0052cc',
    answer: 'Menurut studi empiris terbaru, terdapat dampak negatif linear antara waktu layar (screen time) media sosial dengan kesejahteraan emosional remaja. Risiko utama meliputi paparan cyberbullying, fragmentasi atensi, serta berkurangnya interaksi tatap muka secara langsung...'
  }
};

// State management
let selectedPlatform = 'ChatGPT';
let verificationData = null;
let currentCitationFormat = 'apa'; // default citation format

const screenLabels = [
  '',
  'Screen 1 of 3 — pilih platform AI',
  'Screen 2 of 3 — web AI + tombol Verify ngambang',
  'Screen 3 of 3 — panel fitur muncul ngambang'
];

function goTo(n) {
  ['s1', 's2', 's3'].forEach((id, i) => {
    const el = document.getElementById(id);
    if (el) {
      el.style.display = (i + 1 === n) ? 'flex' : 'none';
    }
  });

  for (let i = 1; i <= 3; i++) {
    const dot = document.getElementById('d' + i);
    if (dot) {
      dot.className = 'dot' + (i === n ? ' on' : '');
    }
  }

  const labelEl = document.getElementById('lbl');
  if (labelEl) {
    labelEl.textContent = screenLabels[n];
  }
}

function selectAI(el) {
  document.querySelectorAll('.ai-grid .ai-btn').forEach(btn => {
    btn.classList.remove('selected');
  });

  el.classList.add('selected');

  const platformName = el.querySelector('span').textContent.trim();
  selectedPlatform = platformName;

  updateMockupDetails(platformName);
}

function updateMockupDetails(platform) {
  const data = platformsData[platform];
  if (!data) return;

  const nextBtn = document.querySelector('.s1-inner .next-btn');
  if (nextBtn) {
    nextBtn.innerHTML = `Buka ${platform} <i class="ti ti-arrow-right" aria-hidden="true"></i>`;
  }

  const urls = document.querySelectorAll('.browser-bar .url, .s3-browser .url');
  urls.forEach(urlEl => {
    urlEl.textContent = data.url;
  });

  const logoText = document.querySelector('.chatgpt-header .logo-text');
  if (logoText) logoText.textContent = data.logo;

  const modelBadge = document.querySelector('.chatgpt-header .model-badge');
  if (modelBadge) modelBadge.textContent = data.model;

  const s2AiBubble = document.querySelector('#s2 .chat-msg:not(.user) .msg-bubble');
  const s2AiAvatar = document.querySelector('#s2 .chat-msg:not(.user) .avatar');
  if (s2AiBubble) s2AiBubble.textContent = data.answer;
  if (s2AiAvatar) {
    s2AiAvatar.textContent = data.avatar;
    s2AiAvatar.style.backgroundColor = data.avatarColor;
  }

  const s3AiBubble = document.querySelector('.s3-chat .chat-msg:not(.user) .msg-bubble');
  const s3AiAvatar = document.querySelector('.s3-chat .chat-msg:not(.user) .avatar');
  if (s3AiBubble) s3AiBubble.textContent = data.answer;
  if (s3AiAvatar) {
    s3AiAvatar.textContent = data.avatar;
    s3AiAvatar.style.backgroundColor = data.avatarColor;
  }
}

// ----------------------------------------------------
// INTEGRASI API & LOGIKA DETAILED PANELS
// ----------------------------------------------------

async function startVerification() {
  const loadingOverlay = document.getElementById('loadingOverlay');
  if (loadingOverlay) loadingOverlay.style.display = 'flex';

  const answerText = platformsData[selectedPlatform].answer;

  try {
    const response = await fetch('http://localhost:5000/api/v1/verify', {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json'
      },
      body: JSON.stringify({ answer: answerText })
    });

    const result = await response.json();

    if (result.status === 'success') {
      verificationData = result.data;
      showFeaturesList(); // Pastikan menu utama yang muncul pertama kali
      goTo(3); // Masuk ke panel verifikasi overlay
    } else {
      alert('Gagal memverifikasi: ' + (result.message || 'Error tidak dikenal'));
    }
  } catch (error) {
    console.error('Error connecting to backend:', error);
    alert('Tidak dapat terhubung ke server backend lokal (Port 5000). Pastikan server backend sudah dijalankan dengan "npm run dev".');
  } finally {
    if (loadingOverlay) loadingOverlay.style.display = 'none';
  }
}

function showFeaturesList() {
  document.getElementById('featuresList').style.display = 'flex';
  document.getElementById('panelSubtitle').style.display = 'block';
  document.getElementById('featureDetail').style.display = 'none';
}

function showFeatureDetail(featureId) {
  if (!verificationData) return;

  document.getElementById('featuresList').style.display = 'none';
  document.getElementById('panelSubtitle').style.display = 'none';
  
  const detailPanel = document.getElementById('featureDetail');
  const titleEl = document.getElementById('detailTitle');
  const contentEl = document.getElementById('detailContent');

  detailPanel.style.display = 'flex';

  if (featureId === 'claims') {
    titleEl.textContent = 'Claim Extractor';
    let html = '<div class="detail-scroll-container"><div class="claims-list">';
    verificationData.claims.forEach((claim, idx) => {
      html += `
        <div class="detail-card claim-card">
          <div class="claim-number">Klaim #${idx + 1}</div>
          <p class="claim-text">"${claim}"</p>
        </div>
      `;
    });
    html += '</div></div>';
    contentEl.innerHTML = html;

  } else if (featureId === 'papers') {
    titleEl.textContent = 'Evidence Finder';
    let html = '<div class="detail-scroll-container"><div class="papers-list">';
    if (verificationData.papers.length === 0) {
      html += '<p style="font-size:12px;color:var(--color-text-tertiary);text-align:center;">Tidak ada jurnal referensi yang ditemukan.</p>';
    } else {
      verificationData.papers.forEach((paper) => {
        html += `
          <div class="detail-card paper-card">
            <h4 class="paper-title">${paper.title}</h4>
            <div class="paper-meta">
              <span><i class="ti ti-user"></i> ${paper.authors.slice(0, 2).join(', ')}${paper.authors.length > 2 ? ' et al.' : ''}</span>
              <span><i class="ti ti-calendar"></i> ${paper.year}</span>
            </div>
            <p class="paper-abstract-preview">${paper.abstract ? paper.abstract.substring(0, 140) + '...' : 'Abstrak tidak tersedia.'}</p>
            ${paper.url ? `<a href="${paper.url}" target="_blank" class="paper-link-btn">Buka Jurnal <i class="ti ti-external-link"></i></a>` : ''}
          </div>
        `;
      });
    }
    html += '</div></div>';
    contentEl.innerHTML = html;

  } else if (featureId === 'consensus') {
    titleEl.textContent = 'Consensus Meter';
    let html = '<div class="detail-scroll-container"><div class="consensus-container">';
    
    // Tampilkan consensus meter per klaim
    Object.entries(verificationData.consensus).forEach(([claim, res]) => {
      let levelColor = '#10a37f'; // green for high
      if (res.level === 'Medium') levelColor = '#eab308'; // yellow
      if (res.level === 'Low' || res.level === 'Weak') levelColor = '#f97316'; // orange
      if (res.level === 'Contradictory') levelColor = '#ef4444'; // red

      html += `
        <div class="detail-card consensus-card">
          <p class="consensus-claim">"${claim}"</p>
          <div class="consensus-gauge-row">
            <div class="consensus-gauge-circle" style="border-color: ${levelColor}">
              <div class="score-val" style="color: ${levelColor}">${res.score}%</div>
              <div class="level-val">${res.level}</div>
            </div>
            <div class="consensus-breakdown-details">
              <div class="bd-item"><span class="dot-indicator support"></span> Support: <strong>${res.support}</strong></div>
              <div class="bd-item"><span class="dot-indicator neutral"></span> Neutral: <strong>${res.neutral}</strong></div>
              <div class="bd-item"><span class="dot-indicator oppose"></span> Oppose: <strong>${res.oppose}</strong></div>
              <div class="bd-item-total">Total Paper: ${res.total}</div>
            </div>
          </div>
        </div>
      `;
    });

    html += '</div></div>';
    contentEl.innerHTML = html;

  } else if (featureId === 'blindspot') {
    titleEl.textContent = 'Blind Spot Alert';
    const bs = verificationData.blindSpot;
    
    let statsHtml = '';
    Object.entries(bs.distribution).forEach(([region, count]) => {
      statsHtml += `
        <div class="stat-bar-row">
          <div class="stat-lbl">${region}</div>
          <div class="stat-bar-container">
            <div class="stat-bar-fill" style="width: ${Math.min(100, (count/8)*100)}%"></div>
          </div>
          <div class="stat-count">${count}</div>
        </div>
      `;
    });

    let html = `
      <div class="detail-scroll-container">
        <div class="blindspot-container">
          <div class="detail-card warning-card">
            <div class="warning-title"><i class="ti ti-alert-triangle"></i> Ringkasan Geografis</div>
            <p class="warning-text">${bs.summary}</p>
          </div>
          
          <div class="detail-card stats-card">
            <h4 class="stats-title">Sebaran Wilayah Institusi</h4>
            <div class="stats-list">
              ${statsHtml}
            </div>
          </div>
        </div>
      </div>
    `;
    contentEl.innerHTML = html;

  } else if (featureId === 'citations') {
    titleEl.textContent = 'Ready-to-Cite';
    renderCitationsContent(contentEl);
  }
}

function renderCitationsContent(container) {
  let html = `
    <div class="detail-scroll-container">
      <div class="citation-selector-row">
        <button class="cite-tab-btn ${currentCitationFormat === 'apa' ? 'active' : ''}" onclick="changeCitationFormat('apa')">APA</button>
        <button class="cite-tab-btn ${currentCitationFormat === 'mla' ? 'active' : ''}" onclick="changeCitationFormat('mla')">MLA</button>
        <button class="cite-tab-btn ${currentCitationFormat === 'ieee' ? 'active' : ''}" onclick="changeCitationFormat('ieee')">IEEE</button>
      </div>
      <div class="citations-list">
  `;

  if (verificationData.papers.length === 0) {
    html += '<p style="font-size:12px;color:var(--color-text-tertiary);text-align:center;">Tidak ada sitasi untuk ditampilkan.</p>';
  } else {
    verificationData.papers.forEach((paper) => {
      const citationText = verificationData.citations[paper.id] 
        ? verificationData.citations[paper.id][currentCitationFormat]
        : 'Sitasi tidak tersedia.';

      html += `
        <div class="detail-card citation-card">
          <h5 class="citation-paper-title">${paper.title}</h5>
          <div class="citation-box-wrapper">
            <div class="citation-copy-box" id="cite-${paper.id.replace(/[^a-zA-Z0-9]/g, '')}">${citationText}</div>
            <button class="copy-icon-btn" onclick="copyCitationText('cite-${paper.id.replace(/[^a-zA-Z0-9]/g, '')}')" title="Salin Sitasi">
              <i class="ti ti-copy"></i>
            </button>
          </div>
        </div>
      `;
    });
  }

  html += '</div></div>';
  container.innerHTML = html;
}

function changeCitationFormat(format) {
  currentCitationFormat = format;
  const contentEl = document.getElementById('detailContent');
  renderCitationsContent(contentEl);
}

function copyCitationText(elementId) {
  const el = document.getElementById(elementId);
  if (!el) return;

  const textToCopy = el.textContent;
  navigator.clipboard.writeText(textToCopy).then(() => {
    alert('Sitasi berhasil disalin ke clipboard!');
  }).catch(err => {
    console.error('Failed to copy text:', err);
  });
}

// ----------------------------------------------------
// EVENT LISTENERS INITIALIZATION
// ----------------------------------------------------

document.addEventListener('DOMContentLoaded', () => {
  const firstBtn = document.querySelector('.ai-grid .ai-btn');
  if (firstBtn) {
    selectAI(firstBtn);
  }
  
  for (let i = 1; i <= 3; i++) {
    const dot = document.getElementById('d' + i);
    if (dot) {
      dot.addEventListener('click', () => goTo(i));
    }
  }
});
