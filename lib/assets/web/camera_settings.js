let videoStream = null;
let videoElement = null;

async function getAvailableCameras() {
  if (!navigator.mediaDevices || !navigator.mediaDevices.enumerateDevices) {
    console.error('enumerateDevices() not supported.');
    return [];
  }

  // Request camera permission first (optional, but required for labels)
  try {
    await navigator.mediaDevices.getUserMedia({ video: true });
  } catch (err) {
    console.warn('Permission denied or error while requesting media devices:', err);
    // Proceed anyway; labels might be empty
  }

  const devices = await navigator.mediaDevices.enumerateDevices();

  // Filter to video input devices (cameras)
  const videoDevices = devices.filter(d => d.kind === 'videoinput');

  // Map to simple serializable objects
  const cameras = videoDevices.map(device => {
    // Infer facing mode from label heuristics
    let facing = 'unknown';
    const label = device.label.toLowerCase();
    if (label.includes('back') || label.includes('rear')) {
      facing = 'environment';
    } else if (label.includes('front')) {
      facing = 'user';
    }
    return {
      deviceId: device.deviceId,
      label: device.label,
      facingMode: facing
    };
  });

  return cameras;
}

async function startCamera(videoElementId, deviceId = null, facingMode = 'environment') {
  try {
    const videoEl = document.getElementById(videoElementId);
    if (!videoEl) {
      const error = 'Video element not found: ' + videoElementId;
      console.error(error);
      return [false, error];
    }
    if (!navigator.mediaDevices || !navigator.mediaDevices.getUserMedia) {
      const error = 'getUserMedia not supported on this browser';
      console.error(error);
      return [false, error];
    }

    if (videoStream) {
      videoStream.getTracks().forEach(track => track.stop());
    }

    const constraints = deviceId
      ? { video: { deviceId: { exact: deviceId } } }
      : { video: { facingMode: facingMode } };

    const stream = await navigator.mediaDevices.getUserMedia(constraints);

    videoStream = stream;
    videoElement = videoEl;
    videoEl.srcObject = stream;
    await videoEl.play();

    return [true, null];
  } catch (e) {
    const error = e?.toString() || 'Unknown error';
    console.error('startCamera error:', error);
    return [false, error];
  }
}

function stopCamera() {
  if (videoStream) {
    videoStream.getTracks().forEach(track => track.stop());
    videoStream = null;
    console.log('Stop videoStream');
  }
  if (videoElement) {
    videoElement.pause();
    videoElement.srcObject = null;
    videoElement = null;
    console.log('Stop videoElement');
  }
}

async function takePicture() {
  if (!videoElement) {
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