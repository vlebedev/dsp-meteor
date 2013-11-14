class @EditController extends AppController

Template.editCreative.currentCreative = ->
    Session.get 'edit_creative'

Template.editCreative.showSuccess = ->
    Session.get 'show_success'

Template.editCreative.disabled_pill = ->
    if Session.get('edit_creative') == 0 then 'disabled' else ''

Template.editCreative.events

    'click .alert-close-success-js': (e) ->
        Session.set 'show_success', false