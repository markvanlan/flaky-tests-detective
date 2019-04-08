# frozen_string_literal: true

class BuildOutputParser
  def clean_state
    { metadata: { runs: 0, last_commit_hash: nil }, ruby_tests: {}, js_tests: {} }
  end

  def parse_raw_from(state, raw_output_path)
    commit_hash = parse_commit_hash(raw_output_path)
    ruby_errors = parse_ruby_errors(state[:ruby_tests], raw_output_path, commit_hash)
    js_errors = parse_js_errors(state[:js_tests], raw_output_path, commit_hash)

    {
      metadata: {
        runs: (state.dig(:metadata, :runs) + 1),
        last_commit_hash: commit_hash,
        new_errors: ruby_errors[:new_errors] || js_errors[:new_errors]
      },
      ruby_tests: ruby_errors[:errors], js_tests: js_errors[:errors]
    }
  end

  private

  def parse_commit_hash(raw_output_path)
    result = File.foreach(raw_output_path).each_with_object(checked_latest: false, hash: nil) do |line, s|
      s[:checked_latest] = s[:checked_latest] || line.include?("You are in 'detached HEAD' state.")
      next(s) unless s[:checked_latest]

      commit_hash_line = line.include? 'HEAD is now at'
      if commit_hash_line
        s[:hash] = line.match(/HEAD is now at \s*(\S+)/)[1].gsub('...', '')
        break(s)
      end
    end

    result[:hash]
  end

  def parse_ruby_errors(state, raw_output_path, commit_hash)
    initial_s = {
      failure_zone: false, seed: nil, errors: state, new_errors: false,
      current_test: { failures: 1, appeared_on: commit_hash, last_seen: commit_hash }
    }

    results = File.foreach(raw_output_path).each_with_object(initial_s) do |line, s|
      stripped_line = line.strip

      break(s) if stripped_line.include? 'Finished in'

      s[:seed] = stripped_line.match(/\d+/)[0] if stripped_line.include? 'Randomized with seed'

      s[:failure_zone] = s[:failure_zone] || stripped_line.include?('Failures:')
      next(s) unless s[:failure_zone]

      s[:current_test][:assertion] = stripped_line.gsub(/\d\)/, '').strip if stripped_line.match?(/\d\)/)
      s[:current_test][:result] = stripped_line if stripped_line.include? 'expected'

      next unless stripped_line.include? './spec/'

      test_name = stripped_line.match(%r{spec/([^\s]+)})[0].gsub(':in', '')
      test_key = test_name.tr('.', '_').tr('/', '_').tr(':', '_').to_sym
      s[:current_test][:module] = test_name
      s[:new_errors] = true
      if s[:errors].key?(test_key)
        s[:errors][test_key][:failures] += 1
        s[:errors][test_key][:seed] = s[:seed]
      else
        s[:errors][test_key] = s[:current_test].merge(seed: s[:seed])
      end

      s[:current_test] = { failures: 1 }
    end

    results.slice(:new_errors, :errors)
  end

  def parse_js_errors(state, raw_output_path, commit_hash)
    initial_s = { 
      watching_test: false, current_module: nil, seed: nil, 
      current_test_key: nil, errors: state, new_errors: false
    }

    results = File.foreach(raw_output_path).each_with_object(initial_s) do |line, s|
      stripped_line = line.strip
      s[:seed] = stripped_line.match(/\d+/)[0] if stripped_line.include? 'Running: {"seed":'
      module_failed_line = stripped_line.include? 'Module Failed'
      test_line = stripped_line.include? 'Test Failed'
      s[:watching_test] = s[:watching_test] || module_failed_line || test_line
      next(s) unless s[:watching_test]

      assertion_description_line = stripped_line.include? 'Assertion Failed'
      assertion_line = stripped_line.include? 'Expected'

      s[:current_module] = stripped_line if module_failed_line

      if test_line
        s[:current_test_key] = build_test_key(stripped_line)
        s[:new_errors] = true

        if s[:errors].key?(s[:current_test_key])
          s[:errors][s[:current_test_key]][:failures] += 1
          s[:errors][s[:current_test_key]][:appeared_on] = commit_hash unless s[:errors][s[:current_test_key]][:appeared_on]
          s[:errors][s[:current_test_key]][:last_seen] = commit_hash
          s[:errors][s[:current_test_key]][:seed] = s[:seed]
        else
          s[:errors][s[:current_test_key]] = { module: s[:current_module], failures: 1, seed: s[:seed], appeared_on: commit_hash, last_seen: commit_hash }
        end
      end

      s[:errors][s[:current_test_key]][:assertion] = stripped_line if s[:current_test_key] && assertion_description_line
      s[:errors][s[:current_test_key]][:result] = stripped_line if s[:current_test_key] && assertion_line

      if assertion_line
        s[:watching_test] = false
        s[:current_module] = nil
      end
    end

    results.slice(:new_errors, :errors)
  end

  def build_test_key(raw)
    raw.delete(':').downcase.gsub(/\s+/, '_').to_sym
  end
end
