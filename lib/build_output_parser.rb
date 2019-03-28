# frozen_string_literal: true

class BuildOutputParser
  def clean_state
    { metadata: { runs: 0, last_commit_hash: nil }, ruby_tests: {}, js_tests: {} }
  end

  def parse_raw_from(state, raw_output_path)
    { 
      metadata: { 
        runs: (state.dig(:metadata, :runs) + 1),
        last_commit_hash: parse_commit_hash(raw_output_path)
      },
      ruby_tests: parse_ruby_errors(state[:ruby_tests], raw_output_path), 
      js_tests: parse_js_errors(state[:js_tests], raw_output_path) 
    }
  end

  private

  def parse_commit_hash(raw_output_path)
    result = File.foreach(raw_output_path).reduce({ checked_latest: false, hash: nil }) do |s, line|
      s[:checked_latest] = s[:checked_latest] || line.include?("You are in 'detached HEAD' state.")
      next(s) unless s[:checked_latest]

      commit_hash_line = line.include? 'HEAD is now at'
      if commit_hash_line
        s[:hash] = line.match(/HEAD is now at \s*(\S+)/)[1].gsub('...', '')
        break(s)
      end

      s
    end

    result[:hash]
  end

  def parse_ruby_errors(state, raw_output_path)
    initial_s = { failure_zone: false, current_test: { failures: 1 }, errors: state }

    results = File.foreach(raw_output_path).reduce(initial_s) do |s, line|
      stripped_line = line.strip

      break(s) if stripped_line.include? 'Finished in'

      s[:failure_zone] = s[:failure_zone] || stripped_line.include?('Failures:')
      next(s) unless s[:failure_zone]

      s[:current_test].merge!(assertion: stripped_line.gsub(/\d\)/, '').strip) if stripped_line.match?(/\d\)/)
      s[:current_test].merge!(result: stripped_line) if stripped_line.include? 'expected'

      if stripped_line.include? './spec/'
        test_name = stripped_line.match(/spec\/([^\s]+)/)[0].gsub(':in', '')
        test_key = test_name.gsub('.', '_').gsub('/', '_').gsub(':', '_').to_sym
        s[:current_test][:module] = test_name
        if s[:errors].has_key?(test_key)
          s[:errors][test_key][:failures] += 1
        else
          s[:errors][test_key] = s[:current_test]
        end
        
        s[:current_test] = { failures: 1 }
      end

      s
    end

    results[:errors]
  end

  def parse_js_errors(state, raw_output_path)
    initial_s = { watching_test: false, current_module: nil, current_test_key: nil, errors: state }

    results = File.foreach(raw_output_path).reduce(initial_s) do |s, line|
      stripped_line = line.strip
      module_failed_line = stripped_line.include? 'Module Failed'
      test_line = stripped_line.include? 'Test Failed'
      s[:watching_test] = s[:watching_test] || module_failed_line || test_line
      next(s) unless s[:watching_test]

      assertion_description_line = stripped_line.include? 'Assertion Failed'
      assertion_line = stripped_line.include? 'Expected'
      
      s[:current_module] = stripped_line if module_failed_line

      if test_line
        s[:current_test_key] = build_test_key(stripped_line)
        
        if s[:errors].has_key?(s[:current_test_key])
          s[:errors][s[:current_test_key]][:failures] += 1
        else
          s[:errors][s[:current_test_key]] = { module: s[:current_module], failures: 1 } 
        end
      end

      s[:errors][s[:current_test_key]][:assertion] = stripped_line if s[:current_test_key] && assertion_description_line
      s[:errors][s[:current_test_key]][:result] = stripped_line if s[:current_test_key] && assertion_line

      if assertion_line
        s[:watching_test] = false 
        s[:current_module] = nil
      end

      s
    end

    results[:errors]
  end

  def build_test_key(raw)
    raw.gsub(':','').downcase.gsub(/\s+/, '_').to_sym
  end
end
