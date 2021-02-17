# code is obtained from https://github.com/thumblemonks/cpio/blob/bad40c293280bb3c1678251c66f0f1f6fb1cc03e/cpio.rb
# rubocop:disable all

require 'stringio'

module CPIO
  class ArchiveFormatError < IOError; end

  class ArchiveHeader
    Magic = '070707'
    Fields = [[6,  :magic   ],
              [6,  :dev     ],
              [6,  :inode   ],
              [6,  :mode    ],
              [6,  :uid     ],
              [6,  :gid     ],
              [6,  :numlinks],
              [6,  :rdev    ],
              [11, :mtime   ],
              [6,  :namesize],
              [11, :filesize]]

    FieldDefaults = {:magic    => Integer(Magic),
                     :dev      => 0777777,
                     :inode    => 0,
                     :mode     => 0100444,
                     :uid      => 0,
                     :gid      => 0,
                     :numlinks => 1,
                     :rdev     => 0,
                     :mtime    => lambda { Time.now.to_i }}

    FieldMaxValues = Fields.inject({}) do |map,(width,name)|
      map[name] = Integer("0#{'7' * width}")
      map
    end

    HeaderSize = Fields.inject(0) do |sum,(size,name)|
      sum + size
    end

    HeaderUnpackFormat = Fields.collect do |size,name|
      "a%s" % size
    end.join('')

    Fields.each do |(size,name)|
      define_method(name) { @attrs[name.to_sym] }
    end

    class << self
      private :new
    end

    def initialize(attrs)
      @attrs = attrs
      check_attrs
    end

    def self.from(io)
      data = io.read(HeaderSize)
      verify_size(data)
      verify_magic(data)
      new(unpack_data(data))
    end

    def self.with_defaults(opts)
      name = opts[:name]
      defaults = FieldDefaults.merge(:mode => opts[:mode], :filesize => opts[:filesize], :namesize => name.size + 1)
      new(defaults)
    end

    def to_data
      Fields.collect do |(width,name)|
        raise ArchiveFormatError, "Expected header to have key #{name}" unless @attrs.has_key?(name)
        val = @attrs[name].respond_to?(:to_proc) ? @attrs[name].call : @attrs[name]
        raise ArchiveFormatError, "Header value for #{name} exceeds max length of #{FieldMaxValues[name]}" if val > FieldMaxValues[name]
        sprintf("%0*o", Fields.rassoc(name).first, val)
      end.join('')
    end

  private

    def check_attrs
      [:mode, :namesize, :filesize].each do |attr|
        raise ArgumentError, "#{attr.inspect} must be given" if !@attrs.has_key?(attr)
      end
    end

    def self.verify_size(data)
      unless data.size == HeaderSize
        raise ArchiveFormatError, "Header is not long enough to be a valid CPIO archive with ASCII headers."
      end
    end

    def self.verify_magic(data)
      unless data[0..Magic.size - 1] == Magic
        raise ArchiveFormatError, "Archive does not seem to be a valid CPIO archive with ASCII headers."
      end
    end

    def self.unpack_data(data)
      contents = {}
      data.unpack(HeaderUnpackFormat).zip(Fields) do |(chunk,(size,name))|
        contents[name] = Integer("0#{chunk}")
      end
      contents
    end

  end

  class ArchiveEntry
    TrailerMagic = "TRAILER!!!"
    S_IFMT  = 0170000   # bitmask for the file type bitfields
    S_IFREG = 0100000   # regular file
    S_IFDIR = 0040000   # directory

    ExecutableMask = (0100 | # Owner executable
                      0010 | # Group executable
                      0001)  # Other executable

    attr_reader :filename, :data

    class << self
      private :new
    end

    def self.from(io)
      header = ArchiveHeader.from(io)
      filename = read_filename(header, io)
      data = read_data(header, io)
      new(header, filename, data)
    end

    def self.new_directory(opts)
      mode = S_IFDIR | opts[:mode]
      header = ArchiveHeader.with_defaults(:mode => mode, :name => opts[:name], :filesize => 0)
      new(header, opts[:name], '')
    end

    def self.new_file(opts)
      mode = S_IFREG | opts[:mode]
      header = ArchiveHeader.with_defaults(:mode => mode, :name => opts[:name], :filesize => opts[:io].size)
      opts[:io].rewind
      new(header, opts[:name], opts[:io].read)
    end

    def self.new_trailer
      header = ArchiveHeader.with_defaults(:mode => S_IFREG, :name => TrailerMagic, :filesize => 0)
      new(header, TrailerMagic, '')
    end

    def initialize(header, filename, data)
      @header = header
      @filename = filename
      @data = data
    end

    def trailer?
      @filename == TrailerMagic && @data.size == 0
    end

    def directory?
      mode & S_IFMT == S_IFDIR
    end

    def file?
      mode & S_IFMT == S_IFREG
    end

    def executable?
      (mode & ExecutableMask) != 0
    end

    def mode
      @mode ||= sprintf('%o', @header.mode).to_s.oct
    end

    def to_data
      sprintf("%s%s\000%s", @header.to_data, filename, data)
    end

  private

    def self.read_filename(header, io)
      fname = io.read(header.namesize)
      if fname.size != header.namesize
        raise ArchiveFormatError, "Archive header seems to innacurately contain length of filename"
      end
      fname.chomp("\000")
    end

    def self.read_data(header, io)
      data = io.read(header.filesize)
      if data.size != header.filesize
        raise ArchiveFormatError, "Archive header seems to inaccurately contain length of the entry"
      end
      data
    end

  end

  class ArchiveWriter
    class ArchiveFinalizedError < RuntimeError; end

    def initialize(io)
      @io = io
      @open = false
    end

    def open?
      @open
    end

    def open
      raise ArchiveFinalizedError, "This archive has already been finalized" if @finalized
      @open = true
      yield(self)
    ensure
      close
      finalize
    end

    def mkdir(name, mode = 0555)
      entry = ArchiveEntry.new_directory(:name => name, :mode => mode)
      @io.write(entry.to_data)
    end

    def add_file(name, mode = 0444)
      file = StringIO.new
      yield(file)
      entry = ArchiveEntry.new_file(:name => name, :mode => mode, :io => file)
      @io.write(entry.to_data)
    end

  private

    def add_entry(opts)
    end

    def write_trailer
      entry = ArchiveEntry.new_trailer
      @io.write(entry.to_data)
    end

    def finalize
      write_trailer
      @finalized = true
    end

    def check_open
      raise "#{self.class.name} not open for writing" unless open?
    end

    def close
      @open = false
    end

  end # ArchiveWriter

  class ArchiveReader

    def initialize(io)
      @io = io
    end

    def each_entry
      @io.rewind
      while (entry = ArchiveEntry.from(@io)) && !entry.trailer?
        yield(entry)
      end
    end

  end # ArchiveReader

