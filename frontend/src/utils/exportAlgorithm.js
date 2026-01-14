/**
 * Generate a clean Markdown representation of an algorithm
 */
export function generateMarkdown(algorithm) {
  const sections = []

  // Title and metadata
  sections.push(`# ${algorithm.name}`)
  sections.push(``)
  sections.push(`**Category:** ${algorithm.category}  `)
  sections.push(`**Difficulty:** ${algorithm.difficulty}  `)
  sections.push(`**Tags:** ${algorithm.tags.join(', ')}`)
  sections.push(``)

  // Description
  sections.push(`## Description`)
  sections.push(``)
  sections.push(algorithm.description)
  sections.push(``)

  // Key Insight
  if (algorithm.keyInsight) {
    sections.push(`## Key Insight`)
    sections.push(``)
    sections.push(`> ${algorithm.keyInsight}`)
    sections.push(``)
  }

  // Recognition Hints
  if (algorithm.recognitionHints && algorithm.recognitionHints.length > 0) {
    sections.push(`## How to Recognize`)
    sections.push(``)
    algorithm.recognitionHints.forEach(hint => {
      sections.push(`- ${hint}`)
    })
    sections.push(``)
  }

  // When to Use
  if (algorithm.whenToUse && algorithm.whenToUse.length > 0) {
    sections.push(`## When to Use`)
    sections.push(``)
    algorithm.whenToUse.forEach(use => {
      sections.push(`- ${use}`)
    })
    sections.push(``)
  }

  // Pseudo Code
  sections.push(`## Pseudo Code`)
  sections.push(``)
  sections.push('```')
  sections.push(algorithm.pseudoCode)
  sections.push('```')
  sections.push(``)

  // Complexity
  sections.push(`## Complexity`)
  sections.push(``)
  sections.push(`- **Time:** ${algorithm.complexity.time}`)
  sections.push(`- **Space:** ${algorithm.complexity.space}`)
  sections.push(``)

  // Common Pitfalls
  if (algorithm.commonPitfalls && algorithm.commonPitfalls.length > 0) {
    sections.push(`## Common Pitfalls`)
    sections.push(``)
    algorithm.commonPitfalls.forEach(pitfall => {
      sections.push(`- ${pitfall}`)
    })
    sections.push(``)
  }

  // Related Algorithms
  if (algorithm.relatedAlgos && algorithm.relatedAlgos.length > 0) {
    sections.push(`## Related Algorithms`)
    sections.push(``)
    algorithm.relatedAlgos.forEach(related => {
      sections.push(`- ${related}`)
    })
    sections.push(``)
  }

  // Resources
  if (algorithm.resources && algorithm.resources.length > 0) {
    sections.push(`## Resources`)
    sections.push(``)
    algorithm.resources.forEach(resource => {
      sections.push(`- ${resource}`)
    })
    sections.push(``)
  }

  // Footer
  sections.push(`---`)
  sections.push(`*Exported from AoC Algo Buddy on ${new Date().toLocaleDateString()}*`)

  return sections.join('\n')
}

/**
 * Download content as a file
 */
export function downloadFile(content, filename, mimeType) {
  const blob = new Blob([content], { type: mimeType })
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  document.body.appendChild(link)
  link.click()
  document.body.removeChild(link)
  URL.revokeObjectURL(url)
}

/**
 * Download algorithm as Markdown file
 */
export function downloadAsMarkdown(algorithm) {
  const markdown = generateMarkdown(algorithm)
  const filename = `${algorithm.id}-algorithm.md`
  downloadFile(markdown, filename, 'text/markdown')
}

/**
 * Generate printable HTML for PDF export
 */
