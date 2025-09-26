const { VisualAnalyzer } = require('./visual-analyzer');
const { SimilarityEngine } = require('./similarity-engine');
const fs = require('fs').promises;
const path = require('path');

class PixelBuilder {
  constructor(targetUrl) {
    this.targetUrl = targetUrl;
    this.outputDir = path.join(__dirname, 'pixel-build');
    this.similarity = new SimilarityEngine();
    this.buildSteps = [];
    this.currentSimilarity = 0;
  }

  async build() {
    console.log('🎯 PIXEL BUILDER - Incremental Visual Matching');
    console.log('='.repeat(50));
    
    await fs.mkdir(this.outputDir, { recursive: true });
    
    // Step 1: Analyze target visually
    console.log('\n📸 Step 1: Visual Analysis');
    const analyzer = new VisualAnalyzer(this.targetUrl);
    const analysis = await analyzer.analyze();
    
    // Step 2: Build base structure
    console.log('\n🏗️ Step 2: Base Structure');
    let currentHtml = this.createBaseHtml();
    await this.saveAndTest(currentHtml, 'base');
    
    // Step 3: Add elements incrementally
    console.log('\n🔨 Step 3: Incremental Building');
    const topElements = analysis.elements
      .filter(el => el.y < 600) // Focus on above-fold content
      .sort((a, b) => a.y - b.y) // Build top to bottom
      .slice(0, 5); // Limit to most important elements

    for (let i = 0; i < topElements.length; i++) {
      const element = topElements[i];
      console.log(`\n  Adding element ${i + 1}: ${element.tag} (${element.width}x${element.height})`);
      
      currentHtml = this.addElement(currentHtml, element, i);
      const stepResults = await this.saveAndTest(currentHtml, `step-${i + 1}`);
      
      // Stop if similarity drops significantly
      if (stepResults.similarity < this.currentSimilarity - 10) {
        console.log(`  ❌ Similarity dropped to ${stepResults.similarity}%, stopping`);
        break;
      }
      
      this.currentSimilarity = stepResults.similarity;
      console.log(`  ✅ Step ${i + 1} similarity: ${stepResults.similarity}%`);
    }
    
    // Final results
    console.log('\n📊 Final Build Results:');
    console.log(`  Steps completed: ${this.buildSteps.length}`);
    console.log(`  Final similarity: ${this.currentSimilarity}%`);
    console.log(`  Output files: ${this.outputDir}`);
    
    return {
      finalHtml: currentHtml,
      similarity: this.currentSimilarity,
      steps: this.buildSteps
    };
  }

  createBaseHtml() {
    return `<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Pixel-Perfect Clone</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body { 
            font-family: system-ui, -apple-system, sans-serif;
            background: #111113;
            color: #edeeef;
            width: 1280px;
            min-height: 1024px;
        }
        .container { width: 100%; position: relative; }
    </style>
</head>
<body>
    <div class="container">
        <!-- Elements will be added here incrementally -->
    </div>
</body>
</html>`;
  }

  addElement(currentHtml, element, index) {
    // Create CSS for the element based on visual analysis
    const elementCss = `
        .element-${index} {
            position: absolute;
            left: ${element.x}px;
            top: ${element.y}px;
            width: ${element.width}px;
            height: ${element.height}px;
            background-color: ${element.backgroundColor};
            color: ${element.color};
            font-size: ${element.fontSize}px;
            font-weight: ${element.fontWeight};
            overflow: hidden;
            ${element.text ? 'display: flex; align-items: center; padding: 8px;' : ''}
        }`;

    const elementHtml = `
        <div class="element-${index}">
            ${element.text ? this.truncateText(element.text, 50) : ''}
        </div>`;

    // Insert CSS before </style>
    currentHtml = currentHtml.replace('</style>', elementCss + '\n    </style>');
    
    // Insert element before </div>
    currentHtml = currentHtml.replace('<!-- Elements will be added here incrementally -->', 
        `<!-- Elements will be added here incrementally -->\n        ${elementHtml}`);

    return currentHtml;
  }

  truncateText(text, maxLength) {
    if (!text) return '';
    return text.length > maxLength ? text.substring(0, maxLength) + '...' : text;
  }

  async saveAndTest(html, stepName) {
    // Save HTML file
    const htmlPath = path.join(this.outputDir, `${stepName}.html`);
    await fs.writeFile(htmlPath, html);
    
    // Test similarity
    const results = await this.similarity.comparePages(this.targetUrl, htmlPath);
    
    // Save step results
    const stepData = {
      step: stepName,
      similarity: results.overallSimilarity,
      htmlPath,
      timestamp: new Date().toISOString()
    };
    
    this.buildSteps.push(stepData);
    
    return {
      similarity: results.overallSimilarity,
      results
    };
  }
}

// Usage
async function runPixelBuild() {
  const builder = new PixelBuilder('https://forward.digital');
  try {
    const results = await builder.build();
    console.log('\n✅ Pixel build complete');
    return results;
  } catch (error) {
    console.error('❌ Build failed:', error.message);
  }
}

if (require.main === module) {
  runPixelBuild();
}

module.exports = { PixelBuilder };