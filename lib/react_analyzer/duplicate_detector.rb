require 'digest'

module ReactAnalyzer
  class DuplicateDetector
    def self.extract_code_blocks(file)
      blocks = []
      in_block = false
      current = ""

      File.foreach(file) do |line|
        next if line.strip.start_with?("/*", "//") || line.strip.empty?

        if line.include?("function") || line.include?("class") || line.include?("{")
          in_block = true
        end

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
      blocks.map { |b| Digest::MD5.hexdigest(b) }
    end

    def self.find_similar_code_blocks(files, min_common = 5)
      checksums_by_file = {}

      files.each do |file|
        blocks = extract_code_blocks(file)
        checksums_by_file[file] = generate_checksums(blocks)
      end

      result = {}
      files.combination(2) do |file1, file2|
        common = checksums_by_file[file1] & checksums_by_file[file2]
        if common.size >= min_common
          result[file1] ||= []
          result[file1] << { file: file2, checksums: common }
        end
      end

      result
    end
  end
end
