Here's a complete `README.md` for your **React Debt Analyzer** project:

---

## 📊 React Debt Analyzer

A command-line Ruby tool to analyze React and Next.js projects for common code quality issues and anti-patterns — such as bloated components, excessive hooks, repeated logic, and more.

---

### 🚀 Features

- 🔍 Scans JavaScript and TypeScript files (`.js`, `.jsx`, `.ts`, `.tsx`)
- ✅ Checks for:
  - Large files (over configurable line count)
  - Overuse of `useEffect` and `useState`
  - Too many `return` statements (in JSX components)
  - Excessive import statements
  - Duplicate code blocks across files
- 🧠 Detects React or Next.js projects by inspecting `package.json`
- 💾 Remembers previously scanned paths
- 🔧 Customizable via `.reactanalyzerrc.json`

---

### 📦 Installation

```bash
git clone https://github.com/your-username/react-debt-analyzer.git
cd react-debt-analyzer
bundle install
```

---

### 🛠 Usage

```bash
bin/react_analyzer /path/to/react-project
```

Or run without arguments to select from history or enter a new path interactively:

```bash
bin/react_analyzer
```

---

### ⚙️ Configuration

You can customize thresholds by creating a `.reactanalyzerrc.json` file in the root of your React project:

```bash
bin/react_analyzer --init-config
```

This generates:

```json
{
  "max_use_effect": 3,
  "max_use_state": 4,
  "max_lines": 150,
  "max_imports": 8,
  "max_returns": 3,
  "min_duplicate_blocks": 5
}
```

Adjust these values to suit your team's preferences.

---

### 📁 Output Example

```
Files with more than 150 lines:
  src/components/HugeComponent.jsx
  src/pages/Dashboard.tsx

Files with more than 3 useEffect hooks:
  src/hooks/useAnalytics.ts

Files with similar code blocks:
  src/utils/helpers.ts shares logic with src/services/data.ts (6 common blocks)
```

---

### 📌 Project Structure

```
bin/
  react_analyzer        # CLI entry point

lib/react_analyzer/
  analyzer.rb           # Main orchestrator
  file_scanner.rb       # File discovery
  code_metrics.rb       # Hook/import/line/return counters
  duplicate_detector.rb # Detects duplicate code blocks
  output.rb             # Nicely formatted CLI output

history.json            # Stores recently analyzed paths (auto-generated)
```

---

### 🧠 Roadmap Ideas

- Detect deeply nested JSX trees
- Highlight files that contain multiple components
- CLI flags to enable/disable specific checks
- Export reports as JSON or markdown
