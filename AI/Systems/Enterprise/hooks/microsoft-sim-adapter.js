/**
 * Microsoft Similarity Adapter Loader
 * Tries to wire global.msSimilarityCompare from an external adapter.
 * Priority:
 *  - If global.msSimilarityCompare already set, keep it
 *  - If MS_SIM_ADAPTER env points to a module, require and use it
 *  - If a known module name is available (e.g., 'ms-similarity'), try it
 *
 * Expected adapter signature:
 *   module.exports = async function (baselinePath, candidatePath, options) {
 *     // return { passed: boolean, score?: number }
 *   }
 */

(() => {
  try {
    if (typeof global.msSimilarityCompare === 'function') return;

    const path = process.env.MS_SIM_ADAPTER;
    const tryLoad = (modName) => {
      try { return require(modName); } catch { return null; }
    };

    let fn = null;
    if (path) fn = tryLoad(path);
    if (!fn) fn = tryLoad('ms-similarity');
    if (!fn) fn = tryLoad('@ms/similarity');

    if (typeof fn === 'function') {
      global.msSimilarityCompare = fn;
      if (process.env.DEBUG) console.log('[info] Microsoft similarity adapter wired from', path || 'auto');
    } else {
      if (process.env.DEBUG) console.log('[info] Microsoft similarity adapter not found');
    }
  } catch (e) {
    if (process.env.DEBUG) console.log('[warn] Microsoft similarity adapter load error:', e.message || String(e));
  }
})();

module.exports = {};

