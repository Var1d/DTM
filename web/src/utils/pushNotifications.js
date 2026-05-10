import api from './api';

const SERVICE_WORKER_TIMEOUT_MS = 10000;

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

const waitForServiceWorkerRegistration = async () => {
  const ready = navigator.serviceWorker.ready;
  const timeout = new Promise((_, reject) => {
    window.setTimeout(() => reject(new Error('Service worker belum siap. Coba refresh halaman lalu aktifkan lagi.')), SERVICE_WORKER_TIMEOUT_MS);
  });

  return Promise.race([ready, timeout]);
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

export const subscribeToPush = async () => {
  if (!isPushSupported()) {
    throw new Error('Browser ini belum mendukung Web Push Notification');
  }

  const permission = await Notification.requestPermission();
  if (permission !== 'granted') {
    throw new Error('Izin notifikasi belum diberikan');
  }

  const registration = await waitForServiceWorkerRegistration();
  const { data } = await api.get('/notifications/public-key');
  let subscription = await registration.pushManager.getSubscription();

  if (!subscription) {
    subscription = await registration.pushManager.subscribe({
      userVisibleOnly: true,
      applicationServerKey: urlBase64ToUint8Array(data.data.public_key),
    });
  }

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
