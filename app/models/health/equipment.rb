module Health
  class Equipment < HealthBase
    
    acts_as_paranoid

    has_many :careplans
    belongs_to :patient, required: true

    validates_presence_of :item 
    validates :quantity, numericality: { only_integer: true, allow_blank: true }
    def self.available_items
      [ 
        'Diapers',
        'Pullups',
        'Liners',
        'Disposable Under pad /Chux',
        'Reusable bed size pad',
        'Reusable chair pad',
        'Enteral and Parenteral Formula',
        'Hearing Aid Batteries',
        'Prosthetics, Orthotics, and Orthopedic Footwear',
        'Other',
      ]
    end

  end
end