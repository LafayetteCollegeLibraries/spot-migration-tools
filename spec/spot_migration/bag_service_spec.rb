require 'tmpdir'

RSpec.describe SpotMigration::BagService do
  subject(:service) do
    described_class.new(id: id, metadata: metadata, files: files)
  end

  let(:id) { 'abc123' }
  let(:metadata) do
    { 'title' => 'An obscure title', 'subject' => %w[Art Painting] }
  end
  let(:files) { [fixture_path('image.png')] }

  describe '#create!' do
    # we're going to do this all in one-fell-swoop so
    # we don't have to create a new bag for each test
    Dir.mktmpdir('spot-migration-bag-service') do |tmpdir|
      before do
        service.create!(destination: tmpdir)
      end

      it 'writes a bag to the directory' do
        bag_directory = File.join(tmpdir, id)
        expect(File.directory?(bag_directory)).to be true

        data_directory = File.join(bag_directory, 'data')
        expect(File.directory?(data_directory)).to be true

        files_directory = File.join(data_directory, 'files')
        expect(File.directory?(files_directory)).to be true

        expect(Dir.entries(files_directory) - %w[. ..]).to eq ['image.png']

        expect(BagIt::Bag.new(bag_directory).valid?).to be true
      end
    end
  end
end
