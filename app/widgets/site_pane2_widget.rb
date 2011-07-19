class SitePane2Widget < Apotomo::Widget
  responds_to_event :submit, :with=>:update_site

  def display(options = {})
    @project = options[:project]
    @sites = options[:sites]
    @site = options[:projectSite]
    @current_user = options[:user]
    #@id = UUIDTools::UUID.timestamp_create
    @auth = !@current_user.nil? && @current_user.projects.include?(@project)
    
    @site_stats = []
    @site_samps = []
    @variable_labels = Array["Variable Data","Count","Start","End"]
    @sample_labels = Array["Sample Type","Lab Sample Code","Sample Medium","Timestamp"]
    @sample_fields = Array["sample_type","lab_sample_code","material","local_date_time"]
    @sites.map{ |site| 
      stats = @project.managed_repository{Voeis::SiteDataCatalog.all(:site_id=>site.id)}.aggregate(:record_number.sum, :starting_timestamp.min, :ending_timestamp.max)
      stats.map!{ |x| 
        if x.nil?
          x = 'NA'
        else
          if x.class.to_s[0,4]=='Date'
            x = x.strftime('%m/%d/%Y')
          else
            x = x
          end
        end
      }
      @site_stats << {:vars=>site.variables.count, :count=>stats[0], :first=>stats[1], :last=>stats[2]}
    }
    
    @sites.map{ |site| 
      @temp_array = []
      site.samples.all(:order => [:lab_sample_code.asc]).each { |samp|
        @temp_array << Array[samp.sample_type, samp.lab_sample_code, samp.material, samp.local_date_time.to_s]
      }
      @site_samps << @temp_array
    }
    
    render
  end
  
private
  def setup
    #@test = options[:test]
  end
end