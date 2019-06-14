require_relative '../spec_helper.rb'
require_relative '../../lib/build_output_parser.rb'

RSpec.describe BuildOutputParser do
  let(:clean_state) do
    { metadata: { runs: 0, last_commit_hash: nil }, ruby_tests: {}, js_tests: {} }
  end

  describe 'Build metadata' do
    let(:raw_output_path) { File.expand_path('../examples/succesful_run.txt', __dir__) }

    it 'Increments the amount of runs' do
      results = subject.parse_raw_from clean_state, raw_output_path

      expect(results.dig(:metadata, :runs)).to eq clean_state.dig(:metadata, :runs) + 1
      expect(results.dig(:metadata, :new_errors)).to eq false
    end

    it 'Returns the last stable commit hash' do
      expected_commit_hash = 'f072da1'

      results = subject.parse_raw_from clean_state, raw_output_path

      expect(results.dig(:metadata, :last_commit_hash)).to eq expected_commit_hash
    end
  end

  describe 'Parsing a succesful build' do
    let(:raw_output_path) { File.expand_path('../examples/succesful_run.txt', __dir__) }

    it 'Returns no errors' do
      failed_tests = subject.parse_raw_from clean_state, raw_output_path

      expect(failed_tests[:ruby_tests]).to be_empty
      expect(failed_tests[:js_tests]).to be_empty
    end
  end

  describe 'Parsing a build with JS errors' do
    let(:raw_output_path) { File.expand_path('../examples/qunit_failed_run.txt', __dir__) }
    let(:test_name) { :test_failed_user_card }

    it 'Parses and stores failed tests' do
      test_failed_assertion = 'Assertion Failed: user card is invisible by default'
      test_assertion_result = 'Expected: true, Actual: false'
      test_module = 'Module Failed: Acceptance: User Card'

      parsed_output = subject.parse_raw_from clean_state, raw_output_path
      failed_test = parsed_output.dig(:js_tests, test_name)

      expect(failed_test[:assertion]).to eq test_failed_assertion
      expect(failed_test[:result]).to eq test_assertion_result
      expect(failed_test[:module]).to eq test_module
      expect(failed_test[:failures]).to eq 1
    end

    it 'Updates initial state and returns a new state when the failures counter is incremented' do
      first_run_state = subject.parse_raw_from clean_state, raw_output_path
      second_run = subject.parse_raw_from first_run_state, raw_output_path
      failed_test = second_run.dig(:js_tests, test_name)

      expect(failed_test[:failures]).to eq 2
      expect(second_run.dig(:metadata, :new_errors)).to eq true
    end

    it 'Stores the seed' do
      expected_seed = '304691216275098133962654566400469666965'

      parsed_output = subject.parse_raw_from clean_state, raw_output_path
      failed_test = parsed_output.dig(:js_tests, test_name)

      expect(failed_test[:seed]).to eq expected_seed
    end
  end

  describe 'Parsing a build with RSpec errors' do
    let(:raw_output_path) { File.expand_path('../examples/rspec_failed_run.txt', __dir__) }
    let(:test_name) { :spec_requests_finish_installation_controller_spec_rb_13 }

    it 'Parses and stores failed tests' do
      test_failed_assertion = "FinishInstallationController#index has_login_hint is false doesn't allow access"
      test_assertion_result = 'expected `#<ActionDispatch::TestResponse:0x000055a703336698 @mon_mutex=#<Thread::Mutex:0x000055a703336620>, @mo..., @method=nil, @request_method=nil, @remote_ip=nil, @original_fullpath=nil, @fullpath=nil, @ip=nil>>.forbidden?` to return false, got true'
      test_module = 'spec/requests/finish_installation_controller_spec.rb:13'

      parsed_output = subject.parse_raw_from clean_state, raw_output_path
      failed_test = parsed_output.dig(:ruby_tests, test_name)

      expect(failed_test[:assertion]).to eq test_failed_assertion
      expect(failed_test[:result]).to eq test_assertion_result
      expect(failed_test[:module]).to eq test_module
      expect(failed_test[:failures]).to eq 1
    end

    it 'Updates initial state and returns a new state when the failures counter is incremented' do
      first_run_state = subject.parse_raw_from clean_state, raw_output_path
      second_run = subject.parse_raw_from first_run_state, raw_output_path
      failed_test = second_run.dig(:ruby_tests, test_name)

      expect(failed_test[:failures]).to eq 2
      expect(second_run.dig(:metadata, :new_errors)).to eq true
    end

    it 'Stores the seed' do
      expected_seed = '21827'

      parsed_output = subject.parse_raw_from clean_state, raw_output_path
      failed_test = parsed_output.dig(:ruby_tests, test_name)

      expect(failed_test[:seed]).to eq expected_seed
    end
  end
end
