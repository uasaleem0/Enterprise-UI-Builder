const { VisualAnalyzer } = require('./visual-analyzer');
const { SimilarityEngine } = require('./similarity-engine');
const { PixelBuilder } = require('./pixel-builder');
const fs = require('fs').promises;
const path = require('path');

/**
 * VISUAL-FIRST CLONING PIPELINE
 * 
 * Clean, linear process:
 * 1. Visual Analysis - Screenshot-based target analysis
 * 2. Pixel Building - Incremental element construction with validation
 * 3. Final Assessment - Honest similarity measurement
 */

class VisualCloningPipeline {
  constructor(targetUrl) {
    this.targetUrl = targetUrl;
    this.outputDir = path.join(__dirname, 'pipeline-results');
    this.startTime = Date.now();
  }

  async run() {
    console.log('🚀 VISUAL-FIRST CLONING PIPELINE');
    console.log('=' .repeat(60));
    console.log(`Target: ${this.targetUrl}`);
    console.log(`Started: ${new Date().toISOString()}\n`);
    
    await fs.mkdir(this.outputDir, { recursive: true });
    
    try {
      // STAGE 1: Visual Analysis
      console.log('STAGE 1: VISUAL ANALYSIS');
      console.log('-'.repeat(30));
      const analyzer = new VisualAnalyzer(this.targetUrl);
      const analysis = await analyzer.analyze();
      
      // STAGE 2: Incremental Building
      console.log('\nSTAGE 2: INCREMENTAL BUILDING');
      console.log('-'.repeat(30));
      const builder = new PixelBuilder(this.targetUrl);
      const buildResults = await builder.build();
      
      // STAGE 3: Final Assessment
      console.log('\nSTAGE 3: FINAL ASSESSMENT');
      console.log('-'.repeat(30));
      const similarity = new SimilarityEngine();
      const finalResults = await similarity.comparePages(
        this.targetUrl, 
        buildResults.steps[buildResults.steps.length - 1].htmlPath
      );
      
      // Save complete pipeline results
      const pipelineResults = {
        targetUrl: this.targetUrl,
        startTime: this.startTime,
        endTime: Date.now(),
        duration: Date.now() - this.startTime,
        analysis: {
          layoutType: analysis.layoutType,
          elementsAnalyzed: analysis.elements.length,
          colorsFound: analysis.colors.length,
          typographyStyles: analysis.typography.length
        },
        building: {
          stepsCompleted: buildResults.steps.length,
          finalHtml: buildResults.steps[buildResults.steps.length - 1].htmlPath,
          buildingStopped: buildResults.similarity < 30 // Indicating if we stopped due to quality drop
        },
        similarity: {
          overall: finalResults.overallSimilarity,
          layout: finalResults.layoutMatch,
          color: finalResults.colorMatch,
          typography: finalResults.typographyMatch,
          differences: finalResults.differences
        }
      };
      
      const resultsPath = path.join(this.outputDir, 'pipeline-results.json');
      await fs.writeFile(resultsPath, JSON.stringify(pipelineResults, null, 2));
      
      // Final Report
      this.printFinalReport(pipelineResults);
      
      return pipelineResults;
      
    } catch (error) {
      console.error('❌ Pipeline failed:', error.message);
      throw error;
    }
  }

  printFinalReport(results) {
    console.log('\n' + '='.repeat(60));
    console.log('📊 PIPELINE COMPLETE - FINAL REPORT');
    console.log('=' .repeat(60));
    
    console.log('\n⏱️  EXECUTION:');
    console.log(`  Duration: ${Math.round(results.duration / 1000)}s`);
    console.log(`  Target: ${results.targetUrl}`);
    
    console.log('\n📸 ANALYSIS:');
    console.log(`  Layout type: ${results.analysis.layoutType}`);
    console.log(`  Elements analyzed: ${results.analysis.elementsAnalyzed}`);
    console.log(`  Colors extracted: ${results.analysis.colorsFound}`);
    console.log(`  Typography styles: ${results.analysis.typographyStyles}`);
    
    console.log('\n🔨 BUILDING:');
    console.log(`  Build steps: ${results.building.stepsCompleted}`);
    console.log(`  Final HTML: ${path.basename(results.building.finalHtml)}`);
    console.log(`  Building stopped: ${results.building.buildingStopped ? 'Yes (quality drop)' : 'No'}`);
    
    console.log('\n🎯 SIMILARITY (HONEST SCORING):');
    console.log(`  Overall: ${results.similarity.overall}%`);
    console.log(`  Layout: ${results.similarity.layout}%`);
    console.log(`  Colors: ${results.similarity.color}%`);
    console.log(`  Typography: ${results.similarity.typography}%`);
    
    if (results.similarity.differences.length > 0) {
      console.log('\n❌ IDENTIFIED ISSUES:');
      results.similarity.differences.forEach(diff => {
        console.log(`  - ${diff}`);
      });
    }
    
    console.log('\n📁 OUTPUT FILES:');
    console.log(`  Results: ${path.join(this.outputDir, 'pipeline-results.json')}`);
    console.log(`  Clone HTML: ${results.building.finalHtml}`);
    console.log(`  Screenshots: similarity-results/ directory`);
    
    // Recommendation
    console.log('\n💡 RECOMMENDATION:');
    if (results.similarity.overall >= 40) {
      console.log('  ✅ Reasonable similarity achieved for this methodology');
    } else if (results.similarity.overall >= 25) {
      console.log('  ⚠️  Basic structural similarity - needs refinement');
    } else {
      console.log('  ❌ Low similarity - fundamental approach issues');
    }
    
    console.log('\n🎯 NEXT STEPS:');
    console.log('  1. Review screenshot comparisons in similarity-results/');
    console.log('  2. Examine build steps in pixel-build/ directory');
    console.log('  3. Iterate on elements that caused similarity drops');
    console.log('  4. Focus on fixing specific differences identified above');
  }
}

// MAIN EXECUTION FUNCTION
async function runVisualCloningPipeline(targetUrl = 'https://forward.digital') {
  console.log('Starting Visual-First Cloning Pipeline...\n');
  
  const pipeline = new VisualCloningPipeline(targetUrl);
  
  try {
    const results = await pipeline.run();
    console.log('\n✅ Pipeline execution complete');
    return results;
  } catch (error) {
    console.error('\n❌ Pipeline execution failed:', error.message);
    process.exit(1);
  }
}

// Run if called directly
if (require.main === module) {
  runVisualCloningPipeline();
}

module.exports = { VisualCloningPipeline, runVisualCloningPipeline };