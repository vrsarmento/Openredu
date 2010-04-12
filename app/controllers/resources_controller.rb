class ResourcesController < BaseController
  
  before_filter :login_required, :except => [:index]
  
  def favorites
    
    if params[:from] == 'favorites'
      @taskbar = "favorites/taskbar"
    else
      @taskbar = "resources/taskbar_index"
    end
    
    @resources = Resource.paginate(:all, 
    :joins => :favorites,
    :conditions => ["favorites.favoritable_type = 'Resource' AND favorites.user_id = ? AND resources.id = favorites.favoritable_id", current_user.id], 
    :page => params[:page], :order => 'created_at DESC', :per_page => AppConfig.items_per_page)
    
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @resources }
    end
  end
  
  
  
  def add
    @resources = Resource.all
    
    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @resources }
    end
  end
  
  def sort
    
  end
  
  def search
    
    @resources = Resource.find(:all, :conditions => ["title LIKE ?", "%" + params[:query] + "%"])
    #, :conditions => ["statement LIKE '%?%'", params[:query]]
    
    respond_to do |format|
      format.js do
        render :update do |page| 
          page.replace_html 'local_search_results', :partial => 'resources/item', :collection => @resources, :as => :resource
          # :partial => "questions/list_item", :collection => @products, :as => :item 
          #page.insert_html :bottom, "questions", :partial => 'questions/question_show', :object => @question
          #page.visual_effect :highlight, "question_#{@question.id}" 
        end
      end
    end
  end
  
  
  
  
  def rate
    @resource = Resource.find(params[:id])
    @resource.rate(params[:stars], current_user, params[:dimension])
    id = "ajaxful-rating-#{!params[:dimension].blank? ? "#{params[:dimension]}-" : ''}recourse-#{@resource.id}"
    
    render :update do |page|
      page.replace_html id, ratings_for(@resource, :wrap => false, :dimension => params[:dimension])
      page.visual_effect :highlight, id
    end
  end
  
=begin desnecessario pois tem um controller central de comentarios que faz isso 
  def put_comment
    
    if current_user
   
    thecomment = params[:comment]
    @commentable = Resource.find(params[:id])
    @commentable.comments.create(:comment => thecomment, :user => current_user)
    
    else
      flash[:error] = 'Usuário não logado'
    end
      redirect_to :back
    
  end
