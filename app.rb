#!/usr/bin/env ruby

require 'json'
require 'colorize'
require 'digest'

HISTORY_FILE = 'history.json'

# Function to load history from a file
def load_history
  if File.exist?(HISTORY_FILE)
    history = JSON.parse(File.read(HISTORY_FILE))
    # Extract unique paths
    unique_paths = history.map { |entry| entry['path'].split(File::SEPARATOR)[-1] }.uniq
    unique_paths.map { |path| history.find { |entry| entry['path'].split(File::SEPARATOR)[-1] == path } }
  else
    []
  end
end

# Function to save history to a file
def save_history(history)
  File.write(HISTORY_FILE, JSON.pretty_generate(history))
end

# Function to add a path to the history
def add_to_history(path, history)
  history << { path: path, timestamp: Time.now.strftime('%Y-%m-%d %H:%M:%S') }
end

# Function to recursively search for JavaScript and TypeScript files in a directory, excluding the node_modules and public directories
def search_files(directory)
  Dir.glob(File.join(directory, '**', '*.{js,ts,jsx,tsx}')).reject do |file|
    File.directory?(file) || file.include?('node_modules') || file.include?('public') || file.include?('out')
  end
end

# Function to count the occurrences of 'useEffect' in a file
def count_use_effect(file_path)
  File.readlines(file_path).join.scan(/\buseEffect\b/).count
end

# Function to count the occurrences of 'useState' in a file
def count_use_state(file_path)
  File.readlines(file_path).join.scan(/\buseState\b/).count
end

# Function to count the occurrences of 'import' in a file and return the number of imports
def count_imports(file_path)
  lines = File.readlines(file_path)
  import_lines = lines.select { |line| line.strip.start_with?('import') }
  import_lines.size
end

# Function to count the occurrences of 'return' in a file and return the number of returns
def count_returns(file_path)
  File.readlines(file_path).join.scan(/\breturn\b/).count
end

# Function to display files with more than 150 lines
def files_more_than_150_lines(files)
  files.select { |file| File.foreach(file).count > 150 }
end

# Function to display files with more than 3 occurrences of 'useEffect'
def files_more_than_3_use_effects(files)
  files.select { |file| count_use_effect(file) > 3 }
end

# Function to display files with more than 4 occurrences of 'useState'
def files_more_than_4_use_states(files)
  files.select { |file| count_use_state(file) > 4 }
end

# Function to display files with more than 8 occurrences of 'import'
def files_more_than_8_imports(files)
  files.select { |file| count_imports(file) > 8 }
end

def files_more_than_3_returns(files)
  files.select { |file| (file.end_with?('.jsx') || file.end_with?('.tsx')) && count_returns(file) > 3 }
end

# Function to count the occurrences of duplicate lines in a file
def count_duplicate_lines(file_path)
  lines = File.readlines(file_path)
  lines.group_by(&:itself).select { |_, duplicates| duplicates.count > 1 }.map(&:last).flatten.size
end

# Function to extract code blocks from a file
def extract_code_blocks(file_path)
  code_blocks = []
  in_block = false
  current_block = ""

  File.foreach(file_path) do |line|
    if line.strip.start_with?("/*") || line.strip.start_with?("//") || line.strip.empty?
      next
    end

    if line.include?("function") || line.include?("class") || line.include?("{")
      in_block = true
    end

    if in_block
      current_block += line
    end

    if line.strip.end_with?("}") && in_block
      code_blocks << current_block.strip
      current_block = ""
      in_block = false
    end
  end

  code_blocks
end

# Function to generate checksums for code blocks
def generate_checksums(code_blocks)
  checksums = []
  code_blocks.each do |block|
    checksums << Digest::MD5.hexdigest(block)
  end
  checksums
end

# Function to find similar code blocks
def find_similar_code_blocks(files)
  code_blocks_by_file = {}
  files.each do |file|
    code_blocks = extract_code_blocks(file)
    checksums = generate_checksums(code_blocks)
    code_blocks_by_file[file] = checksums
  end

  similar_blocks = {}
  code_blocks_by_file.each do |file, checksums|
    code_blocks_by_file.each do |other_file, other_checksums|
      next if file == other_file

      common_checksums = checksums & other_checksums
      if common_checksums.any?
        similar_blocks[file] ||= []
        similar_blocks[file] << { file: other_file, checksums: common_checksums }
      end
    end
  end

  similar_blocks.reject! { |_, similar_files| similar_files.any? { |similar_file| similar_file[:checksums].size < 5 } }

  similar_blocks
end

# Function to get the relative path of a file
def relative_path(file_path, base_path)
  relative_path = file_path.sub("#{base_path}/", '')
  relative_path.sub!(/^\.\.\/+/, '') # Remove any leading "../" sequences
  base_directory = base_path.split(File::SEPARATOR)[-1]
  relative_path.sub("#{base_directory}/", '')