export function generatePrintableHTML(algorithm) {
  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>${algorithm.name} - AoC Algo Buddy</title>
  <style>
    * {
      box-sizing: border-box;
    }
    body {
      font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
      line-height: 1.6;
      max-width: 800px;
      margin: 0 auto;
      padding: 2rem;
      color: #333;
    }
    h1 {
      font-size: 2rem;
      margin-bottom: 0.5rem;
      border-bottom: 2px solid #00d9ff;
      padding-bottom: 0.5rem;
    }
    h2 {
      font-size: 1.25rem;
      margin-top: 1.5rem;
      margin-bottom: 0.75rem;
      color: #00a0c0;
    }
    .meta {
      display: flex;
      gap: 1rem;
      margin-bottom: 1rem;
      font-size: 0.9rem;
      color: #666;
    }
    .badge {
      padding: 0.25rem 0.5rem;
      border-radius: 4px;
      font-size: 0.8rem;
    }
    .category { background: #e3f2fd; color: #1976d2; }
    .difficulty-beginner { background: #e8f5e9; color: #388e3c; }
    .difficulty-intermediate { background: #fff3e0; color: #f57c00; }
    .difficulty-advanced { background: #ffebee; color: #d32f2f; }
    .tags {
      display: flex;
      flex-wrap: wrap;
      gap: 0.5rem;
      margin-bottom: 1.5rem;
    }
    .tag {
      padding: 0.2rem 0.5rem;
      background: #f5f5f5;
      border-radius: 4px;
      font-size: 0.8rem;
      color: #666;
    }
    blockquote {
      margin: 1rem 0;
      padding: 1rem;
      background: #f8f9fa;
      border-left: 4px solid #00d9ff;
      font-style: italic;
    }
    ul {
      padding-left: 1.5rem;
    }
    li {
      margin-bottom: 0.5rem;
    }
    pre {
      background: #1e1e1e;
      color: #f0f0f0;
      padding: 1rem;
      border-radius: 8px;
      overflow-x: auto;
      font-family: 'Fira Code', 'Consolas', monospace;
      font-size: 0.9rem;
      line-height: 1.5;
    }
    .complexity {
      display: flex;
      gap: 2rem;
      padding: 1rem;
      background: #f8f9fa;
      border-radius: 8px;
    }
    .complexity-item {
      display: flex;
      gap: 0.5rem;
    }
    .complexity-label {
      font-weight: 600;
    }
    .footer {
      margin-top: 2rem;
      padding-top: 1rem;
      border-top: 1px solid #ddd;
      font-size: 0.8rem;
      color: #999;
      text-align: center;
    }
    @media print {
      body { padding: 0; }
      pre { white-space: pre-wrap; word-wrap: break-word; }
    }
  </style>
</head>
<body>
  <h1>${algorithm.name}</h1>

  <div class="meta">
    <span class="badge category">${algorithm.category}</span>
    <span class="badge difficulty-${algorithm.difficulty.toLowerCase()}">${algorithm.difficulty}</span>
  </div>

  <div class="tags">
    ${algorithm.tags.map(tag => `<span class="tag">${tag}</span>`).join('')}
  </div>

  <h2>Description</h2>
  <p>${algorithm.description}</p>

  ${algorithm.keyInsight ? `
  <h2>Key Insight</h2>
  <blockquote>${algorithm.keyInsight}</blockquote>
  ` : ''}

  ${algorithm.recognitionHints && algorithm.recognitionHints.length > 0 ? `
  <h2>How to Recognize</h2>
  <ul>
    ${algorithm.recognitionHints.map(hint => `<li>${hint}</li>`).join('')}
  </ul>
  ` : ''}

  ${algorithm.whenToUse && algorithm.whenToUse.length > 0 ? `
  <h2>When to Use</h2>
  <ul>
    ${algorithm.whenToUse.map(use => `<li>${use}</li>`).join('')}
  </ul>
  ` : ''}

  <h2>Pseudo Code</h2>
  <pre>${algorithm.pseudoCode.replace(/</g, '&lt;').replace(/>/g, '&gt;')}</pre>

  <h2>Complexity</h2>
  <div class="complexity">
    <div class="complexity-item">
      <span class="complexity-label">Time:</span>
      <span>${algorithm.complexity.time}</span>
    </div>
    <div class="complexity-item">
      <span class="complexity-label">Space:</span>
      <span>${algorithm.complexity.space}</span>
    </div>
  </div>

  ${algorithm.commonPitfalls && algorithm.commonPitfalls.length > 0 ? `
  <h2>Common Pitfalls</h2>
  <ul>
    ${algorithm.commonPitfalls.map(pitfall => `<li>${pitfall}</li>`).join('')}
  </ul>
  ` : ''}

  ${algorithm.relatedAlgos && algorithm.relatedAlgos.length > 0 ? `
  <h2>Related Algorithms</h2>
  <ul>
    ${algorithm.relatedAlgos.map(related => `<li>${related}</li>`).join('')}
  </ul>
  ` : ''}

  ${algorithm.resources && algorithm.resources.length > 0 ? `
  <h2>Resources</h2>
  <ul>
    ${algorithm.resources.map(resource => `<li><a href="${resource}">${resource}</a></li>`).join('')}
  </ul>
  ` : ''}

  <div class="footer">
    Exported from AoC Algo Buddy on ${new Date().toLocaleDateString()}
  </div>
</body>
</html>
`
}

/**
 * Export algorithm as PDF using browser print
 */
export function exportAsPDF(algorithm) {
  const html = generatePrintableHTML(algorithm)
  const printWindow = window.open('', '_blank')

  if (printWindow) {
    printWindow.document.write(html)
    printWindow.document.close()

    // Wait for content to load, then trigger print
    printWindow.onload = () => {
      printWindow.focus()
      printWindow.print()
    }
  }
}
