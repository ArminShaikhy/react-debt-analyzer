# lib/react_analyzer/history.rb

module ReactAnalyzer
  module History
    # Load history from file
    def self.load
      if File.exist?('history.json')
        JSON.parse(File.read('history.json'))
      else
        []
      end
    end

    # Save history to file
    def self.save(history)
      File.write('history.json', JSON.pretty_generate(history))
    end

    # Add new entry to history
    def self.add(path, history)
      history << { path: path, timestamp: Time.now.strftime('%Y-%m-%d %H:%M:%S') }
    end
  end
end
