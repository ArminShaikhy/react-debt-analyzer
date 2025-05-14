require 'json'

module ReactAnalyzer
  module History
    HISTORY_FILE = 'history.json'

    def self.load
      return [] unless ::File.exist?(HISTORY_FILE)
      JSON.parse(::File.read(HISTORY_FILE))
    end

    def self.save_path(path)
      history = load
      history << { path: path, timestamp: Time.now.strftime('%Y-%m-%d %H:%M:%S') }
      ::File.write(HISTORY_FILE, JSON.pretty_generate(history.uniq { |h| h['path'] }))
    end

    def self.prompt_for_path
      history = load
      return ask_new_path if history.empty?

      puts "Choose a path from history:".colorize(:green)
      history.each_with_index do |entry, index|
        puts "#{index + 1}. #{entry['path']} (#{entry['timestamp']})"
      end
      print "Enter number or press Enter to input new path: "
      choice = $stdin.gets.chomp
      return ask_new_path if choice.empty?

      selected = history[choice.to_i - 1]
      selected ? selected['path'] : ask_new_path
    end

    def self.ask_new_path
      print "Enter a new path: "
      $stdin.gets.chomp
    end
  end
end