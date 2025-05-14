require 'colorize'
require 'pathname'

module ReactAnalyzer
  class Output
    def self.relative(file, base)
      Pathname.new(file).relative_path_from(Pathname.new(base)).to_s
    end

    def self.print_section(title, files, base)
      puts "\n#{title}:".colorize(:green)
      if files.empty?
        puts "  No files found.".colorize(:light_black)
      else
        files.each { |f| puts "  #{relative(f, base)}" }
      end
    end

    def self.print_similar_blocks(similar, base)
      puts "\nFiles with similar code blocks:".colorize(:green)
      if similar.empty?
        puts "  No duplicates found.".colorize(:light_black)
      else
        similar.each do |file, entries|
          puts "  #{relative(file, base)} has similar blocks with:".colorize(:blue)
          entries.each do |entry|
            puts "    #{relative(entry[:file], base)} (#{entry[:checksums].size} common blocks)"
          end
        end
      end
    end

    def self.warn_no_files_found
      puts "No JavaScript or TypeScript files found.".colorize(:yellow)
    end
  end
end
