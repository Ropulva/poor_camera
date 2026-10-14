let videoStream = null;
let videoElement = null;
// Bumped by every start/stop so a slow getUserMedia that resolves after a newer
// request (or after the sheet closed) releases its camera instead of leaking it.
let startToken = 0;
// Starts run one at a time: a getUserMedia still acquiring the camera can't be
// cancelled, and opening another camera alongside it fails with NotReadableError.
let pendingStart = Promise.resolve();

// Call after a stream is open: labels are only exposed once permission is granted.
async function getAvailableCameras() {
  if (!navigator.mediaDevices || !navigator.mediaDevices.enumerateDevices) {
    console.error('enumerateDevices() not supported.');
    return [];
  }

  const devices = await navigator.mediaDevices.enumerateDevices();

  return devices
    .filter(d => d.kind === 'videoinput' && d.deviceId)
    .map(device => {
      // Infer facing mode from label heuristics
      let facing = 'unknown';
      const label = device.label.toLowerCase();
      if (label.includes('back') || label.includes('rear') || label.includes('environment')) {
        facing = 'environment';
      } else if (label.includes('front') || label.includes('user')) {
        facing = 'user';
      }
      return {
        deviceId: device.deviceId,
        label: device.label,
        facingMode: facing
      };
    });
}

// Resolves to [success, error, activeDeviceId].
async function startCamera(videoElementId, deviceId = null, facingMode = 'environment') {
  const token = ++startToken;
  const previousStart = pendingStart;
  let settle;
  pendingStart = new Promise(resolve => { settle = resolve; });
  try {
    await previousStart;
    if (token !== startToken) {
      return [false, 'Superseded', null];
    }
    return await openCamera(token, videoElementId, deviceId, facingMode);
  } finally {
    settle();
  }
}

async function openCamera(token, videoElementId, deviceId, facingMode) {
  try {
    const videoEl = await waitForElement(videoElementId);
    if (!videoEl) {
      const error = 'Video element not found: ' + videoElementId;
      console.error(error);
      return [false, error, null];
    }
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      const error = 'getUserMedia not supported on this browser';
      console.error(error);
      return [false, error, null];
    }

    // Some Android devices refuse to open a second camera while one is held.
    releaseStream();

    // `ideal` rather than `exact` so devices with a single camera still open.
    const constraints = deviceId
      ? { video: { deviceId: { exact: deviceId } } }
      : { video: { facingMode: { ideal: facingMode } } };

    const stream = await navigator.mediaDevices.getUserMedia(constraints);
    if (token !== startToken) {
      stream.getTracks().forEach(track => track.stop());
      return [false, 'Superseded', null];
    }

    videoStream = stream;
    videoElement = videoEl;
    videoEl.srcObject = stream;
    await videoEl.play();

    const track = stream.getVideoTracks()[0];
    const activeDeviceId = track?.getSettings?.().deviceId ?? null;
    return [true, null, activeDeviceId];
  } catch (e) {
    const error = e?.name ? `${e.name}: ${e.message}` : (e?.toString() || 'Unknown error');
    console.error('startCamera error:', error);
    return [false, error, null];
  }
}

// Flutter attaches the platform view's <video> a few frames after the widget builds.
async function waitForElement(id, timeoutMs = 2000) {
  const deadline = performance.now() + timeoutMs;
  let element = document.getElementById(id);
  while (!element && performance.now() < deadline) {
    await new Promise(resolve => requestAnimationFrame(resolve));
    element = document.getElementById(id);
  }
  return element;
}

function releaseStream() {
  if (videoStream) {
    videoStream.getTracks().forEach(track => track.stop());
    videoStream = null;
  }
}

function stopCamera() {
  startToken++;
  releaseStream();
  if (videoElement) {
    videoElement.pause();
    videoElement.srcObject = null;
    videoElement = null;
  }
}

async function takePicture() {
  if (!videoElement || !videoElement.videoWidth) {
    console.error('Video element not ready');
    return null;
  }

  const canvas = document.createElement('canvas');
  canvas.width = videoElement.videoWidth;
  canvas.height = videoElement.videoHeight;

  const ctx = canvas.getContext('2d');
  ctx.drawImage(videoElement, 0, 0, canvas.width, canvas.height);

  const base64Image = canvas.toDataURL('image/png');
  return base64Image;
}

async function requestCameraPermission() {
  try {
    const stream = await navigator.mediaDevices.getUserMedia({ video: true });
    stream.getTracks().forEach(track => track.stop());
    return true;
  } catch (err) {
    console.error('Camera permission denied or error:', err);
    return false;
  }
}
window.getAvailableCameras = getAvailableCameras;
window.startCamera = startCamera;
window.stopCamera = stopCamera;
window.takePicture = takePicture;
window.requestCameraPermission = requestCameraPermission;
