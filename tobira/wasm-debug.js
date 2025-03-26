// WebAssembly debug utilities
console.log('WASM debug utilities loaded');

// Memory tracking
let wasmMemoryStats = {
  initial: 0,
  current: 0,
  peak: 0,
  allocations: 0
};

// Track WASM memory usage
function trackWasmMemory(memory) {
  if (!memory) return;
  
  // Initial memory
  const initialBytes = memory.buffer.byteLength;
  wasmMemoryStats.initial = initialBytes;
  wasmMemoryStats.current = initialBytes;
  wasmMemoryStats.peak = initialBytes;
  
  console.log(`[WASM Memory] Initial allocation: ${formatBytes(initialBytes)}`);
  
  // Override grow to track expansions
  const originalGrow = memory.grow;
  memory.grow = function(pages) {
    const result = originalGrow.call(this, pages);
    const newSize = memory.buffer.byteLength;
    const delta = newSize - wasmMemoryStats.current;
    
    wasmMemoryStats.allocations++;
    wasmMemoryStats.current = newSize;
    wasmMemoryStats.peak = Math.max(wasmMemoryStats.peak, newSize);
    
    console.log(`[WASM Memory] Expanded by ${formatBytes(delta)} to ${formatBytes(newSize)} (${pages} pages)`);
    console.log(`[WASM Memory] Peak usage: ${formatBytes(wasmMemoryStats.peak)}`);
    
    return result;
  };
  
  return wasmMemoryStats;
}

// Format bytes to human readable format
function formatBytes(bytes, decimals = 2) {
  if (bytes === 0) return '0 Bytes';
  
  const k = 1024;
  const dm = decimals < 0 ? 0 : decimals;
  const sizes = ['Bytes', 'KB', 'MB', 'GB'];
  
  const i = Math.floor(Math.log(bytes) / Math.log(k));
  
  return parseFloat((bytes / Math.pow(k, i)).toFixed(dm)) + ' ' + sizes[i];
}

// Performance monitoring
class WasmPerformanceMonitor {
  constructor() {
    this.markers = {};
    this.measures = [];
  }
  
  startMeasure(name) {
    const markName = `${name}-start`;
    performance.mark(markName);
    this.markers[name] = markName;
    console.log(`[Performance] Started measuring: ${name}`);
    return markName;
  }
  
  endMeasure(name) {
    const startMark = this.markers[name];
    if (!startMark) {
      console.error(`No start mark found for: ${name}`);
      return null;
    }
    
    const endMark = `${name}-end`;
    performance.mark(endMark);
    
    const measureName = `measure-${name}`;
    performance.measure(measureName, startMark, endMark);
    
    const duration = performance.getEntriesByName(measureName)[0].duration;
    console.log(`[Performance] ${name}: ${duration.toFixed(2)}ms`);
    
    this.measures.push({
      name,
      duration,
      timestamp: Date.now()
    });
    
    delete this.markers[name];
    return duration;
  }
  
  getReport() {
    return this.measures;
  }
  
  clearMeasures() {
    this.measures = [];
    performance.clearMarks();
    performance.clearMeasures();
  }
}

// Create global instances
window.wasmPerformance = new WasmPerformanceMonitor();
window.trackWasmMemory = trackWasmMemory;

// Error tracking
class WasmErrorTracker {
  constructor() {
    this.errors = [];
    this.setupGlobalHandlers();
  }
  
  setupGlobalHandlers() {
    // Store original console.error
    const originalConsoleError = console.error;
    
    // Override console.error
    console.error = (...args) => {
      this.trackError('console.error', args.join(' '));
      originalConsoleError.apply(console, args);
    };
    
    // Global error handler
    window.addEventListener('error', (event) => {
      this.trackError('window.error', event.message, event.filename, event.lineno);
    });
    
    // Unhandled promise rejection handler
    window.addEventListener('unhandledrejection', (event) => {
      this.trackError('promise.rejection', event.reason);
    });
  }
  
  trackError(source, message, file = null, line = null) {
    const error = {
      timestamp: Date.now(),
      source,
      message,
      file,
      line
    };
    
    this.errors.push(error);
    return error;
  }
  
  getErrors() {
    return this.errors;
  }
  
  clearErrors() {
    this.errors = [];
  }
}

// Create global error tracker
window.wasmErrorTracker = new WasmErrorTracker();

// Expose utilities to global scope
window.wasmDebug = {
  memory: wasmMemoryStats,
  performance: window.wasmPerformance,
  errors: window.wasmErrorTracker,
  formatBytes
};

console.log('WASM debug utilities ready');