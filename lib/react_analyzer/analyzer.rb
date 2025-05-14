module ReactAnalyzer
  class Analyzer
    def initialize(base_path)
      @base_path = File.expand_path(base_path)
      @files = FileUtils.search_files(@base_path)
    end

    def analyze
      {
        long_files: @files.select { |f| FileUtils.line_count(f) > 150 },
        many_use_effects: @files.select { |f| CodeMetrics.count_use_effect(f) > 3 },
        many_use_states: @files.select { |f| CodeMetrics.count_use_state(f) > 4 },
        many_imports: @files.select { |f| CodeMetrics.count_imports(f) > 8 },
        many_returns: @files.select { |f| CodeMetrics.count_returns(f) > 3 },
        duplicated_blocks: CodeBlocks.find_similar(@files)
      }
    end
  end
end
