Dir['./data/*.sty'].each do |filename|
  File.open(filename, 'rb') do |f|
    file_type = f.read(4)
    next if file_type != "GBST"
    
    # apparently 700, not 600 as in the dox
    version_code = f.read(2).unpack("S")[0]
    
    # extract all chunks from file
    chunks = []
    chunk_type = f.read(4)
    while(!chunk_type.nil?)
      chunk_size = f.read(4).unpack("I")[0]
      
      p [chunk_type, chunk_size]
      
      chunk_data = f.read(chunk_size)
            
      chunks << [chunk_type, chunk_size, chunk_data]
      
      # set up next loop
      chunk_type = f.read(4)
    end
    
    exit
  end
end
