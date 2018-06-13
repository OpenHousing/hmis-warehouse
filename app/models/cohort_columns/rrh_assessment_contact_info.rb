module CohortColumns
  class RrhAssessmentContactInfo < ReadOnly
    attribute :column, String, lazy: true, default: :rrh_assessment_contact_info
    attribute :title, String, lazy: true, default: 'RRH Income Maximization Contact'
    
    def renderer
      'html'
    end

    def value(cohort_client)
      cohort_client.client.contact_info_for_rrh_assessment if cohort_client.client.consent_form_valid?
    end

    def text_value cohort_client
      strip_tags value(cohort_client)
    end
  end
end
