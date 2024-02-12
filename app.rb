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

def add_to_history(path, history)
  history << { path: path, timestamp: Time.now.strftime('%Y-%m-%d %H:%M:%S') }
end

def search_files(directory)
  Dir.glob(File.join(directory, '**', '*.{js,ts,jsx,tsx}')).reject do |file|
    File.directory?(file) || file.include?('node_modules') || file.include?('public') || file.include?('out')
  end
end

def count_use_effect(file_path)
  File.readlines(file_path).join.scan(/\buseEffect\b/).count
end

def count_use_state(file_path)
  File.readlines(file_path).join.scan(/\buseState\b/).count
end

def count_imports(file_path)
  lines = File.readlines(file_path)
  import_lines = lines.select { |line| line.strip.start_with?('import') }
  import_lines.size
end

def count_returns(file_path)
  File.readlines(file_path).join.scan(/\breturn\b/).count
end

def files_more_than_150_lines(files)
  files.select { |file| File.foreach(file).count > 150 }
end

def files_more_than_3_use_effects(files)
  files.select { |file| count_use_effect(file) > 3 }
end

def files_more_than_4_use_states(files)
  files.select { |file| count_use_state(file) > 4 }
end

def files_more_than_8_imports(files)
  files.select { |file| count_imports(file) > 8 }
end

def files_more_than_3_returns(files)
  files.select { |file| (file.end_with?('.jsx') || file.end_with?('.tsx')) && count_returns(file) > 3 }
end

def count_duplicate_lines(file_path)
  lines = File.readlines(file_path)
  lines.group_by(&:itself).select { |_, duplicates| duplicates.count > 1 }.map(&:last).flatten.size
end

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

def generate_checksums(code_blocks)
  checksums = []
  code_blocks.each do |block|
    checksums << Digest::MD5.hexdigest(block)
  end
  checksums
end

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

def relative_path(file_path, base_path)
  relative_path = file_path.sub("#{base_path}/", '')
  relative_path.sub!(/^\.\.\/+/, '') # Remove any leading "../" sequences
  base_directory = base_path.split(File::SEPARATOR)[-1]
  relative_path.sub("#{base_directory}/", '')
end

path = ARGV[0]

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

if path.empty?
  puts "Error: Path cannot be empty.".colorize(:red)
  exit 1
end

puts "Path: #{path}".colorize(:blue)

package_json_path = File.join(path, 'package.json')
unless File.exist?(package_json_path)
  puts "Error: '#{package_json_path}' not found. This path doesn't contain a valid React.js/Next.js project.".colorize(:red)
  exit 1
end

package_json_content = File.read(package_json_path)
unless package_json_content.include?('react') || package_json_content.include?('next')
  puts "Error: '#{package_json_path}' doesn't contain a valid React.js/Next.js project.".colorize(:red)
  exit 1
end

files = search_files(path)

if files.empty?
  puts "No JavaScript or TypeScript files found  .".colorize(:yellow)
else
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

history = load_history
add_to_history(path, history)
save_history(history)
