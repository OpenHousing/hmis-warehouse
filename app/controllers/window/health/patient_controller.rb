module Window::Health
  class PatientController < ApplicationController
    before_action :require_can_edit_client_health!
    before_action :set_client, only: [:index]
    before_action :set_patient, only: [:index]
    include PjaxModalController
    include HealthPatient
    include WindowClientPathGenerator
    include ActionView::Helpers::NumberHelper
    
    helper HealthOverviewHelper

    def index
      load_patient_metrics
      
      render layout: !request.xhr?      
    end
    
  end
end