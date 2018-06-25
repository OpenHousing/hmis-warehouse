# A wrapper around Services form changes to ease Qualifying Activities creation
module Health
  class DmeSaver

    def initialize user:, equipment: Health::Equipment.new
      @user = user
      @equipment = equipment
      @qualifying_activity = setup_qualifying_activity
    end

    def create
      update
    end

    def update
      @equipment.class.transaction do 
        @equipment.save!
        @qualifying_activity.source_id = @equipment.id
        @qualifying_activity.save
      end
    end

    protected def setup_qualifying_activity
      Health::QualifyingActivity.new(
        source_type: @equipment.class.name,
        user_id: @user.id,
        user_full_name: @user.name_with_email,
        date_of_activity: Date.today,
        activity: 'Care planning',
        follow_up: 'Provide durable medical equipment to patient',
        reached_client: 'Yes (face to face, phone call answered, response to email)',
        mode_of_contact: 'In Person',
        patient_id: @equipment.patient_id
      )
    end


  end
end