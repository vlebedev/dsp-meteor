class @ViewController extends AppController

htmlEscape = (str) ->
    return String(str).replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/'/g, '&#39;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

Template.viewCreative.creative = ->
    Creatives.findOne { CreativeNmb: Session.get 'view_creative' }

Template.viewCreative.TemplateData = ->
    @TemplateData

Template.viewCreative.helpers

    FmtStatus: (nmb) ->
        switch nmb
            when undefined, 1 then 'Draft (1)'
            when 2 then 'Approval in progress (2)'
            when 3 then 'Rejected (3)'
            when 4 then 'Accepted (4)'
            when 5 then 'Delayed (5)'
            when 6 then 'Confirmation needed (6)'
            else "Unknown (#{nmb})"

    FmtDate: (d) ->
        if !d
            return ''
        else
            return moment(d).format("YYYY-MM-DD HH:mm:ss")

    Advertiser: ->
        a = Advertisers.findOne { Nmb: @TnsAdvertiserNmb }
        if !!a
            return a.Name
        else
            Meteor.call 'getAdvertiserName', @TnsAdvertiserNmb, (error, result) =>
                Advertisers.insert { Nmb: @TnsAdvertiserNmb, Name: result }

    Template: ->
        n = BS_Templates.findOne({ Nmb: @TemplateNmb })?.Name
        return "#{n} (#{@TemplateNmb})"

Template.viewCreative.events

    'click .button-edit-creative-js': (e) ->
        nmb = Session.get 'view_creative'
        Router.go "/creative/edit/#{nmb}"
