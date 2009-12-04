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
        # note: palette in BGRA order
        processed[:ppal] = {}
        index = 0
        ppal_num = 0
        while index < size
          ppal_dat = data[index, 1024]
          processed[:ppal][ppal_num] = ppal_dat
          index += 1024
          ppal_num += 1
        end
      when "SPRB"
        sprb_arr = data.unpack("SSSSSS")
        sprb = {}
        sprb[:car] = sprb_arr[0]
        sprb[:ped] = sprb_arr[1]
        sprb[:code_obj] = sprb_arr[2]
        sprb[:map_obj] = sprb_arr[3]
        sprb[:user] = sprb_arr[4]
        sprb[:font] = sprb_arr[5]
        processed[:sprb] = sprb
      when "FONB"
        font_count = data[0,2].unpack("S")[0]
        index = 2
        bases = [0]
        (font_count-1).times do
          num_char = data[index,2].unpack("S")[0]
          bases << bases[bases.length-1] + num_char
          index += 2
        end
        processed[:fonb] = bases
      else
        puts "ERROR: Unknown Chunk Type: #{type}"
        exit
      end
      
    end
    
    exit
  end
end
