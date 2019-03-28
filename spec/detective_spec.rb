require_relative './spec_helper.rb'
require_relative '../lib/detective.rb'
require 'tempfile'

RSpec.describe Detective do
  let(:detective) { described_class.build_detective }

  describe '#investigate' do
    let(:raw_path) { '../report.json' }

    describe 'sssss' do
      it 'xxxxxx' do
        expect { detective.investigate(nil, raw_path) }.to raise_error ArgumentError, 'Missing build to investigate'
      end

      it 'xxxxxx' do
        expect { detective.investigate(raw_path, nil) }.to raise_error ArgumentError, 'Missing output path'
      end
    end
  end
end