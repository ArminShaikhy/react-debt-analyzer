require 'digest'

module ReactAnalyzer
  module CodeBlocks
    def self.extract(file)
      blocks = []
      current = ""
      in_block = false

      ::File.foreach(file) do |line|
        next if line.strip.start_with?("//", "/*") || line.strip.empty?

        in_block = true if line.include?("function") || line.include?("class") || line.include?("{")
        current += line if in_block
        if line.strip.end_with?("}") && in_block
          blocks << current.strip
          current = ""
          in_block = false
        end
      end

      blocks
    end

    def self.generate_checksums(blocks)
      blocks.map { |block| Digest::MD5.hexdigest(block) }
    end

    def self.find_similar(files)
      checksums_by_file = files.to_h { |f| [f, generate_checksums(extract(f))] }

      similar = {}
      checksums_by_file.each do |file, checksums|
        checksums_by_file.each do |other_file, other_checksums|
          next if file == other_file
          common = checksums & other_checksums
          next if common.size < 5
          similar[file] ||= []
          similar[file] << { file: other_file, shared: common.size }
        end
      end

      similar
    end
  end
end
