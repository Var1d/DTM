import React from 'react';
import ReactDOM from 'react-dom/client';
import App from './App';
import './styles/theme.css';

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(<React.StrictMode><App /></React.StrictMode>);

// Register Service Worker - Platform-Specific Feature Web: PWA
if ('serviceWorker' in navigator) {
  window.addEventListener('load', () => {
    navigator.serviceWorker.register('/service-worker.js', { scope: '/' })
      .then((reg) => {
        console.log('SW registered:', reg.scope);
        if (reg.waiting) reg.waiting.postMessage({ type: 'SKIP_WAITING' });
      })
      .catch((err) => console.log('SW failed:', err));
  });
}
