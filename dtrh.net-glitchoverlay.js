// Glitch Overlay Effect - DTRH.net
// Binary rain overlay that only appears during glitches (not continuous)
// Black/white/greys color scheme, violent flashes lasting 0.25-0.75s

(function() {
  'use strict';

  // ============================================================
  // STYLES
  // ============================================================
  const style = document.createElement('style');
  style.id = 'glitch-overlay-style';
  style.textContent = `
@keyframes scanlineMove { 0% { background-position: 0 0; } 100% { background-position: 0 6px; } }
@keyframes binaryFall { 0% { transform: translateY(-100%); opacity: 0; } 10% { opacity: 1; } 90% { opacity: 1; } 100% { transform: translateY(100vh); opacity: 0; } }
@keyframes binaryFlicker { 0%, 100% { opacity: 1; } 50% { opacity: 0.3; } }
@keyframes screenShake { 0%, 100% { transform: translate(0, 0) rotate(0); } 10% { transform: translate(-3px, 2px) rotate(-0.5deg); } 20% { transform: translate(3px, -2px) rotate(0.5deg); } 30% { transform: translate(-2px, 3px) rotate(-0.3deg); } 40% { transform: translate(2px, -3px) rotate(0.3deg); } 50% { transform: translate(-3px, -2px) rotate(0.5deg); } 60% { transform: translate(3px, 2px) rotate(-0.5deg); } 70% { transform: translate(-2px, -3px) rotate(0.3deg); } 80% { transform: translate(2px, 3px) rotate(-0.3deg); } 90% { transform: translate(-3px, 3px) rotate(0.5deg); } }
@keyframes glitchFlash { 
  0% { filter: none; } 
  15% { filter: invert(1) contrast(2) hue-rotate(180deg); } 
  30% { filter: grayscale(1) contrast(3) brightness(0.5); } 
  45% { filter: invert(0.5) contrast(2) sepia(1); } 
  60% { filter: grayscale(1) contrast(2) brightness(1.5); } 
  100% { filter: none; } 
}
`;
  document.head.appendChild(style);

  // ============================================================
  // OVERLAY ELEMENTS
  // ============================================================
  const overlay = document.createElement('div');
  overlay.id = 'glitch-overlay';
  overlay.style.cssText = `
    position: fixed; top: 0; left: 0; width: 100%; height: 100%;
    pointer-events: none; z-index: 9999; opacity: 0; overflow: hidden;
    background: transparent;
  `;
  document.body.appendChild(overlay);

  const scanlines = document.createElement('div');
  scanlines.id = 'glitch-scanlines';
  scanlines.style.cssText = `
    position: absolute; top: 0; left: 0; width: 100%; height: 100%;
    background: repeating-linear-gradient(0deg, rgba(0,0,0,0.15), rgba(0,0,0,0.15) 1px, transparent 1px, transparent 3px);
    animation: scanlineMove 0.1s linear infinite; opacity: 0; pointer-events: none;
  `;
  overlay.appendChild(scanlines);

  // ============================================================
  // BINARY COLUMN CREATION
  // ============================================================
  function createBinaryColumn() {
    const column = document.createElement('div');
    column.style.cssText = `
      position: absolute; top: -100vh; font-family: monospace;
      font-size: 14px; line-height: 1.3; white-space: nowrap;
      opacity: 0; will-change: transform, opacity;
    `;
    column.style.left = Math.random() * 100 + '%';
    const duration = 3 + Math.random() * 3;
    column.style.animation = `binaryFall ${duration}s linear, binaryFlicker 0.05s infinite`;
    
    let binary = '';
    const length = 30 + Math.floor(Math.random() * 40);
    for (let i = 0; i < length; i++) {
      binary += Math.random() > 0.5 ? '1' : '0';
      if (i % 8 === 7) binary += '\n';
    }
    column.textContent = binary;
    
    const brightness = 150 + Math.floor(Math.random() * 105);
    column.style.color = `rgb(${brightness}, ${brightness}, ${brightness})`;
    column.style.textShadow = `0 0 5px rgb(${brightness}, ${brightness}, ${brightness}), 0 0 10px rgb(${Math.floor(brightness/2)}, ${Math.floor(brightness/2)}, ${Math.floor(brightness/2)})`;
    
    overlay.appendChild(column);
    return column;
  }

  // ============================================================
  // GLITCH CYCLE LOGIC
  // ============================================================
  let isGlitching = false;

  function endGlitch() {
    overlay.style.opacity = '0';
    scanlines.style.opacity = '0';
    document.body.style.animation = '';
    document.documentElement.style.animation = '';
    setTimeout(() => {
      overlay.querySelectorAll('div:not(#glitch-scanlines)').forEach(col => col.remove());
    }, 500);
    isGlitching = false;
    scheduleNextGlitch();
  }

  function triggerGlitch() {
    if (isGlitching) return;
    isGlitching = true;
    overlay.style.opacity = '1';
    scanlines.style.opacity = '0.5';
    document.body.style.animation = 'screenShake 0.08s ease-in-out infinite';
    document.body.style.transformOrigin = 'center center';
    
    // Random flash duration between 0.25s and 0.75s - runs ONCE per glitch
    const flashDuration = (0.25 + Math.random() * 0.5).toFixed(3);
    document.documentElement.style.animation = `glitchFlash ${flashDuration}s linear forwards`;
    
    const columnsToSpawn = 50 + Math.floor(Math.random() * 30);
    for (let i = 0; i < columnsToSpawn; i++) {
      setTimeout(createBinaryColumn, i * 25);
    }
    
    const glitchDuration = 2500 + Math.random() * 1500;
    window.glitchTimeout = setTimeout(endGlitch, glitchDuration);
  }

  function scheduleNextGlitch() {
    const delay = 12000 + Math.random() * 8000; // 12-20 seconds
    window.glitchTimeout = setTimeout(triggerGlitch, delay);
  }

  // Optional: hover trigger (10% chance)
  document.addEventListener('mouseover', (e) => {
    if (!isGlitching && Math.random() < 0.1) triggerGlitch();
  }, true);

  // Start the cycle
  scheduleNextGlitch();

  // Expose for debugging
  window.glitchOverlay = {
    trigger: triggerGlitch,
    end: endGlitch,
    isGlitching: () => isGlitching
  };
})();