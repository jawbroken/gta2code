require 'rubygems'
require 'gd2'

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
        
        # tiles are stored in 4x4 blocks in 64K pages
        while index < size
          page = data[index, 64*1024]
          4.times do |y|
            4.times do |x|
              tile_dat = ""
              64.times do |l|
                tile_dat += page[x*64+(y*64+l)*256, 64]
              end
              processed[:tile][tile_num] = tile_dat
              tile_num += 1
            end
          end
          
          index += 64*1024
        end
      when "PPAL"
        # note: palette in BGRA order
        # processed[:ppal] = {}
        # index = 0
        # ppal_num = 0
        # while index < size
        #   ppal_dat = data[index, 1024]
        #   processed[:ppal][ppal_num] = ppal_dat
        #   index += 1024
        #   ppal_num += 1
        # end
        processed[:ppal] = {}
        index = 0
        ppal_num = 0
        
        # palettes are stored as columns in 64K pages
        while index < size
          page = data[index, 64*1024]
          
          64.times do |i|
            ppal_dat = {}
            256.times do |l|
              ppal_dat[l] = page[i*4+l*256,4] 
            end
            processed[:ppal][ppal_num] = ppal_dat
            ppal_num += 1
          end
          index += 64*1024
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
      when "DELX"
        index = 0
        delxs = []
        while index < size
          delx_arr = data[index,4].unpack("SCC")
          which_sprite = delx_arr[0]
          delta_count = delx_arr[1]
          delta_size = data[index+4,2*delta_count].unpack("S"*delta_count)
          delx = {}
          delx[:which_sprite] = which_sprite
          delx[:delta_count] = delta_count
          delx[:delta_size] = delta_size
          delxs << delx
          index += 4+2*delta_count
        end
        processed[:delx] = delxs
      when "PALX"
        processed[:palx] = data.unpack("S"*16384)
      when "PALB"
        palb_arr = data.unpack("S"*8)
        palb = {}
        palb[:tile] = 0
        palb[:sprite] = palb_arr[0]
        palb[:car_remap] = palb[:sprite] + palb_arr[1]
        palb[:ped_remap] = palb[:car_remap] + palb_arr[2]
        palb[:code_obj_remap] = palb[:ped_remap] + palb_arr[3]
        palb[:map_obj_remap] = palb[:code_obj_remap] + palb_arr[4]
        palb[:user_remap] = palb[:map_obj_remap] + palb_arr[5]
        palb[:font_remap] = palb[:user_remap] + palb_arr[6]
        processed[:palb] = palb
      else
        puts "ERROR: Unknown Chunk Type: #{type}"
        #exit
      end
    end
    
    if(!processed[:tile].nil? and !processed[:ppal].nil? and
      !processed[:palx].nil? and !processed[:palb].nil?)
      output_dir = "./tiles/#{File::basename(filename).split(".")[0]}"
      FileUtils.mkdir_p output_dir
      
      tile = processed[:tile]
      ppal = processed[:ppal]
      palx = processed[:palx]
      palb = processed[:palb]
      tile_base = palb[:tile]
      
      tile.each do |tile_num, tile_raw|
        tile_pal_ind = palx[tile_base+tile_num]
        tile_pal = ppal[tile_pal_ind]
        # workaround for GD2 alpha
        tile_img = GD2::Image.import('./blank_tile.png')
        tile_img.save_alpha = 1
        64.times do |x|
          64.times do |y|
            pix_raw = tile_raw[x+64*y]
            color = tile_pal[pix_raw]
            tile_img.set_pixel(x,y,GD2::Color.new(color[2],color[1],color[0], 
              pix_raw == 0 ? GD2::ALPHA_TRANSPARENT : GD2::ALPHA_OPAQUE).to_i)
          end
        end
        tile_img.export("#{output_dir}/#{tile_num}.png")
      end
    end
  end
end
