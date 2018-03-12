module CohortColumns
  class Notes < Base
    attribute :column, String, lazy: true, default: :notes
    attribute :title, String, lazy: true, default: 'Notes'
    

    def column_editable?
      false
    end

    def default_input_type
      :notes
    end

    def value(cohort_client)
      nil
    end

    def display_for user
      display_read_only(user)
    end

    def renderer
      'html'
    end

    def comments
      cohort_client.cohort_client_notes.reverse.map do |note|
        "#{note.note} -- #{note.user.name} on #{note.updated_at.to_date}"
      end.join('; ').html_safe
    end

    def display_read_only user
      note_count = cohort_client.cohort_client_notes.length
      path = cohort_cohort_client_cohort_client_notes_path(cohort, cohort_client)
      link_to note_count, path, class: 'badge', data: {loads_in_pjax_modal: true, cohort_client_id: cohort_client.id, column: column}
    end
  end
end
