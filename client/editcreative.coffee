class @EditController extends AppController

Template.editCreative.currentCreative = ->
    Session.get 'edit_creative'

Template.editCreative.showSuccess = ->
    Session.get 'show_success'

Template.editCreative.events

    'click .alert-close-success-js': (e) ->
        Session.set 'show_success', false