end   # CPIO

if $PROGRAM_NAME == __FILE__
require 'stringio'
require 'test/unit'
require 'digest/sha1'

class CPIOArchiveReaderTest < Test::Unit::TestCase
  CPIOFixture = StringIO.new(DATA.read)
  # These are SHA1 hashes
  ExpectedFixtureHashes = { 'cpio_test/test_executable'    => '97bd38305a81f2d89b5f3aa44500ec964b87cf8a',
                            'cpio_test/test_dir/test_file' => 'e7f1aa55a7f83dc99c9978b91072d01a3f5c812e' }

  def test_given_a_archive_with_a_bad_magic_number_should_raise
    assert_raises(CPIO::ArchiveFormatError) do
      CPIO::ArchiveReader.new(StringIO.new('foo')).each_entry { }
    end
  end

  def test_given_a_archive_with_a_valid_magic_number_should_not_raise
    archive = CPIO::ArchiveReader.new(CPIOFixture)
    assert_nil archive.each_entry { }
  end

  def test_given_a_valid_archive_should_have_the_expected_number_of_entries
    archive = CPIO::ArchiveReader.new(CPIOFixture)
    entries = 4
    archive.each_entry { |ent| entries -= 1 }
    assert_equal 0, entries, "Expected #{entries} in the archive."
  end

  def test_given_a_valid_archive_should_have_the_expected_entry_filenames
    expected = %w[cpio_test cpio_test/test_dir cpio_test/test_dir/test_file cpio_test/test_executable]
    archive = CPIO::ArchiveReader.new(CPIOFixture)
    archive.each_entry { |ent| expected.delete(ent.filename) }
    assert_equal 0, expected.size, "The expected array should be empty but we still have: #{expected.inspect}"
  end

  def test_given_a_valid_archive_should_have_the_expected_number_of_directories
    expected = 2
    archive = CPIO::ArchiveReader.new(CPIOFixture)
    archive.each_entry { |ent| expected -= 1 if ent.directory? }
    assert_equal 0, expected
  end

  def test_given_a_valid_archive_should_have_the_expected_number_of_regular_files
    expected = 1
    archive = CPIO::ArchiveReader.new(CPIOFixture)
    archive.each_entry { |ent| expected -= 1 if ent.file? && !ent.executable? }
    assert_equal 0, expected
  end

  def test_given_a_valid_archive_should_have_the_expected_number_of_executable_files
    expected = 1
    archive = CPIO::ArchiveReader.new(CPIOFixture)
    archive.each_entry { |ent| expected -= 1 if ent.file? && ent.executable? }
    assert_equal 0, expected
  end

  def test_given_a_valid_archive_should_have_correct_file_contents
    expected = ExpectedFixtureHashes.size
    archive = CPIO::ArchiveReader.new(CPIOFixture)
    archive.each_entry do |ent|
      if (sha1_hash = ExpectedFixtureHashes[ent.filename]) && Digest::SHA1.hexdigest(ent.data) == sha1_hash
        expected -= 1
      end
    end
    assert_equal 0, expected, "Expected all files in the archive to hash correctly."
  end

