class @CreativesController extends AppController

Template.creativesBrowser.creatives = ->
    Creatives.find {}, { sort: { CreativeNmb: -1 } }

Template.creativesBrowser.helpers
    show_spinner: ->
        Session.get 'show_spinner'

    show_alert: ->
        Session.get 'show_alert_creatives'

Template.creativesBrowser.events
    'click .button-new-creative-js': (e) ->
        Session.set 'currentCreative', null
        Router.go '/creative/edit/0'

    'click .button-refresh-creatives-js': (e) ->
        Session.set 'show_spinner', true
        Session.set 'show_alert_creatives', false
        Meteor.call 'refreshCreatives', (error, result) ->
            Session.set 'show_spinner', false
            Session.set 'show_alert_creatives', true
            Deps.flush()

    'click .alert-close-creatives-js': (e) ->
            Session.set 'show_alert_creatives', false

Template.creative.helpers

    isStatus: (nmb) ->
        return @Moderation.StatusNmb == Number(nmb)

    Status: ->
        switch @Moderation?.StatusNmb
            when undefined, 1 then 'Draft (1)'
            when 2 then 'Approval in progress (2)'
            when 3 then 'Rejected (3)'
            when 4 then 'Accepted (4)'
            when 5 then 'Delayed (5)'
            when 6 then 'Confirmation needed (6)'
            else "Unknown (#{@Moderation?.StatusNmb})"

    ExpireDate: ->
        return moment(@ExpireDate).format("YYYY-MM-DD HH:mm:ss")

    Advertiser: ->
        n = GetAdvertiserName @TnsAdvertiserNmb
        return "#{n} (#{@TnsAdvertiserNmb})"

    Template: ->
        n = BS_Templates.findOne({ Nmb: @TemplateNmb })?.Name
        return "#{n} (#{@TemplateNmb})"
