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

// Description labels for the mockup header
const screenLabels = [
  '',
  'Screen 1 of 3 — pilih platform AI',
  'Screen 2 of 3 — web AI + tombol Verify ngambang',
  'Screen 3 of 3 — panel fitur muncul ngambang'
];

/**
 * Switch screen view
 * @param {number} n - Target screen number (1, 2, or 3)
 */
function goTo(n) {
  // Hide all screens, show target screen
  ['s1', 's2', 's3'].forEach((id, i) => {
    const el = document.getElementById(id);
    if (el) {
      el.style.display = (i + 1 === n) ? 'flex' : 'none';
    }
  });

  // Update pagination dots indicator
  for (let i = 1; i <= 3; i++) {
    const dot = document.getElementById('d' + i);
    if (dot) {
      dot.className = 'dot' + (i === n ? ' on' : '');
    }
  }

  // Update label text
  const labelEl = document.getElementById('lbl');
  if (labelEl) {
    labelEl.textContent = screenLabels[n];
  }
}

/**
 * Handle platform selection
 * @param {HTMLElement} el - The clicked AI button element
 */
function selectAI(el) {
  // Remove selection from all buttons
  document.querySelectorAll('.ai-grid .ai-btn').forEach(btn => {
    btn.classList.remove('selected');
  });

  // Highlight selected button
  el.classList.add('selected');

  // Update selected platform state
  const platformName = el.querySelector('span').textContent.trim();
  selectedPlatform = platformName;

  // Update visual details for the next screens
  updateMockupDetails(platformName);
}

/**
 * Dynamically update mock values on Screens 2 and 3 based on selected platform
 * @param {string} platform - Name of the selected platform
 */
function updateMockupDetails(platform) {
  const data = platformsData[platform];
  if (!data) return;

  // 1. Update next screen button text
  const nextBtn = document.querySelector('.s1-inner .next-btn');
  if (nextBtn) {
    nextBtn.innerHTML = `Buka ${platform} <i class="ti ti-arrow-right" aria-hidden="true"></i>`;
  }

  // 2. Update Browser URL in Screen 2 and Screen 3
  const urls = document.querySelectorAll('.browser-bar .url, .s3-browser .url');
  urls.forEach(urlEl => {
    urlEl.textContent = data.url;
  });

  // 3. Update Chat Logo Text and Model Badge in Screen 2
  const logoText = document.querySelector('.chatgpt-header .logo-text');
  if (logoText) logoText.textContent = data.logo;

  const modelBadge = document.querySelector('.chatgpt-header .model-badge');
  if (modelBadge) modelBadge.textContent = data.model;

  // 4. Update Chat Bubbles & Avatars in Screen 2 & Screen 3
  // S2 AI bubble & avatar
  const s2AiBubble = document.querySelector('#s2 .chat-msg:not(.user) .msg-bubble');
  const s2AiAvatar = document.querySelector('#s2 .chat-msg:not(.user) .avatar');
  if (s2AiBubble) s2AiBubble.textContent = data.answer;
  if (s2AiAvatar) {
    s2AiAvatar.textContent = data.avatar;
    s2AiAvatar.style.backgroundColor = data.avatarColor;
  }

  // S3 AI bubble & avatar
  const s3AiBubble = document.querySelector('.s3-chat .chat-msg:not(.user) .msg-bubble');
  const s3AiAvatar = document.querySelector('.s3-chat .chat-msg:not(.user) .avatar');
  if (s3AiBubble) s3AiBubble.textContent = data.answer;
  if (s3AiAvatar) {
    s3AiAvatar.textContent = data.avatar;
    s3AiAvatar.style.backgroundColor = data.avatarColor;
  }
}

// Attach event listeners after content loads
document.addEventListener('DOMContentLoaded', () => {
  // Set default selection state on load
  const firstBtn = document.querySelector('.ai-grid .ai-btn');
  if (firstBtn) {
    selectAI(firstBtn);
  }
  
  // Set up click handlers on dots for easy testing/navigation
  for (let i = 1; i <= 3; i++) {
    const dot = document.getElementById('d' + i);
    if (dot) {
      dot.addEventListener('click', () => goTo(i));
    }
  }

  // Set up click handlers for feature list items on Screen 3
  const featItems = document.querySelectorAll('.feat-item');
  featItems.forEach(item => {
    item.addEventListener('click', () => {
      featItems.forEach(i => i.classList.remove('active'));
      item.classList.add('active');
    });
  });
});
