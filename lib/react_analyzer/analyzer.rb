require_relative 'file_scanner'
require_relative 'code_metrics'
require_relative 'duplicate_detector'
require_relative 'output'

module ReactAnalyzer
  class Analyzer
    def self.run(path, config = {})
      thresholds = {
        max_use_effect: config[:max_use_effect] || 3,
        max_use_state: config[:max_use_state] || 4,
        max_lines: config[:max_lines] || 150,
        max_imports: config[:max_imports] || 8,
        max_returns: config[:max_returns] || 3,
        min_duplicate_blocks: config[:min_duplicate_blocks] || 5
      }

      files = FileScanner.search_files(path)

      Output.warn_no_files_found if files.empty?

      # Filtered files by bad practices
      long_files        = files.select { |f| CodeMetrics.line_count(f) > thresholds[:max_lines] }
      heavy_effects     = files.select { |f| CodeMetrics.use_effect_count(f) > thresholds[:max_use_effect] }
      heavy_states      = files.select { |f| CodeMetrics.use_state_count(f) > thresholds[:max_use_state] }
      import_bloat      = files.select { |f| CodeMetrics.import_count(f) > thresholds[:max_imports] }
      return_heavy      = files.select do |f|
        %w[.jsx .tsx].any? { |ext| f.end_with?(ext) } &&
        CodeMetrics.return_count(f) > thresholds[:max_returns]
      end

      # Output
      Output.print_section("Files with more than #{thresholds[:max_lines]} lines", long_files, path)
      Output.print_section("Files with more than #{thresholds[:max_use_effect]} useEffect hooks", heavy_effects, path)
      Output.print_section("Files with more than #{thresholds[:max_use_state]} useState hooks", heavy_states, path)
      Output.print_section("Files with more than #{thresholds[:max_imports]} imports", import_bloat, path)
      Output.print_section("Files with more than #{thresholds[:max_returns]} return statements", return_heavy, path)

      # Duplicates
      similar = DuplicateDetector.find_similar_code_blocks(files, thresholds[:min_duplicate_blocks])
      Output.print_similar_blocks(similar, path)
    end
  end
end