=end
  def get_query(sort, page)
    
    case sort
      
      when '1' # Data
      @courses = Resource.paginate :conditions => ["published = ? and state LIKE 'approved'", true], :include => :owner, :page => page, :order => 'created_at DESC', :per_page => AppConfig.items_per_page
      when '2' # Avaliações
      @courses = Resource.paginate :conditions => ["published = ? and state LIKE 'approved'", true], :include => :owner, :page => page, :order => 'rating_average DESC', :per_page => AppConfig.items_per_page
      when '3' # Downloads #TODO
      @courses = Resource.paginate :conditions => ["published = ? and state LIKE 'approved'", true], :include => :owner, :page => page, :order => 'rating_average DESC', :per_page => AppConfig.items_per_page
      when '4' # Título
      @courses = Resource.paginate :conditions => ["published = ? and state LIKE 'approved'", true], :include => :owner, :page => page, :order => 'title DESC', :per_page => AppConfig.items_per_page
    else
      @courses = Resource.paginate :conditions => ["published = ? and state LIKE 'approved'", true], :include => :owner, :page => page, :order => 'created_at DESC', :per_page => AppConfig.items_per_page
    end
    
  end  
  
  
  # GET /resources
  # GET /resources.xml
  def index
    
    if params[:user_id] # TODO garantir que é sempre login e nao id?
      @user = User.find_by_login(params[:user_id])
      @resources = @user.resources.paginate :conditions => ["state LIKE 'approved'"], :page => params[:page], :per_page => AppConfig.items_per_page
      
      respond_to do |format|
        format.html { render :action => "user_resources"} 
        format.xml  { render :xml => @user.resources }
      end
    else 
      
      @sort_by = params[:sort_by]
      #@order = params[:order]
      @resources = get_query(params[:sort_by], params[:page])
      
      @popular_tags = Resource.tag_counts
      
      respond_to do |format|
        format.html # index.html.erb
        format.xml  { render :xml => @resources }
      end
    end
    
  end
  
  # GET /resources/1
  # GET /resources/1.xml
  def show
    @resource = Resource.find(params[:id])
    
    Log.log_activity(@resource, 'show', current_user)
    
    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @resource }
    end
  end
  
  # GET /resources/new
  # GET /resources/new.xml
  def new
    @resource = Resource.new
  end
  
  # GET /resources/1/edit
  def edit
    @resource = Resource.find(params[:id])
  end
  
  # POST /resources
  # POST /resources.xml
  def create
    @resource = Resource.new(params[:resource])
    @resource.owner = current_user
    
    Log.log_activity(@resource, 'create', current_user)
    
    respond_to do |format|
      if @resource.save
        
        Log.log_activity(@resource, 'create', current_user)
        
        flash[:notice] = 'O material foi criado com sucesso!'
        format.html { 
        #redirect_to(@resource) }
        redirect_to waiting_user_resources_path(current_user.id)
        }
        format.xml  { render :xml => @resource, :status => :created, :location => @resource }
      else
        format.html { render :action => 'new' }
        format.xml  { render :xml => @resource.errors, :status => :unprocessable_entity }
      end
      
    end
  end
  
  # PUT /resources/1
  # PUT /resources/1.xml
  def update
    @resource = Resource.find(params[:id])
    
    respond_to do |format|
      if @resource.update_attributes(params[:resource])
        flash[:notice] = 'Resource was successfully updated.'
        format.html { redirect_to(@resource) }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @resource.errors, :status => :unprocessable_entity }
      end
    end
  end
  
  # DELETE /resources/1
  # DELETE /resources/1.xml
  def destroy
    @resource = Resource.find(params[:id])
    @resource.destroy
    
    respond_to do |format|
      format.html { redirect_to(resources_url) }
      format.xml  { head :ok }
    end
  end
  
  def published
    @resources = Resource.paginate(:conditions => ["owner_id = ? AND published = 1 AND state LIKE 'approved'", params[:user_id]], 
  		:include => :owner, 
  		:page => params[:page], 
  		:order => 'updated_at DESC', 
  		:per_page => AppConfig.items_per_page)
    
    respond_to do |format|
      format.html #{ render :action => "my" }
      format.xml  { render :xml => @resources }
    end
  end
  
  def unpublished
    @resources = Resource.paginate(:conditions => ["owner = ? AND published = 0", params[:user_id]], 
      :include => :owner, 
      :page => params[:page], 
      :order => 'updated_at DESC', 
      :per_page => AppConfig.items_per_page)
    
    respond_to do |format|
      format.html #{ render :action => "my" }
      format.xml  { render :xml => @resources }
    end
  end
  
  #moderating resource
  def approve
    @resource = Resource.find(params[:id])
    @resource.approve!
    flash[:notice] = 'O material auxiliar foi aprovado!'
    redirect_to waiting_resources_path
  end
  
  def disapprove
    @resource = Resource.find(params[:id])
    @resource.disapprove!
    flash[:notice] = 'O material auxiliar não foi aprovado!'
    redirect_to waiting_resources_path
  end
  
  def waiting
    @resources = Resource.paginate(:conditions => ["published = 1 AND state LIKE 'waiting'"], 
      :include => :owner, 
      :page => params[:page], 
      :order => 'updated_at DESC', 
      :per_page => AppConfig.items_per_page)
    
    respond_to do |format|
      format.html #{ render :action => "my" }
      format.xml  { render :xml => @resources }
    end
  end
  
  def download
    @resource = Resource.find(params[:id])
    send_file 'http://localhost:3000/public/system/medias/11/original/test.txt', :type => 'application/pdf', :x_sendfile => true
    
    @resource.update_attribute(:download_count, @resource.download_count + 1)
  end
  
  
  
end
