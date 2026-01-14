/**
 * Escape HTML entities to prevent XSS attacks
 */
function escapeHtml(text) {
  if (!text) return ''
  return String(text)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#039;')
}

/**
 * Escape URL for safe use in href attributes
 */
function escapeUrl(url) {
  if (!url) return ''
  // Only allow http, https, and mailto protocols
  const trimmed = String(url).trim()
  if (!/^(https?:|mailto:)/i.test(trimmed)) {
    return ''
  }
  return encodeURI(trimmed)
}

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
 * All user-controlled content is escaped to prevent XSS attacks
 */
export function generatePrintableHTML(algorithm) {
  // Escape all user-controlled fields
  const name = escapeHtml(algorithm.name)
  const category = escapeHtml(algorithm.category)
  const difficulty = escapeHtml(algorithm.difficulty)
  const description = escapeHtml(algorithm.description)
  const keyInsight = escapeHtml(algorithm.keyInsight)
  const pseudoCode = escapeHtml(algorithm.pseudoCode)
  const timeComplexity = escapeHtml(algorithm.complexity?.time)
  const spaceComplexity = escapeHtml(algorithm.complexity?.space)

  // Escape arrays
  const tags = (algorithm.tags || []).map(escapeHtml)
  const recognitionHints = (algorithm.recognitionHints || []).map(escapeHtml)
  const whenToUse = (algorithm.whenToUse || []).map(escapeHtml)
  const commonPitfalls = (algorithm.commonPitfalls || []).map(escapeHtml)
  const relatedAlgos = (algorithm.relatedAlgos || []).map(escapeHtml)
  const resources = (algorithm.resources || []).map(r => ({
    display: escapeHtml(r),
    href: escapeUrl(r)
  }))

  return `
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>${name} - AoC Algo Buddy</title>
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
  <h1>${name}</h1>

  <div class="meta">
    <span class="badge category">${category}</span>
    <span class="badge difficulty-${escapeHtml(algorithm.difficulty?.toLowerCase())}">${difficulty}</span>
  </div>

  <div class="tags">
    ${tags.map(tag => `<span class="tag">${tag}</span>`).join('')}
  </div>

  <h2>Description</h2>
  <p>${description}</p>

  ${keyInsight ? `
  <h2>Key Insight</h2>
  <blockquote>${keyInsight}</blockquote>
  ` : ''}

  ${recognitionHints.length > 0 ? `
  <h2>How to Recognize</h2>
  <ul>
    ${recognitionHints.map(hint => `<li>${hint}</li>`).join('')}
  </ul>
  ` : ''}

  ${whenToUse.length > 0 ? `
  <h2>When to Use</h2>
  <ul>
    ${whenToUse.map(use => `<li>${use}</li>`).join('')}
  </ul>
  ` : ''}

  <h2>Pseudo Code</h2>
  <pre>${pseudoCode}</pre>

  <h2>Complexity</h2>
  <div class="complexity">
    <div class="complexity-item">
      <span class="complexity-label">Time:</span>
      <span>${timeComplexity}</span>
    </div>
    <div class="complexity-item">
      <span class="complexity-label">Space:</span>
      <span>${spaceComplexity}</span>
    </div>
  </div>

  ${commonPitfalls.length > 0 ? `
  <h2>Common Pitfalls</h2>
  <ul>
    ${commonPitfalls.map(pitfall => `<li>${pitfall}</li>`).join('')}
  </ul>
  ` : ''}

  ${relatedAlgos.length > 0 ? `
  <h2>Related Algorithms</h2>
  <ul>
    ${relatedAlgos.map(related => `<li>${related}</li>`).join('')}
  </ul>
  ` : ''}

  ${resources.length > 0 ? `
  <h2>Resources</h2>
  <ul>
    ${resources.map(r => r.href ? `<li><a href="${r.href}">${r.display}</a></li>` : `<li>${r.display}</li>`).join('')}
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
