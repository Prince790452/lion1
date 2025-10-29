import { signIn, signUp, getCurrentUser } from './auth.js';

let isSignUpMode = false;

const authForm = document.getElementById('authForm');
const authTitle = document.getElementById('authTitle');
const submitButton = document.getElementById('submitButton');
const toggleLink = document.getElementById('toggleLink');
const toggleText = document.getElementById('toggleText');
const nameGroup = document.getElementById('nameGroup');
const fullNameInput = document.getElementById('fullName');
const emailInput = document.getElementById('email');
const passwordInput = document.getElementById('password');
const errorMessage = document.getElementById('errorMessage');
const successMessage = document.getElementById('successMessage');

async function checkAuth() {
  const user = await getCurrentUser();
  if (user) {
    window.location.href = '/';
  }
}

checkAuth();

function showError(message) {
  errorMessage.textContent = message;
  errorMessage.classList.add('show');
  successMessage.classList.remove('show');

  setTimeout(() => {
    errorMessage.classList.remove('show');
  }, 5000);
}

function showSuccess(message) {
  successMessage.textContent = message;
  successMessage.classList.add('show');
  errorMessage.classList.remove('show');
}

function setLoading(loading) {
  submitButton.disabled = loading;
  if (loading) {
    submitButton.innerHTML = '<span class="loading-spinner"></span>Processing...';
  } else {
    submitButton.textContent = isSignUpMode ? 'Create Account' : 'Sign In';
  }
}

toggleLink.addEventListener('click', (e) => {
  e.preventDefault();
  isSignUpMode = !isSignUpMode;

  if (isSignUpMode) {
    authTitle.textContent = 'Create Account';
    submitButton.textContent = 'Create Account';
    toggleText.textContent = 'Already have an account?';
    toggleLink.textContent = 'Sign In';
    nameGroup.style.display = 'flex';
    fullNameInput.required = true;
  } else {
    authTitle.textContent = 'Welcome Back';
    submitButton.textContent = 'Sign In';
    toggleText.textContent = "Don't have an account?";
    toggleLink.textContent = 'Sign Up';
    nameGroup.style.display = 'none';
    fullNameInput.required = false;
  }

  errorMessage.classList.remove('show');
  successMessage.classList.remove('show');
});

authForm.addEventListener('submit', async (e) => {
  e.preventDefault();

  const email = emailInput.value.trim();
  const password = passwordInput.value;
  const fullName = fullNameInput.value.trim();

  if (password.length < 6) {
    showError('Password must be at least 6 characters long');
    return;
  }

  setLoading(true);
  errorMessage.classList.remove('show');
  successMessage.classList.remove('show');

  try {
    if (isSignUpMode) {
      if (!fullName) {
        showError('Please enter your full name');
        setLoading(false);
        return;
      }

      await signUp(email, password, fullName);
      showSuccess('Account created successfully! Redirecting...');

      setTimeout(() => {
        window.location.href = '/';
      }, 1500);
    } else {
      await signIn(email, password);
      showSuccess('Signed in successfully! Redirecting...');

      setTimeout(() => {
        window.location.href = '/';
      }, 1000);
    }
  } catch (error) {
    console.error('Auth error:', error);

    if (error.message.includes('Invalid login credentials')) {
      showError('Invalid email or password');
    } else if (error.message.includes('User already registered')) {
      showError('An account with this email already exists');
    } else if (error.message.includes('Email not confirmed')) {
      showError('Please verify your email address');
    } else {
      showError(error.message || 'An error occurred. Please try again.');
    }

    setLoading(false);
  }
});