end

class CPIOArchiveWriterTest < Test::Unit::TestCase

  def test_making_directories_should_work
    expected = 2
    io = StringIO.new
    archiver = CPIO::ArchiveWriter.new(io)
    archiver.open do |arch|
      arch.mkdir "foo"
      arch.mkdir "bar"
    end
    CPIO::ArchiveReader.new(io).each_entry { |ent| expected -= 1 if ent.directory? }
    assert_equal 0, expected
  end

  def test_making_files_should_work
    expected = 2
    io = StringIO.new
    archiver = CPIO::ArchiveWriter.new(io)
    archiver.open do |arch|
      arch.add_file("foo") { |sio| sio.write("foobar") }
      arch.add_file("barfoo") { |sio| sio.write("barfoo") }
    end
    CPIO::ArchiveReader.new(io).each_entry { |ent| expected -= 1 if ent.file? }
    assert_equal 0, expected
  end

  def test_making_files_and_directories_should_work
    expected = 4
    io = StringIO.new
    archiver = CPIO::ArchiveWriter.new(io)
    archiver.open do |arch|
      arch.mkdir "blah"
      arch.add_file("foo") { |sio| sio.write("foobar") }
      arch.add_file("barfoo") { |sio| sio.write("barfoo") }
      arch.add_file("barfoobaz", 0111) { |sio| sio.write("wee") }
    end
    CPIO::ArchiveReader.new(io).each_entry { |ent| expected -= 1 }
    assert_equal 0, expected
  end

  def test_adding_empty_files_should_work
    expected = 1
    io = StringIO.new
    archiver = CPIO::ArchiveWriter.new(io)
    archiver.open do |arch|
      arch.add_file("barfoo", 0111) { |sio| }
    end
    CPIO::ArchiveReader.new(io).each_entry { |ent| expected -= 1 if ent.file? }
    assert_equal 0, expected
  end

  def test_adding_a_file_with_an_excessively_long_name_should_raise
    archiver = CPIO::ArchiveWriter.new(StringIO.new)
    assert_raise(CPIO::ArchiveFormatError) do
      archiver.open do |arch|
        name = "fffff" * (CPIO::ArchiveHeader::FieldMaxValues[:namesize])
        arch.add_file(name) { |sio| }
      end
    end
  end

  def test_adding_a_non_executable_file_should_preserve_said_mode
    io = StringIO.new
    archiver = CPIO::ArchiveWriter.new(io)
    archiver.open do |arch|
      arch.add_file("barfoo", 0444) { |sio| }
    end
    CPIO::ArchiveReader.new(io).each_entry do |ent|
      assert !ent.executable? && ent.file?
    end
  end

  def test_adding_an_executable_file_should_preserve_said_mode
    io = StringIO.new
    archiver = CPIO::ArchiveWriter.new(io)
    archiver.open do |arch|
      arch.add_file("barfoo", 0500) { |sio| }
    end
    CPIO::ArchiveReader.new(io).each_entry do |ent|
      assert ent.executable? && ent.file?
    end
  end
end

end

__END__
0707077777770465470407550007650000240000040000001130242405100001200000000000cpio_test 0707077777770465520407550007650000240000030000001130242404300002300000000000cpio_test/test_dir 0707077777770465531006440007650000240000010000001130242637200003500000000016cpio_test/test_dir/test_file foobarbazbeep
0707077777770465541007550007650000240000010000001130242636000003200000000012cpio_test/test_executable foobarbaz
0707070000000000000000000000000000000000010000000000000000000001300000000000TRAILER!!!              
