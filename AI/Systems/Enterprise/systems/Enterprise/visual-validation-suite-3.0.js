/**
 * VisualValidationSuite 3.0
 * Abstraction over visual similarity: prefers Microsoft/Playwright similarity (pass/fail),
 * gracefully falls back to pixel-based diff (pixelmatch) when unavailable.
 */

const fs = require('fs');
const path = require('path');

class VisualValidationSuite3_0 {
  constructor(logger = console) {
    this.logger = logger;
    this.pixelmatch = null;
    this.PNG = null;
    this._initFallback();
  }

  _initFallback() {
    try {
      this.pixelmatch = require('pixelmatch');
      this.PNG = require('pngjs').PNG;
    } catch (e) {
      // Fallback not available; compareImages will report gracefully
      this.pixelmatch = null;
      this.PNG = null;
    }
  }

  isMicrosoftSimilarityAvailable() {
    // Heuristic: allow environment flag to indicate availability
    // Integrators can set MS_PLAYWRIGHT_SIMILARITY=1 when the adapter is wired.
    return process.env.MS_PLAYWRIGHT_SIMILARITY === '1' || typeof global.msSimilarityCompare === 'function';
  }

  async compareWithMicrosoftAdapter(baselinePath, candidatePath, options = {}) {
    // Expected to return a boolean pass/fail. Integrators should provide global.msSimilarityCompare
    // with signature async (baselinePath, candidatePath, options) => boolean
    if (typeof global.msSimilarityCompare === 'function') {
      try {
        const passed = await global.msSimilarityCompare(baselinePath, candidatePath, options);
        return { passed, score: null, engine: 'microsoft' };
      } catch (e) {
        this.logger.log('[visual] Microsoft adapter failed, falling back:', e.message || e);
      }
    } else {
      this.logger.log('[visual] Microsoft adapter not present; set MS_PLAYWRIGHT_SIMILARITY=1 and provide global.msSimilarityCompare');
    }
    return { passed: null, score: null, engine: 'microsoft' };
  }

  async compareWithPixelmatch(baselinePath, candidatePath, options = {}) {
    if (!this.pixelmatch || !this.PNG) {
      return { passed: null, score: null, engine: 'pixelmatch', message: 'pixelmatch/pngjs not installed' };
    }
    const { maxDiffPct = 0.015 } = options; // 1.5% default tolerance
    const a = this.PNG.sync.read(fs.readFileSync(baselinePath));
    const b = this.PNG.sync.read(fs.readFileSync(candidatePath));
    if (a.width !== b.width || a.height !== b.height) {
      return { passed: false, score: 0, engine: 'pixelmatch', message: 'dimension mismatch' };
    }
    const diffPixels = this.pixelmatch(a.data, b.data, null, a.width, a.height, { threshold: 0.1 });
    const totalPixels = a.width * a.height;
    const diffRatio = diffPixels / totalPixels; // 0..1
    const score = Math.max(0, 100 - diffRatio * 100); // 100==identical
    const passed = diffRatio <= maxDiffPct;
    return { passed, score: Math.round(score), engine: 'pixelmatch' };
  }

  /**
   * Compare two images and return { passed, score, engine }
   * If Microsoft adapter available, returns pass/fail with null score.
   * Otherwise uses pixelmatch to compute a score and pass/fail based on maxDiffPct.
   */
  async compareImages(baselinePath, candidatePath, options = {}) {
    if (this.isMicrosoftSimilarityAvailable()) {
      const res = await this.compareWithMicrosoftAdapter(baselinePath, candidatePath, options);
      if (typeof res.passed === 'boolean') return res;
      // fall through to pixelmatch if adapter failed
    }
    return await this.compareWithPixelmatch(baselinePath, candidatePath, options);
  }

  /**
   * High-level validation used by Protocol 3.0.
   * Attempts to call a provided global MCP validator first, then Microsoft adapter, then pixel fallback.
   * Returns: { success: boolean, similarity: number, issues: Array<{description: string}> }
   */
  async runComprehensiveValidation(localPreviewUrl, targetUrl, options = {}) {
    try {
      if (typeof global.mcpVisualValidate === 'function') {
        const r = await global.mcpVisualValidate(localPreviewUrl, targetUrl, options);
        return {
          success: !!r && (!!r.passed || (typeof r.similarity === 'number' && r.similarity > 0)),
          similarity: typeof r.similarity === 'number' ? r.similarity : (r.passed ? 100 : 0),
          issues: Array.isArray(r.issues) ? r.issues : []
        };
      }

      // If no MCP validator, we rely on image comparison; expect options to include paths when used.
      if (options.baselinePath && options.candidatePath) {
        if (this.isMicrosoftSimilarityAvailable()) {
          const ms = await this.compareWithMicrosoftAdapter(options.baselinePath, options.candidatePath, options);
          return {
            success: typeof ms.passed === 'boolean' ? ms.passed : false,
            similarity: typeof ms.score === 'number' ? ms.score : (ms.passed ? 100 : 0),
            issues: []
          };
        }
        const px = await this.compareWithPixelmatch(options.baselinePath, options.candidatePath, options);
        return {
          success: typeof px.passed === 'boolean' ? px.passed : false,
          similarity: typeof px.score === 'number' ? px.score : 0,
          issues: px.message ? [{ description: px.message }] : []
        };
      }

      // No engines available
      return { success: false, similarity: 0, issues: [{ description: 'No validation engine available' }] };
    } catch (e) {
      return { success: false, similarity: 0, issues: [{ description: e.message || String(e) }] };
    }
  }
}

module.exports = { VisualValidationSuite3_0 };
