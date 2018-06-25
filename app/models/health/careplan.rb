module Health
  class Careplan < HealthBase
    
    acts_as_paranoid
    has_many :goals, class_name: Health::Goal::Base.name
    has_many :hpc_goals, class_name: Health::Goal::Hpc.name
    has_one :team, class_name: Health::Team.name, dependent: :destroy

    has_many :team_members, through: :team, source: :members
    belongs_to :patient, class_name: Health::Patient.name
    belongs_to :user

    has_many :services, through: :patient, class_name: Health::Service.name
    has_many :equipments, through: :patient, class_name: Health::Equipment.name

    belongs_to :responsible_team_member, class_name: Health::Team::Member.name
    belongs_to :provider, class_name: Health::Team::Member.name
    belongs_to :representative, class_name: Health::Team::Member.name

    serialize :service_archive, Array
    serialize :equipment_archive, Array

    validates_presence_of :provider_id, if: -> { self.provider_signed_on.present? }

    # Scopes
    scope :locked, -> do
      where(locked: true)
    end 
    scope :editable, -> do
      where(locked: false)
    end

    scope :approved, -> do
      where(status: :approved)
    end
    scope :rejected, -> do
      where(status: :rejected)
    end
    scope :sorted, -> do
      order(updated_at: :desc)
    end
    # End Scopes 

    def editable?
      ! locked
    end

    def ensure_team_exists
      if team.blank?
        create_team!(patient: patient, editor: user)
      end
    end

    def import_team_members
      potential_team = patient.epic_team_members.unprocessed.to_a
      return unless potential_team.any?
      potential_team.each do |epic_member|
        if epic_member.name.include?(',')
          (last_name, first_name) = epic_member.name.split(', ', 2)
        else
          (first_name, last_name) = epic_member.name.split(' ', 2)
        end
        user = User.find_by(email: 'noreply@greenriver.com')
        # Use the PCP type if we have it
        relationship = epic_member.pcp_type || epic_member.relationship
        member = Health::Team::Member.class_from_member_type_name(relationship).new(
            team: team, 
            user_id: user.id,
            first_name: first_name,
            last_name: last_name,
            title: epic_member.relationship,
            email: epic_member.email,
            phone: epic_member.phone,
            organization: epic_member.email&.split('@')&.last || 'Unknown'
          )
        member.save(validate: false)
        epic_member.update(processed: Time.now)
      end
    end

    def just_signed?
      self.patient_signed_on.present? && self.patient_signed_on_changed? || 
      self.provider_signed_on.present? && self.provider_signed_on_changed?
    end

    def set_lock
      if self.patient_signed_on.present? && self.provider_signed_on.present?
        self.locked = true
        archive_services
        archive_equipment
      else
        self.locked = false
      end
      self.save
    end

    def archive_services
      self.service_archive = self.services.map(&:attributes)
    end

    def archive_equipment
      self.equipment_archive = self.equipments.map(&:attributes)
    end

    def revise!
      original_team = self.team
      original_team_members = self.team_members
      original_goals = self.goals

      new_careplan = self.class.new(revsion_attributes)
      self.class.transaction do
        new_careplan.locked = false
        new_careplan.save!
        team_attrs = original_team.attributes.except('id')
        team_attrs['careplan_id'] = new_careplan.id
        new_team = original_team.class.create(team_attrs)
        
        original_team_members.each do |member|
          member_attrs = member.attributes.except('id')
          member_attrs['team_id'] = new_team.id
          new_team_members = member.class.create(member_attrs)
        end
        original_goals.each do |goal|
          goal_attr = goal.attributes.except('id')
          goal_attr[:careplan_id] = new_careplan.id
          new_goal = goal.class.create(goal_attr)
        end
      end
      return new_careplan.id
    end

    def revsion_attributes
      attributes = self.attributes.except('id', 'patient_signed_on', 'responsible_team_member_signed_on', 'representative_signed_on', 'provider_signed_on')
      attributes['initial_date'] = Date.today
      attributes['review_date'] = Date.today + 6.months
      return attributes
    end
  end
end