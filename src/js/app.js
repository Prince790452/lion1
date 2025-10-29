import { getCurrentUser, getUserProfile, signOut, onAuthStateChange } from './auth.js';
import { supabase } from './supabase.js';

let currentUser = null;
let userProfile = null;

async function initApp() {
  try {
    currentUser = await getCurrentUser();

    if (!currentUser) {
      window.location.href = '/auth.html';
      return;
    }

    userProfile = await getUserProfile(currentUser.id);

    if (userProfile) {
      const fullName = userProfile.full_name || 'User';
      document.getElementById('userName').textContent = fullName;
      document.getElementById('userEmail').textContent = userProfile.email;

      const initials = fullName.split(' ').map(n => n[0]).join('').toUpperCase().substring(0, 2);
      document.getElementById('userAvatar').textContent = initials;
    }

    setupEventListeners();
    loadUserData();
  } catch (error) {
    console.error('Error initializing app:', error);
    window.location.href = '/auth.html';
  }
}

function setupEventListeners() {
  const logoutBtn = document.getElementById('logoutBtn');
  if (logoutBtn) {
    logoutBtn.addEventListener('click', handleLogout);
  }

  const sidebarToggle = document.getElementById('sidebarToggle');
  const sidebar = document.getElementById('sidebar');
  if (sidebarToggle && sidebar) {
    sidebarToggle.addEventListener('click', () => {
      sidebar.classList.toggle('open');
    });
  }

  const darkModeToggle = document.getElementById('darkModeToggle');
  if (darkModeToggle) {
    darkModeToggle.addEventListener('click', toggleDarkMode);
  }

  document.addEventListener('click', (e) => {
    if (sidebar && !sidebar.contains(e.target) && !sidebarToggle?.contains(e.target)) {
      sidebar.classList.remove('open');
    }
  });
}

async function handleLogout() {
  try {
    await signOut();
    window.location.href = '/auth.html';
  } catch (error) {
    console.error('Error logging out:', error);
    alert('Failed to log out. Please try again.');
  }
}

function toggleDarkMode() {
  document.body.classList.toggle('dark-mode');
  const isDark = document.body.classList.contains('dark-mode');
  localStorage.setItem('darkMode', isDark);
}

async function loadUserData() {
  try {
    const { data: plans, error } = await supabase
      .from('study_plans')
      .select('*')
      .eq('user_id', currentUser.id)
      .order('created_at', { ascending: false });

    if (error) throw error;

    if (plans && plans.length > 0) {
      displayStudyPlans(plans);
    }
  } catch (error) {
    console.error('Error loading user data:', error);
  }
}

function displayStudyPlans(plans) {
  console.log('Study plans:', plans);
}

onAuthStateChange((event, session) => {
  if (event === 'SIGNED_OUT') {
    window.location.href = '/auth.html';
  }
});

const savedDarkMode = localStorage.getItem('darkMode');
if (savedDarkMode === 'true') {
  document.body.classList.add('dark-mode');
}

initApp();
