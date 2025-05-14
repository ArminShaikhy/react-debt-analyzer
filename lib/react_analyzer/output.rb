require 'colorize'

module ReactAnalyzer
  module Output
    def self.print_results(results, base_path)
      puts "\nFiles with more than 150 lines:".colorize(:green)
      print_list(results[:long_files], base_path)

      puts "\nFiles with > 3 'useEffect':".colorize(:green)
      print_list(results[:many_use_effects], base_path)

      puts "\nFiles with > 4 'useState':".colorize(:green)
      print_list(results[:many_use_states], base_path)

      puts "\nFiles with > 8 imports:".colorize(:green)
      results[:many_imports].each do |file|
        count = CodeMetrics.count_imports(file)
        puts "#{relative(file, base_path)} (#{count} imports)"
      end

      puts "\nFiles with > 3 returns:".colorize(:green)
      results[:many_returns].each do |file|
        count = CodeMetrics.count_returns(file)
        puts "#{relative(file, base_path)} (#{count} returns)"
      end

      puts "\nFiles with similar code blocks:".colorize(:green)
      results[:duplicated_blocks].each do |file, similarities|
        puts "#{relative(file, base_path)} has similarities with:"
        similarities.each do |entry|
          puts "  #{relative(entry[:file], base_path)} - #{entry[:shared]} shared blocks"
        end
      end
    end

    def self.print_list(files, base_path)
      if files.empty?
        puts "No files found."
      else
        files.each { |f| puts relative(f, base_path) }
      end
    end

    def self.relative(file, base)
      file.sub(/^#{base}\//, '')
    end
  end
end