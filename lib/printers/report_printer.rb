# frozen_string_literal: true

require 'date'

class ReportPrinter
  def print_from(report)
    <<~eos
    ## Flakey tests report - #{Date.today.strftime('%m/%d/%Y')}

    >Total runs: #{report.dig(:metadata, :runs)}
    >Last commit: #{report.dig(:metadata, :last_commit_hash)}

    ### New findings:

    ### Ruby
    
    #{build_ruby_failures(report[:ruby_tests])}

    ### JS

    #{build_js_failures(report[:js_tests])}
    
    eos
  end

  private

  def build_ruby_failures(ruby_json)
    index = 0
    ordered_tests = ruby_json.values.sort_by { |r| -r[:failures] } 
    
    ordered_tests.reduce('') do |memo, test|
      index += 1
      memo += <<~eos
      #{index}. #{test[:module]}
        - Failures: #{test[:failures]}
        #{details(test)}

      eos
    end
  end

  def build_js_failures(js_json)
    index = 0
    with_test_data = js_json 
    with_test_data.each { |t, r| r[:test] = t }
    ordered_tests = with_test_data.values.sort_by { |r| -r[:failures] }

    ordered_tests.reduce('') do |memo, test|
      index += 1
      memo += <<~eos
      #{index}. #{test[:test].to_s.gsub('_', ' ')}
        - Failures: #{test[:failures]}
        - #{test[:module]}
        #{details(test)}

      eos
    end
  end

  def details(test)
    <<~eos
    - <details>
          <summary>Show details</summary>

          - **Seed:** #{test[:seed]}
          - **First seen:** #{test[:appeared_on]}
          - **Last seen:** #{test[:last_seen]}
          - **Assertion:** #{test[:assertion]}
          - **Result:** ```#{test[:result]}```
        </details>
    eos
  end
end
