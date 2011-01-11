# pour avoir des valeurs par défaut à l'import, utiliser ce modèle

#Page.send :include, PageDefaultValues
#
#module PageDefaultValues
#  
#  def self.included(base)
#    base.send :include, InstanceMethods
#    base.before_save :set_default_values
#  end
#    
#  module InstanceMethods
#    
#    def set_default_values
#      return unless new_record?
#      
#      self.sitemap ||= true
#      self.change_frequency ||= 'weekly'
#      self.priority ||= 0.5
#    end
#    
#  end
#  
#end

namespace :bulk_import do
  
  @page_attributes = {}
  @layouts = {}
  
  desc 'Importation de l\'arborescence'
  task :pages do
    page = Page.new
    @page_attributes = page.attributes
    
    pages = YAML::load_file(File.join(Rails.root, 'config', 'pages.yml'))
    
    Page.delete_all
    PagePart.delete_all
    BodyClass.delete_all
    
    import_pages pages
  end

  private
  
  def import_pages(yml, parent_id = nil)
    yml['parent_id'] = parent_id
    yml['breadcrumb'] = yml['title'] unless yml['breadcrumb']
    yml['status_id'] = 100 unless yml['status_id']
    
    page = {}
    @page_attributes.each do |key, value|
      page[key] = yml[key] || value
    end
  
    if yml['layout_name']
      page['layout_id'] = @layouts[yml['layout_name']] = @layouts[yml['layout_name']] || Layout.find_by_name(yml['layout_name']).id
    end
    
    radiant_page = Page.new page
    radiant_page.save
    
    if yml['body_class']
      radiant_body_class = BodyClass.new({:name => yml['body_class']})
      radiant_body_class.page_id = radiant_page.id
      radiant_body_class.save
    end
    
    parts = yml['parts'] || []
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
    
    children = yml['children'] || []
    children.each do |child|
      import_pages child, radiant_page.id
    end
  end
  
end