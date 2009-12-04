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
    
    processed = {}
    
    chunks.each do |type, size, data|
      case type
      when "TILE"
        processed[:tile] = {}
        index = 0
        tile_num = 0
        
        while index < size
          tile_dat = data[index,64**2]
          processed[:tile][tile_num] = tile_dat
          index += 64**2
          tile_num += 1
        end
      when "PPAL"
        
      else
        puts "ERROR: Unknown Chunk Type: #{type}"
        exit
      end
      
    end
    
    exit
  end
end
