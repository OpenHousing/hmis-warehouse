module CohortColumns
  class OpenEnrollments < ReadOnly
    include ArelHelper
    attribute :column, String, lazy: true, default: :open_enrollments
    attribute :title, String, lazy: true, default: 'Open Residential Enrollments'

    def column_editable?
      false
    end

    def default_input_type
      :enrollment_tag
    end

    def renderer
      'html'
    end

    def value(cohort_client) # OK
      cohort_client.client.processed_service_history&.open_enrollments
    end

    def text_value cohort_client
      value(cohort_client).map(&:last).join(' ')
    end

    def display_for user
      display_read_only(user)
    end

    def display_read_only user
      value(cohort_client).map do |project_type, text|
        content_tag(:div, class: "enrollment__project_type client__service_type_#{project_type}") do
          content_tag(:em, class: 'service-type__program-type') do
            text
          end
        end
      end.join(' ').html_safe
    end
  end
end
