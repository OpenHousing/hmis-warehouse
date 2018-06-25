
$(document).on 'change', '.ssm-form', (e) ->
  form = $(e.target).closest('form')
  $.ajax
    url: form.data('url'),
    type: 'PATCH',
    data: form.serialize()
  .done (e) ->
    console.log 'done'
  .fail (e) ->
    console.log 'fail'