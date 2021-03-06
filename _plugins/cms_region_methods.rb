module Jekyll
  module CmsRegionMethods
    def process_params(params)
      kv_params = {}
      params.each do |kvstr|
        kv_arr = kvstr.to_s.strip.split(':')
        kv_params[kv_arr[0].strip] = kv_arr[1].to_s.strip
      end
      return kv_params
    end

    def render(context)
      site = context.registers[:site]
      site.data['regions'] ||= []
      page_folder = context['page']['path']
      
      # include_data_path = File.join(root_path, site.config['includes_dir'], '_regions')

      region_items = read_data_json_from(context)
      raise "Array is expected in #{@filename}, but #{region_items.class.to_s} found" unless region_items.instance_of? Array

      site.data['regions'] << File.join(page_folder, @filename)

      region_type = @options['type'] || 'html'
      region_classes = get_region_classes(context)    
      suggested_height = @options['suggested_height']
      suggested_width = @options['suggested_width']

      #image_data = ['data-suggested-width' => suggested_width, 'data-suggested-height'=> suggested_height] if region_type == 'image'

      if region_type == 'image'
        wrap('div', 'class' => 'tt-region', 'data-region' => File.join(site.active_lang, page_folder, @filename), 'data-suggested-width' => suggested_width, 'data-suggested-height'=> suggested_height, 'data-region-type' => region_type, 'data-region-classes'=>region_classes) do
          region_content(region_items, context)
        end
      else
        wrap('div', 'class' => 'tt-region', 'data-region' => File.join(site.active_lang, page_folder, @filename), 'data-region-type' => region_type, 'data-region-classes'=>region_classes) do
          region_content(region_items, context)
        end
      end

    rescue Exception => error
      print error.message, "\n"
      print error.backtrace.join("\n")
      return 'Error: ' + error.message
    end

    private

    def get_region_classes(context)
      get_region_classes_from_options(context)
    end
    
    def get_region_classes_from_options(context)
      @options['classes']
    end

    #def empty_region_content(include_data_path, context)
    def empty_region_content(context)
      include(context, 0, {"_template"=>"html"})
    end

    #def include(include_data_path, context, index, ped)
    def include(context, index, ped)
      template = ped['_template']
      raise "'_template' property not found in \n#{ped.to_s}" if template.nil?

      #liquid = Liquid::Template.parse(read_include(include_data_path, template, default_content(template)))
      liquid = Liquid::Template.parse(default_content(template))
      
      context['include'] = {'instance' => ped}
      wrap('div', 'class' => 'tt-region_ped', 'data-ped-index' => index, 'data-ped-type' => ped['_template']) do
        liquid.render(context)
      end
    end

    # def read_include(include_data_path, filename, default_content = nil)
    #   template_path = File.join(include_data_path, filename)
    #   if File.exists?(template_path)
    #     File.open(template_path, 'r') do |file|
    #       file.read
    #     end
    #   else
    #     default_content || raise("Can't find template file #{template_path}")
    #   end
    # end

    def read_data_json_from(context)
      site = context.registers[:site]
      root_path = site.source
      page_folder = context['page']['path']
      
      
      data_dirs = [site.config['data_dir']].flatten
      data_dirs.reverse.each do |dir|
        region_data_path = File.join(root_path, dir, '_regions', site.active_lang, page_folder)
        path = File.join(region_data_path, @filename)
        if File.exists?(path)
          File.open(path, 'r') do |file|
            return JSON.parse(file.read)
          end
        end
      end
      return []
    end

    def wrap(tag, options)
      attrs = options.map { |k,v| "#{k}='#{v}'"}.join(' ')
      "<#{tag} #{attrs}>#{yield}</#{tag}>"
    end

    def default_content(template)
      case template
        when 'html'
          '{{include.instance.content}}'
        else
          nil
      end
    end

    def region_content(region_items, context)
      if region_items.size == 0
          #empty_region_content(include_data_path, context)
          empty_region_content(context)
        else
          region_items.each_with_index.map do |ped, index|
            #include(include_data_path, context, index, ped)
            include(context, index, ped)
          end.join
      end
    end
  end
end

