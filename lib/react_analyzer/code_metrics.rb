module ReactAnalyzer
  module CodeMetrics
    def self.count_use_effect(file_path)
      ::File.readlines(file_path).join.scan(/\buseEffect\b/).count
    end

    def self.count_use_state(file_path)
      ::File.readlines(file_path).join.scan(/\buseState\b/).count
    end

    def self.count_imports(file_path)
      lines = ::File.readlines(file_path)
      lines.select { |line| line.strip.start_with?('import') }.size
    end

    def self.count_returns(file_path)
      ::File.readlines(file_path).join.scan(/\breturn\b/).count
    end
  end
end