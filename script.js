// Daily Bread: full-size graphic viewer and the film's play button.

(() => {
  // ----- full-size viewer -----
  const viewer = document.getElementById('viewer');
  const viewerImg = document.getElementById('viewer-img');
  const closeBtn = document.getElementById('viewer-close');

  document.querySelectorAll('.plate__open').forEach((btn) => {
    btn.addEventListener('click', () => {
      const thumb = btn.querySelector('img');
      viewerImg.src = btn.dataset.full;
      viewerImg.alt = thumb.alt;
      if (typeof viewer.showModal === 'function') {
        viewer.showModal();
        viewer.scrollTo(0, 0);
      } else {
        // very old browsers: just open the image
        window.open(btn.dataset.full, '_blank');
      }
    });
  });

  closeBtn.addEventListener('click', () => viewer.close());
  // clicking the picture or the dark area around it closes the viewer
  viewer.addEventListener('click', (e) => {
    if (e.target === viewer || e.target === viewerImg) viewer.close();
  });

  // ----- film -----
  const video = document.getElementById('interview');
  const play = document.getElementById('play');
  const error = document.getElementById('video-error');

  // until the film starts, the big play button is the only control on screen
  video.controls = false;

  play.addEventListener('click', () => {
    video.controls = true;
    const started = video.play();
    if (started && typeof started.catch === 'function') {
      started.catch(() => { /* the native controls remain available */ });
    }
    video.focus({ preventScroll: true });
  });

  // once the film has started, the native controls take over
  video.addEventListener('play', () => { video.controls = true; play.hidden = true; });

  const showError = () => { error.hidden = false; play.hidden = true; video.controls = true; };
  video.addEventListener('error', showError);
  video.querySelector('source').addEventListener('error', showError);
})();
