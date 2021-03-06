class LabMethodsController < ApplicationController
  rescue_from ActionView::MissingTemplate, :with => :invalid_page


  # GET /lab_methods/new
  def new
    @lab_method = Voeis::LabMethod.new

    respond_to do |format|
      format.html # new.html.erb
    end
  end
  
  # POST /lab_methods
  def create
    @lab_method = Voeis::LabMethod.new(params[:lab_method])
    respond_to do |format|
      if @lab_method.save
        flash[:notice] = 'Lab Method was successfully created.'
        format.json do
          render :json => @lab_method.as_json, :callback => params[:jsoncallback]
        end
        format.html { (redirect_to(new_lab_method_c_v_path())) }
      else
        format.html { render :action => "new" }
      end
    end
  end
  def show
    
  end

  def invalid_page
    redirect_to(:back)
  end
end