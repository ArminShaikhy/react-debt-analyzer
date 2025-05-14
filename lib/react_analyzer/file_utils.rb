module ReactAnalyzer
  module FileUtils
    def self.search_files(directory)
      Dir.glob(File.join(directory, '**', '*.{js,ts,jsx,tsx}')).reject do |file|
        File.directory?(file) || file.include?('node_modules') ||
          file.include?('public') || file.include?('out') || file.include?('dist')
      end
    end

    def self.line_count(file)
      ::File.foreach(file).count
    end
  end
end
