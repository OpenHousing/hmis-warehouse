module CohortColumns
  class FirstDateHomeless < ReadOnly
    attribute :column, String, lazy: true, default: :first_date_homeless
    attribute :title, String, lazy: true, default: 'First Date Homeless'

    def date_format
      'll'
    end

    def renderer
      'date'
    end

    def value(cohort_client) # OK
      cohort_client.client.first_homeless_date&.to_date&.to_s
    end

  end
end
