module CohortColumns
  class Chronic < Base
    attribute :column, Boolean, lazy: true, default: :chronic
    attribute :title, String, lazy: true, default: 'On Previous Chronic List'

    def default_input_type
      :radio_buttons
    end

    def available_options
      ['yes', 'no']
    end
  end
end