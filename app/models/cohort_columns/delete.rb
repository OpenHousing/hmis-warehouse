module CohortColumns
  class Delete < Base
    include ArelHelper
    attribute :column, String, lazy: true, default: :delete
    attribute :title, String, lazy: true, default: 'Delete'

    def column_editable?
      false
    end

    def default_input_type
      :read_only
    end

    def renderer
      'html'
    end

    def value(cohort_client) # OK
      nil
    end

    def display_for user
      if user.can_manage_cohorts? || user.can_edit_cohort_clients?
        display_read_only(user)
      else
        ''
      end
    end

    def display_read_only user
      content_tag(:a, href: pre_destroy_cohort_cohort_client_path(cohort, cohort_client), class: "btn btn-danger btn-sm btn-icon-only", data: {loads_in_pjax_modal: true}) do
        content_tag(:i, '', class: 'icon-cross')
      end
    end
  end
end