end

# Check if a path argument is provided
path = ARGV[0]

# If no path argument is provided, prompt the user to choose a path from history or enter a new path
if path.nil? || path.empty?
  history = load_history
  if history.empty?
    print "Enter a path: "
    path = $stdin.gets.chomp
  else
    puts "Choose a path from history:".colorize(:green)
    history.each_with_index { |entry, index| puts "#{index + 1}. #{entry['path'].split(File::SEPARATOR)[-1]} (#{entry['timestamp']})" }
    print "Enter the number of the path or press Enter to enter a new path: "
    choice = $stdin.gets.chomp
    if choice.empty? || choice.to_i < 1 || choice.to_i > history.size
      print "Enter a new path: "
      path = $stdin.gets.chomp
    else
      path = history[choice.to_i - 1]['path']
    end
  end
end

# Exit with an error message if the provided path is empty
if path.empty?
  puts "Error: Path cannot be empty.".colorize(:red)
  exit 1
end

# Print the provided path
puts "Path: #{path}".colorize(:blue)

# Check if package.json exists in the provided path
package_json_path = File.join(path, 'package.json')
unless File.exist?(package_json_path)
  puts "Error: '#{package_json_path}' not found. This path doesn't contain a valid React.js/Next.js project.".colorize(:red)
  exit 1
end

# Read the contents of package.json to check for React.js/Next.js project
package_json_content = File.read(package_json_path)
unless package_json_content.include?('react') || package_json_content.include?('next')
  puts "Error: '#{package_json_path}' doesn't contain a valid React.js/Next.js project.".colorize(:red)
  exit 1
end

# Search for JavaScript and TypeScript files in all directories within the provided path, excluding node_modules and public
files = search_files(path)

# Print the found files
if files.empty?
  puts "No JavaScript or TypeScript files found  .".colorize(:yellow)
else
  # Separate files with more than 150 lines, more than 3 occurrences of useEffect, more than 4 occurrences of useState, more than 8 occurrences of import, more than 3 occurrences of return, and similar code blocks
  files_with_more_than_150_lines = files_more_than_150_lines(files)
  files_with_more_than_3_use_effects = files_more_than_3_use_effects(files)
  files_with_more_than_4_use_states = files_more_than_4_use_states(files)
  files_with_more_than_8_imports = files_more_than_8_imports(files)
  files_with_more_than_3_returns = files_more_than_3_returns(files)

  puts "\nFiles with more than 150 lines of code  :".colorize(:green)
  if files_with_more_than_150_lines.empty?
    puts "No files found."
  else
    base_path = File.expand_path(path)
    files_with_more_than_150_lines.each { |file| puts relative_path(file, base_path) }
  end

  puts "\nFiles with more than 3 occurrences of 'useEffect'  :".colorize(:green)
  if files_with_more_than_3_use_effects.empty?
    puts "No files found."
  else
    base_path = File.expand_path(path)
    files_with_more_than_3_use_effects.each { |file| puts relative_path(file, base_path) }
  end

  puts "\nFiles with more than 4 occurrences of 'useState'  :".colorize(:green)
  if files_with_more_than_4_use_states.empty?
    puts "No files found."
  else
    base_path = File.expand_path(path)
    files_with_more_than_4_use_states.each { |file| puts relative_path(file, base_path) }
  end

  puts "\nFiles with more than 8 occurrences of 'import'  :".colorize(:green)
  if files_with_more_than_8_imports.empty?
    puts "No files found."
  else
    base_path = File.expand_path(path)
    files_with_more_than_8_imports.each do |file|
      num_imports = count_imports(file)
      puts "#{relative_path(file, base_path)} (#{num_imports} imports)"
    end
  end

  puts "\nFiles with more than 3 occurrences of 'return'  :".colorize(:green)
  if files_with_more_than_3_returns.empty?
    puts "No files found."
  else
    base_path = File.expand_path(path)
    files_with_more_than_3_returns.each do |file|
      num_returns = count_returns(file)
      puts "#{relative_path(file, base_path)} (#{num_returns} returns)"
    end
  end

  puts "\nFiles with similar code blocks:".colorize(:green)
  similar_blocks = find_similar_code_blocks(files)
  similar_blocks.each do |file, similar_files|
    puts "#{relative_path(file, base_path)} has similar code blocks with:".colorize(:light_blue)
    similar_files.each do |similar_file|
      puts "  #{relative_path(similar_file[:file], base_path)} - #{similar_file[:checksums].size} duplicate lines"
    end
  end
end

# Load history, add current path, and save it
history = load_history
add_to_history(path, history)
save_history(history)
