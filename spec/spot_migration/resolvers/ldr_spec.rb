RSpec.describe SpotMigration::Resolvers::Ldr do
  subject do
    described_class.new(db_adapter: db_adapter,
                        asset_store_base: asset_base).call(id)
  end

  before do
    allow(db_adapter).to receive(:exec).with(ldr_query, [id])
                                       .and_return(raw_results)
    allow(File).to receive(:open).with(fake_path, 'r').and_return(io_double)
  end

  let(:id) { 'abc123' }
  let(:db_adapter) { double('postgres adapter') }
  let(:io_double) { double('file io') }
  let(:ldr_query) do
    described_class.new(db_adapter: nil, asset_store_base: nil)
                   .send(:bitstream_query)
  end
  let(:raw_results) do
    [
      { 'name' => 'file.pdf', 'internal_id' => '0123456', 'bitstream_description' => nil },
      { 'name' => 'file.pdf.txt', 'internal_id' => '0123457', 'bitstream_description' => 'Extracted text' }
    ]
  end
  let(:asset_base) { '/path/to/assetstore' }
  let(:fake_path) { File.join(asset_base, '01', '23', '45', '0123456') }
  let(:expected_bitstream) do
    SpotMigration::Resolvers::Bitstream.new('file.pdf', io_double)
  end

  it { is_expected.to eq [expected_bitstream] }
end
