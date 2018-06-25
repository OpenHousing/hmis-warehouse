module Window::Health
  class ServicesController < IndividualPatientController

    before_action :set_client
    before_action :set_hpc_patient
    before_action :set_service, only: [:edit, :destroy, :update]
    
    include PjaxModalController
    include WindowClientPathGenerator
    def index
      # For errors in new/edit forms
      @service = service_source.new
      @equipment = Health::Equipment.new
      @services = @patient.services.order(date_requested: :desc)
      @equipments = @patient.equipments
    end

    def new
      @service = service_source.new
      @equipment = Health::Equipment.new
      @button_label = 'Add Service'
      @form_url = polymorphic_path(health_path_generator + [:services], client_id: @client.id)
    end

    def edit
      @button_label = 'Save Service'
      @form_url = polymorphic_path(health_path_generator + [:service], client_id: @client.id)
    end

    def update
      @button_label = 'Save Service'
      @form_url = polymorphic_path(health_path_generator + [:service], client_id: @client.id)
      @service.assign_attributes(service_params)
      if request.xhr?
        begin
          Health::ServiceSaver.new(service: @service, user: current_user).update
        rescue ActiveRecord::RecordInvalid => e
          j render 'create' 
        end
      else
        Health::ServiceSaver.new(service: @service, user: current_user).update
        respond_with(@service, location: polymorphic_path(health_path_generator + [:services], client_id: @client.id))
      end
    end
  
    def create
      @button_label = 'Add Service'
      @form_url = polymorphic_path(health_path_generator + [:services], client_id: @client.id)
      @service = @patient.services.build(service_params)
      if request.xhr?
        begin
          Health::ServiceSaver.new(service: @service, user: current_user).update
        rescue ActiveRecord::RecordInvalid => e
          j render 'create' 
        end
      else
        Health::ServiceSaver.new(service: @service, user: current_user).update
        respond_with(@service, location: polymorphic_path(health_path_generator + [:services], client_id: @client.id))
      end
    end

    def destroy
      @service.destroy
      unless request.xhr?
        respond_with(@service, location: polymorphic_path(health_path_generator + [:services], client_id: @client.id))
      end
    end

    def service_params
      params.require(:health_service).permit(
        :service_type,
        :provider,
        :hours,
        :days,
        :date_requested,
        :effective_date,
        :end_date,
        :status,
      )
    end

    def service_source
      Health::Service
    end

    def set_service
      @service = service_source.find(params[:id].to_i)
    end

    def set_careplan
      @careplan = careplan_source.find(params[:careplan_id].to_i)
    end

    def careplan_source
      Health::Careplan
    end
    
    def flash_interpolation_options
      { resource_name: 'Service' }
    end
  end
end