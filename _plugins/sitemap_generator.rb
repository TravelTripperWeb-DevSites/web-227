require 'xkeys'
Jekyll::Hooks.register :site, :post_write do |site|
  SitemapGenerator.new(site).generate
end

class SitemapGenerator
  attr_reader :site

  STANDARD_KEYS=["_definitions", "_models", "_regions", "regions"]

  def initialize(site)
    @site = site
  end

  def generate
    pages = site.unfiltered_pages
    default_lang = site.config['default_lang'] || 'en'
    # generate only once
    return unless default_lang == site.active_lang
    sitemap = {}.extend(XKeys::Hash)
    sitemap['__CONFIG__', 'default_locale'] = default_lang
    sitemap['__CONFIG__', 'page_gen'] = site.config['page_gen']
    sitemap['__CONFIG__', 'locales'] = site.config['languages']
    
    # see if there's a page_order file
    page_order_file_name = File.join(site.source, "_data/pageorder.yml")
    page_orders = {}
    if File.exists?(page_order_file_name)
      File.open(page_order_file_name, "r") do |f|
        page_orders = YAML.load(f.read)
      end
    end
    default_order = 0
    pages.each do |page|
      next if page.sass_file?	 # Don't include sass files in the page tree
      default_order += 1 
      url = page.url
      url += 'index.html' if url.end_with?('/')
      url = '__ROOT__' + url
      path = url.split('/')
      label = path.last == 'index.html' && path.length > 2 ? path[-2] : path.last
      path = path[0..-2] 

      # IF we've jumped over an index
      path_to_check = []
      path[0..-2].each do |path_part|
        path_to_check << path_part 
        if !sitemap[*path_to_check] || !sitemap[*path_to_check]['__PAGES__']
          page_path = path_to_check + ['__PAGES__']
          sitemap[*page_path] ||= []
          pageorder_lookup = (path[1..-1].join('/'))
          sitemap[*page_path][0] = {order: page_orders["/#{pageorder_lookup}/"] || default_order }
        end      
      end

      path += ['__PAGES__']
      source_path = page.is_a?(Jekyll::DataPage) ? page.source_path : page.path

      

      sitemap[*path] ||= []
      sitemap[*path][0] = { label: page.data['label'] || page.data['title'] || label, published: page.data['published']!=false, locales: localized_urls(site, page), data_source: (page.is_a?(Jekyll::DataPage) && page.data_source) || nil, source_path: source_path, order: page_orders[page.url] || default_order } unless page.data['editable'] === false
    end

    sitemap['__REGIONS__'] = site.data['regions']

    sitemap['__SETTINGS__'] = site.data.keys.collect{|k| STANDARD_KEYS.include?(k) ? nil : k}.compact

    if Dir.exists?('tmp/src')
      Dir.chdir('tmp/src') {
        sitemap['__SHA__'] = sha
      }
    else
      sitemap['__SHA__'] = sha
    end
    save sitemap
  end

  def localized_urls(site, page)
    (site.config['languages'] || ['en']).map do |locale|
      { locale => page.url(locale) }
    end.inject({}, :merge)
  end

  private

  def save(sitemap)
    File.open('sitemap.json', 'w') do |f|
      f.write(JSON.pretty_generate(sitemap, indent: "  "))
    end
  end

  def sha
    `git rev-parse HEAD`.chomp
  end

end
