import api from './api';

const SERVICE_WORKER_TIMEOUT_MS = 10000;
const PUSH_STEP_TIMEOUT_MS = 15000;

const urlBase64ToUint8Array = (base64String) => {
  const padding = '='.repeat((4 - (base64String.length % 4)) % 4);
  const base64 = (base64String + padding).replace(/-/g, '+').replace(/_/g, '/');
  const rawData = window.atob(base64);
  const outputArray = new Uint8Array(rawData.length);

  for (let i = 0; i < rawData.length; i += 1) {
    outputArray[i] = rawData.charCodeAt(i);
  }

  return outputArray;
};

export const isPushSupported = () => {
  return 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window;
};

const withTimeout = (promise, message, timeoutMs = PUSH_STEP_TIMEOUT_MS) => {
  let timeoutId;
  const timeout = new Promise((_, reject) => {
    timeoutId = window.setTimeout(() => reject(new Error(message)), timeoutMs);
  });

  return Promise.race([promise, timeout]).finally(() => window.clearTimeout(timeoutId));
};

const waitForServiceWorkerRegistration = async () => {
  const existingRegistration = await navigator.serviceWorker.getRegistration('/');
  const registration = existingRegistration || await navigator.serviceWorker.register('/service-worker.js', { scope: '/' });

  if (registration.active) return registration;

  return withTimeout(
    navigator.serviceWorker.ready,
    'Service worker belum siap. Coba refresh halaman lalu aktifkan lagi.',
    SERVICE_WORKER_TIMEOUT_MS
  );
};

export const getPushStatus = async () => {
  if (!isPushSupported()) {
    return { supported: false, permission: 'unsupported', subscribed: false };
  }

  const registration = await waitForServiceWorkerRegistration();
  const subscription = await registration.pushManager.getSubscription();

  return {
    supported: true,
    permission: Notification.permission,
    subscribed: Boolean(subscription),
  };
};

export const subscribeToPush = async (onProgress) => {
  if (!isPushSupported()) {
    throw new Error('Browser ini belum mendukung Web Push Notification');
  }

  onProgress?.('Meminta izin notifikasi...');
  const permission = await withTimeout(
    Notification.requestPermission(),
    'Permintaan izin notifikasi terlalu lama. Cek popup izin browser lalu coba lagi.'
  );
  if (permission !== 'granted') {
    throw new Error('Izin notifikasi belum diberikan');
  }

  onProgress?.('Menyiapkan service worker...');
  const registration = await waitForServiceWorkerRegistration();

  onProgress?.('Mengambil kunci push dari server...');
  const { data } = await api.get('/notifications/public-key');
  const publicKey = data?.data?.public_key;
  if (!publicKey) {
    throw new Error('Public key Web Push tidak ditemukan dari server');
  }

  let subscription = await withTimeout(
    registration.pushManager.getSubscription(),
    'Gagal mengecek subscription notifikasi di browser.'
  );

  if (!subscription) {
    onProgress?.('Mendaftarkan browser untuk push...');
    subscription = await withTimeout(
      registration.pushManager.subscribe({
        userVisibleOnly: true,
        applicationServerKey: urlBase64ToUint8Array(publicKey),
      }),
      'Browser terlalu lama membuat subscription push. Coba refresh halaman atau hapus izin notifikasi lalu aktifkan lagi.'
    );
  }

  onProgress?.('Menyimpan subscription ke server...');
  await api.post('/notifications/subscribe', { subscription: subscription.toJSON() });
  return subscription;
};

export const unsubscribeFromPush = async () => {
  if (!isPushSupported()) return;

  const registration = await waitForServiceWorkerRegistration();
  const subscription = await registration.pushManager.getSubscription();
  if (!subscription) return;

  await api.post('/notifications/unsubscribe', { endpoint: subscription.endpoint });
  await subscription.unsubscribe();
};

export const sendTestNotification = async () => {
  await api.post('/notifications/test');
};
