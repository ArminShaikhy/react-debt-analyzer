module ReactAnalyzer
  class CodeMetrics
    def self.line_count(file)
      File.foreach(file).count
    end

    def self.use_effect_count(file)
      File.read(file).scan(/\buseEffect\b/).size
    end

    def self.use_state_count(file)
      File.read(file).scan(/\buseState\b/).size
    end

    def self.import_count(file)
      File.readlines(file).count { |line| line.strip.start_with?('import') }
    end

    def self.return_count(file)
      File.read(file).scan(/\breturn\b/).size
    end
  end
end
