RSpec.describe SpotMigration::BagFactory do
  describe '#run' do
    before { factory.run(destination: destination) }
    after { FileUtils.remove_entry(tmpdir) }

    let(:tmpdir) { Dir.mktmpdir }
    let(:csv_path) { fixture_path('basic.csv') }
    let(:parsed_csv) { CSV.parse(File.read(csv_path), headers: true) }
    let(:destination) { tmpdir }
    let(:resolver) do
      ->(_id, csv_row) { csv_row['files'].map { |f| fixture_path(f) } }
    end

    let(:factory) do
      described_class.new(
        csv_path: csv_path,
        file_resolver: resolver
      )
    end

    it 'creates a bag for each row of the csv' do
      dest_entries = Dir.entries(destination) - %w[. ..]
      ids = parsed_csv.map { |r| r['id'] }
      expect(dest_entries).to eq ids
    end
  end
end
