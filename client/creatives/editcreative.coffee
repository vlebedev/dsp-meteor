class @EditController extends AppController

    before: ->
        cnmb = Session.get 'edit_creative'
        c = Creatives.findOne({ CreativeNmb: cnmb })
        if c.Moderation.StatusNmb != 1
            @redirect "/creative/view/#{cnmb}"
        super

Template.editCreative.currentCreative = ->
    Session.get 'edit_creative'

Template.editCreative.creativeName = ->
    cnmb = Session.get 'edit_creative'
    Creatives.findOne({ CreativeNmb: cnmb })?.CreativeName

Template.editCreative.showSuccess = ->
    Session.get 'show_success'

Template.editCreative.disabled_pill = ->
    if Session.get('edit_creative') == 0 then 'disabled' else ''

Template.editCreative.helpers

    isStatus: (nmb) ->
        cnmb = Session.get 'edit_creative'
        c = Creatives.findOne({ CreativeNmb: cnmb })
        return c.Moderation.StatusNmb == Number(nmb)

Template.editCreative.events

    'click .alert-close-success-js': (e) ->
        Session.set 'show_success', false

    'click .button-view-creative-js': (e) ->
        nmb = Session.get 'edit_creative'
        Router.go "/creative/view/#{nmb}"

    'click .button-submit-creative-js': (e) ->
        nmb = Session.get 'edit_creative'
        Meteor.call 'requestCreativeModeration', nmb, (error, result) ->
            Meteror.call 'refreshCreative', nmb, (error, result) ->
                Router.go "/creative/view/#{nmb}"
                CoffeeAlerts.success "Moderation has been requested for creative #{nmb}."

    'click .button-reqedit-creative-js': (e) ->
        nmb = Session.get 'edit_creative'
        Meteor.call 'requestCreativeEdit', nmb, (error, result) ->
            Meteor.call 'refreshCreative', nmb