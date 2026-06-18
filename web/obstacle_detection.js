/**
 * Obstacle detection helper for Iris PWA.
 *
 * Loads the COCO-SSD object-detection model and exposes a small API for
 * Dart to start/stop the camera and run detection frames.
 *
 * Why COCO-SSD? It runs entirely in the browser (no backend), works offline
 * after the model is cached, and gives us bounding boxes we can use as a
 * proxy for proximity: the larger an object appears in the frame, the closer
 * it probably is.
 */

(function () {
  let video = null;
  let stream = null;
  let model = null;
  let isRunning = false;

  async function loadModel() {
    if (model) return model;
    if (typeof cocoSsd === 'undefined') {
      throw new Error('COCO-SSD library not loaded');
    }
    model = await cocoSsd.load({ base: 'lite_mobilenet_v2' });
    return model;
  }

  async function startCamera(containerId) {
    if (isRunning) return;

    const constraints = {
      video: {
        facingMode: 'environment',
        width: { ideal: 640 },
        height: { ideal: 480 },
      },
      audio: false,
    };

    stream = await navigator.mediaDevices.getUserMedia(constraints);

    video = document.createElement('video');
    video.srcObject = stream;
    video.autoplay = true;
    video.playsInline = true;
    video.muted = true;
    video.style.width = '100%';
    video.style.height = '100%';
    video.style.objectFit = 'cover';

    const container = document.getElementById(containerId);
    if (!container) {
      throw new Error(`Camera container #${containerId} not found`);
    }
    container.innerHTML = '';
    container.appendChild(video);

    await video.play();
    isRunning = true;

    // Return dimensions so Dart knows the frame size.
    return JSON.stringify({
      width: video.videoWidth,
      height: video.videoHeight,
    });
  }

  async function detectObstacle() {
    if (!isRunning || !video || !model) return null;

    const predictions = await model.detect(video);
    if (!predictions || predictions.length === 0) return null;

    // Pick the largest detection as the most likely obstacle.
    let largest = null;
    let largestArea = 0;
    for (const prediction of predictions) {
      const [x, y, width, height] = prediction.bbox;
      const area = width * height;
      if (area > largestArea) {
        largestArea = area;
        largest = prediction;
      }
    }

    if (!largest) return null;

    const frameArea = video.videoWidth * video.videoHeight;
    const areaRatio = frameArea > 0 ? largestArea / frameArea : 0;

    return JSON.stringify({
      class: largest.class,
      score: largest.score,
      areaRatio: areaRatio,
      bbox: largest.bbox,
      frameWidth: video.videoWidth,
      frameHeight: video.videoHeight,
    });
  }

  // Capture a single frame from the live camera as a base64 JPEG data URL.
  // Reuses the existing stream (no second getUserMedia prompt). Used to feed
  // the Gemini Vision "describe my surroundings" call. Returns null when the
  // camera isn't running or the frame isn't ready yet.
  function captureFrame(quality) {
    if (!isRunning || !video || !video.videoWidth) return null;
    const canvas = document.createElement('canvas');
    canvas.width = video.videoWidth;
    canvas.height = video.videoHeight;
    const ctx = canvas.getContext('2d');
    ctx.drawImage(video, 0, 0, canvas.width, canvas.height);
    return canvas.toDataURL('image/jpeg', quality ?? 0.7);
  }

  function stopCamera() {
    isRunning = false;

    if (stream) {
      stream.getTracks().forEach((track) => track.stop());
      stream = null;
    }

    if (video) {
      video.pause();
      video.srcObject = null;
      if (video.parentNode) {
        video.parentNode.removeChild(video);
      }
      video = null;
    }
  }

  // Expose the API globally so Dart can call it through JS interop.
  window.irisObstacleDetection = {
    loadModel,
    startCamera,
    detectObstacle,
    captureFrame,
    stopCamera,
  };
})();
