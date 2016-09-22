module Saxinator
  class Utils
    # Matches a single string against a sequence of patterns and returns an array of corresponding MatchData objects,
    # one for each regular expression. Alternatives that fail:
    #
    # 1. Create a combined pattern and use the resulting MatchData object. Fails because it is unclear which sub-group
    #    in the resulting MatchData object corresponds to a given original pattern.
    #
    # 2. Match against each pattern in turn, and return the resulting MatchData objects in an array. Fails because a
    #    regular expression may consume too much input, causing the next pattern to fail, even though the combined
    #    pattern would have succeeded. For example, 'I am tall' would fail for the regular expressions /[\w\s]*/ and
    #    /tall/, even though the combined regular expression /[\w\s]*tall/ would have succeeded.
    #
    def self.multimatch(s, patterns)
      return nil if patterns.empty?

      matches = delimited_match(s, patterns)

      matches ? [matches] : nil
      #matches_lists = patterns.map { |pattern| s.match(pattern) }
    end

    # TODO: ...
    # returns MatchData with named matches with delimiters of the form __0, __1, etc... indicating the divides between
    # the results for the individual patterns
    def self.delimited_match(s, patterns)
      combined_pattern = get_combined_pattern(patterns)
      s.match(/^\s*#{combined_pattern}\s*$/)
    end

    def self.get_combined_pattern(patterns)
      wrap_major_groups(rename_all_groups(patterns)).join
    end

    def self.rename_all_groups(patterns)
      patterns.each_with_index.map { |pattern, i| rename_groups(pattern, i) }
    end

    # TODO
    def self.rename_groups(pattern, i)
      # TODO: make sure regex really catches all scenarios ...
      # TODO: verify name of group contains only valid characters ...
      regex_name        = /<([^>]*)>:?/
      regex_modifiers   = /\?(!)?/
      regex_start_group = /\((?:#{regex_modifiers}#{regex_name}|(?!\?))/

      j = 0
      pattern.to_s.gsub(regex_start_group) do
        m    = Regexp.last_match
        name = m[2] ? m[2] : "_#{j}"
        r    = "(?#{m[1]}<_#{i}-#{name}>"

        j    = j + 1 unless m[2]

        r
      end
    end

    def self.wrap_major_groups(patterns)
      patterns.each_with_index.map { |pattern, i| /(?<__#{i}>#{pattern})/ }
    end

    # def self.extract_results(matches)
    #
    # end
  end
end