namespace :'bulk-import' do
  
  desc 'Importation de l\'arborescence'
  task :pages do
    pages = YAML::load_file(File.join(Rails.root, 'vendor', 'extensions', 'avocats', 'config', 'pages.yml'))
    
    Page.delete_all
    PagePart.delete_all
    BodyClass.delete_all
    
    import pages
  end

  private
  
  def import(page, parent_id = nil)
    page['parent_id'] = parent_id
    page['breadcrumb'] = page['title'] unless page['breadcrumb']
    page['status_id'] = 100
    page['sitemap'] = true
    page['change_frequency'] ='weekly'
    page['priority'] = 0.5
    page['avocat_id'] = 'none' unless page['avocat_id']
    
    page['layout_id'] = page['layout_name'] && page['layout_name'].index('<inherit>') ? nil : page['layout_name']
    page.delete 'layout_name'
    if page['layout_id']
      page['layout_id'] = Layout.find_by_name(page['layout_id']).id
    end
    
    children = page['children'] || []
    page.delete 'children'
    
    body_class = page['body_class'] || nil
    page.delete 'body_class'
    
    parts = page['parts'] || []
    page.delete 'parts'
    
    radiant_page = Page.new page
    radiant_page.save
    
    if body_class
      radiant_body_class = BodyClass.new({:name => body_class})
      radiant_body_class.page_id = radiant_page.id
      radiant_body_class.save
    end
    
    if parts.any?
      parts.each do |part|
        radiant_part = PagePart.new part
        radiant_part.page_id = radiant_page.id
        radiant_part.save
      end
    else
      radiant_part = PagePart.new({:name => 'body'})
      radiant_part.page_id = radiant_page.id
      radiant_part.content = ''
      radiant_part.save
    end
    
    children.each do |child|
      import child, radiant_page.id
    end
  end
  
end