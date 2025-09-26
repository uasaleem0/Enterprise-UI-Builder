const playwright = require('playwright');
const fs = require('fs').promises;
const path = require('path');

class VisualAnalyzer {
  constructor(targetUrl) {
    this.targetUrl = targetUrl;
    this.outputDir = path.join(__dirname, 'visual-analysis');
  }

  async analyze() {
    console.log('📸 VISUAL ANALYZER - Screenshot-based Analysis');
    console.log('='.repeat(50));
    
    await fs.mkdir(this.outputDir, { recursive: true });
    
    const browser = await playwright.chromium.launch({ headless: true });
    const context = await browser.newContext({ viewport: { width: 1280, height: 1024 } });
    const page = await context.newPage();
    
    console.log(`Loading: ${this.targetUrl}`);
    await page.goto(this.targetUrl, { waitUntil: 'networkidle', timeout: 15000 });
    
    // Take reference screenshot
    const screenshotPath = path.join(this.outputDir, 'target-reference.png');
    await page.screenshot({ path: screenshotPath, fullPage: false });
    console.log(`✅ Reference screenshot: ${screenshotPath}`);
    
    // Extract visual patterns from the actual rendered page
    const visualData = await page.evaluate(() => {
      // Get visual bounds of significant elements
      const elements = Array.from(document.querySelectorAll('*')).filter(el => {
        const rect = el.getBoundingClientRect();
        return rect.width > 100 && rect.height > 50 && rect.top < 1024;
      });

      return elements.map(el => {
        const rect = el.getBoundingClientRect();
        const styles = window.getComputedStyle(el);
        
        return {
          tag: el.tagName.toLowerCase(),
          x: Math.round(rect.x),
          y: Math.round(rect.y), 
          width: Math.round(rect.width),
          height: Math.round(rect.height),
          backgroundColor: styles.backgroundColor,
          color: styles.color,
          fontSize: parseInt(styles.fontSize) || 16,
          fontWeight: styles.fontWeight,
          text: el.textContent?.trim().substring(0, 100) || '',
          hasBackground: styles.backgroundColor !== 'rgba(0, 0, 0, 0)',
          isVisible: rect.width > 0 && rect.height > 0
        };
      }).slice(0, 20); // Limit to most significant elements
    });

    await browser.close();

    // Analyze visual patterns
    const analysis = this.analyzeVisualPatterns(visualData);
    
    // Save analysis
    const analysisPath = path.join(this.outputDir, 'visual-analysis.json');
    await fs.writeFile(analysisPath, JSON.stringify(analysis, null, 2));
    
    console.log('\n📊 Visual Analysis Results:');
    console.log(`  Primary elements: ${analysis.elements.length}`);
    console.log(`  Layout type: ${analysis.layoutType}`);
    console.log(`  Color palette: ${analysis.colors.length} colors`);
    console.log(`  Typography: ${analysis.typography.length} styles`);
    
    return analysis;
  }

  analyzeVisualPatterns(visualData) {
    // Detect layout patterns from visual positioning
    const layoutType = this.detectLayoutType(visualData);
    
    // Extract color palette from visible elements
    const colors = [...new Set(
      visualData
        .filter(el => el.hasBackground)
        .map(el => el.backgroundColor)
    )].slice(0, 10);

    // Extract typography patterns
    const typography = [...new Set(
      visualData
        .filter(el => el.text)
        .map(el => ({
          fontSize: el.fontSize,
          fontWeight: el.fontWeight,
          color: el.color
        }))
    )].slice(0, 8);

    // Identify key visual regions
    const regions = this.identifyRegions(visualData);

    return {
      layoutType,
      colors,
      typography,
      regions,
      elements: visualData,
      viewport: { width: 1280, height: 1024 },
      timestamp: new Date().toISOString()
    };
  }

  detectLayoutType(elements) {
    // Simple layout detection based on element positioning
    const topElements = elements.filter(el => el.y < 200);
    const hasLeftColumn = elements.some(el => el.x < 100 && el.height > 300);
    const hasRightColumn = elements.some(el => el.x > 900 && el.height > 300);
    
    if (hasLeftColumn && hasRightColumn) return 'three-column';
    if (hasLeftColumn || hasRightColumn) return 'two-column';
    if (topElements.length > 3) return 'header-content';
    return 'single-column';
  }

  identifyRegions(elements) {
    const regions = {
      header: elements.filter(el => el.y < 100),
      hero: elements.filter(el => el.y >= 100 && el.y < 600 && el.height > 200),
      content: elements.filter(el => el.y >= 600)
    };

    return Object.entries(regions).map(([name, els]) => ({
      name,
      count: els.length,
      bounds: els.length > 0 ? {
        top: Math.min(...els.map(el => el.y)),
        bottom: Math.max(...els.map(el => el.y + el.height)),
        left: Math.min(...els.map(el => el.x)),
        right: Math.max(...els.map(el => el.x + el.width))
      } : null
    }));
  }
}

// Usage
async function runVisualAnalysis() {
  const analyzer = new VisualAnalyzer('https://forward.digital');
  try {
    const analysis = await analyzer.analyze();
    console.log('\n✅ Visual analysis complete');
    return analysis;
  } catch (error) {
    console.error('❌ Analysis failed:', error.message);
  }
}

if (require.main === module) {
  runVisualAnalysis();
}

module.exports = { VisualAnalyzer };