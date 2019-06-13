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
    ruby_json.reduce('') do |memo, (_,v)|
      index += 1
      memo += <<~eos
      #{index}. #{v[:module]}
        - Failures: #{v[:failures]}
        #{details(v)}

      eos
    end
  end

  def build_js_failures(js_json)
    index = 0
    js_json.reduce('') do |memo, (k,v)|
      index += 1
      memo += <<~eos
      #{index}. #{k.to_s.gsub('_', ' ')}
        - Failures: #{v[:failures]}
        - #{v[:module]}
        #{details(v)}

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
