require 'responders/rql'

class Voeis::VariableNameCVsController < Voeis::BaseController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page

  has_widgets do |root|
    root << widget(:versions)
    root << widget(:edit_cv)
  end


  # GET /variables/new
  def new
    @variable_name = Voeis::VariableNameCV.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end

  ### LOCAL: POST /variable_name_c_vs
  def create
    @project = parent
    @project.managed_repository{
      cvparams = params
      cvparams = params[:variable_name_c_v] if !params[:variable_name_c_v].nil?
      @variable_name = Voeis::VariableNameCV.with_deleted{Voeis::VariableNameCV.get(cvparams[:id])}
      if @variable_name.nil?
        @variable_name = Voeis::VariableNameCV.create(:id=>cvparams[:id],
                                :term=>cvparams[:term],
                                :definition=>cvparams[:definition],
                                :provenance_comment=>cvparams[:provenance_comment])
      else
        #@vertical_datum.deleted_at  #need to reference 'deleted_at' because of lazy loading
        @variable_name.update(:term=>cvparams[:term],
                              :definition=>cvparams[:definition],
                              :provenance_comment=>cvparams[:provenance_comment],
                              :deleted_at=>nil)
      end
    
      respond_to do |format|
        format.html do
          flash[:notice] = 'Variable Name was successfully created.'
          redirect_to(new_variable_name_c_v_path())
        end
        format.json do
          render :json => @variable_name.as_json, :callback => params[:jsoncallback]
        end
      end
    }
  end

  ### LOCAL: PUT /variable_names_c_vs
  def update
    @project = parent
    @project.managed_repository{
      if params[:variable_name_c_v].nil?
        @variable_name = Voeis::VariableNameCV.get(params[:id])
        cvparams = params
      else
        @variable_name = Voeis::VariableNameCV.get(params[:variable_name_c_v][:id])
        cvparams = params[:variable_name_c_v]
      end
      cvparams.each do |key, value|
        @variable_name[key] = value.blank? ? nil : value
      end
      @variable_name.updated_at = Time.now
      
      respond_to do |format|
        if @variable_name.save
          format.html do
            flash[:notice] = 'Variable Name was successfully updated.'
            redirect_to(new_variable_name_c_v_path()) 
          end
          format.json do
            render :json => @variable_name.as_json, :callback => params[:jsoncallback]
          end
        else
          format.html { render :action => "new" }
        end
      end
    }
  end

  ### LOCAL: DELETE /variable_names_c_vs
  def destroy
    @project = parent
    @project.managed_repository{
      variable_name = Voeis::VariableNameCV.get(params[:id])
      #debugger
      if !variable_name.destroy
        #FAILED!
        #format.html { render :action => "update" }
        error_notice = 'Variable Name delete FAILED!'
        respond_to do |format|
          format.html {
            flash[:error] = error_notice
            redirect_to(variable_name_path())
          }
          format.json {
            render :json=>{:id=>variable_name.id,:errors=>[error_notice]}.as_json, :callback=>params[:jsoncallback]
          }
        end
      else
        respond_to do |format|
          format.html {
            flash[:notice] = 'Variable Name was successfully deleted.'
            redirect_to(variable_name_path())
          }
          format.json {
            render :json => {:id=>variable_name.id}.as_json, :callback=>params[:jsoncallback]
          }
        end
      end
    }
  end
  
  def show
  end

  ### LOCAL: GET /variable_names_c_vs -- List VariableName entries
  def index
    @project = parent
    if User.current.nil? || User.current.system_role.name!='Administrator'
      flash[:notice] = 'You have inadequate permissions for this operation.'
      redirect_to(project_path(@project))
    end
    ### LOCAL VARIABLE NAME
    @global = false
    @cv_data0 = @project.managed_repository{Voeis::VariableNameCV.all}
    #@cv_data = @cv_data0.map{|d| d.attributes.update({:used=>!@project.sites.first(:variable_name_id=>d[:id]).nil?})}
    @cv_data = @cv_data0.map{|d| d.attributes.update({:used=>false})}
    @copy_data = Voeis::VariableNameCV.all(:id.not=>@cv_data0.collect(&:id)) #, :order=>[:term.asc])
    @cv_title = 'Variable Name'
    @cv_title2 = 'variable_name'
    @cv_title2cv = 'variable_name_c_v'
    @cv_id = 'id'
    @cv_name = 'term'
    @cv_columns = [{:field=>"id", :label=>"ID", :width=>"25px", :filterable=>false, :formatter=>"", :style=>""},
                  {:field=>"term", :label=>"Term", :width=>"180px", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"definition", :label=>"Definition", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"updated_at", :label=>"Updated", :width=>"80px", :filterable=>true, :formatter=>"dateTime", :style=>""}]
    @copy_columns = [{:field=>"id", :label=>"ID", :width=>"5%", :filterable=>false, :formatter=>"", :style=>""},
                  {:field=>"term", :label=>"Term", :width=>"15%", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"definition", :label=>"Definition", :width=>"", :filterable=>true, :formatter=>"", :style=>""},
                  {:field=>"updated_at", :label=>"Updated", :width=>"18%", :filterable=>true, :formatter=>"dateTime", :style=>""}]
    @cv_form = [{:field=>"id", :type=>"-IH", :required=>"", :style=>""},
                  {:field=>"idx", :type=>"-XH", :required=>"", :style=>""},
                  {:field=>"Term", :type=>"-LL", :required=>"", :style=>""},
                  {:field=>"term", :type=>"1B-STB", :required=>"true", :style=>""},
                  {:field=>"Definition", :type=>"2B-LL", :required=>"false", :style=>""},
                  {:field=>"definition", :type=>"1B-STA", :required=>"false", :style=>""}]
    render 'voeis/cv_index.html.haml'
  end

  ### LOCAL: VARIABLE-NAME HISTORY!
  def versions
    @global = false
    @project = parent
    @cv_item = @project.managed_repository{Voeis::VariableNameCV.get(params[:id])}
    #@cv_versions = @project.managed_repository{Voeis::VerticalDatumCV.get(params[:id]).versions}
    #@cv_versions = @project.managed_repository{@cv_item.versions_array}
    @cv_versions = @project.managed_repository.adapter.select('SELECT * FROM voeis_variable_name_cv_versions WHERE id=%s ORDER BY updated_at DESC'%@cv_item.id)
    @cv_title = 'Variable Name'
    @cv_title2 = 'variable_name'
    @cv_term = 'term'
    @cv_name = 'term'
    @cv_id = 'id'

    @cv_refs = []

    @cv_properties = [
      #{:label=>"Version", :name=>"version"},
      #{:label=>"ID", :name=>"id"},
      {:label=>"Term", :name=>"term"},
      {:label=>"Definition", :name=>"definition"}
    ]
    render 'spatial_references/versions.html.haml'
  end

  def invalid_page
    redirect_to(:back)
  end
end