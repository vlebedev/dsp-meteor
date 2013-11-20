class @ViewController extends AppController

htmlEscape = (str) ->
    return String(str).replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/'/g, '&#39;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

Template.viewCreative.creative = ->
    Creatives.findOne { CreativeNmb: Session.get 'view_creative' }

Template.viewCreative.macros = ->
    _.sortBy Creatives.findOne({ CreativeNmb: Session.get 'view_creative' })?.Macros, 'MacrosTypeNmb'

Template.viewCreative.geolocs = ->
    _.sortBy Creatives.findOne({ CreativeNmb: Session.get 'view_creative' })?.GeoLocs, 'Name'

Template.viewCreative.sites = ->
    _.sortBy Creatives.findOne({ CreativeNmb: Session.get 'view_creative' })?.Sites, 'Name'

Template.viewCreative.articles = ->
    _.sortBy Creatives.findOne({ CreativeNmb: Session.get 'view_creative' })?.Articles, 'Name'

Template.viewCreative.brands = ->
    _.sortBy Creatives.findOne({ CreativeNmb: Session.get 'view_creative' })?.Brands, 'Name'

Template.viewCreative.helpers

    isStatus: (nmb) ->
        return @Moderation.StatusNmb == Number(nmb)

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

    Value: ->
        if @MacrosTypeNmb == 2
            fname = Files.findOne({ FileNmb: Number(@Value) })?.FileName
            return "#{fname} (#{@Value})"
        else
            return @Value

Template.viewCreative.events

    'click .button-edit-creative-js': (e) ->
        nmb = Session.get 'view_creative'
        Router.go "/creative/edit/#{nmb}"

    'click .button-submit-creative-js': (e) ->
        nmb = Session.get 'view_creative'
        Meteor.call 'requestCreativeModeration', nmb, (error, result) ->
            Meteor.call 'refreshCreative', nmb, (error, result) ->
                CoffeeAlerts.success "Moderation has been requested for creative #{nmb}."

    'click .button-refresh-creative-js': (e) ->
        nmb = Session.get 'view_creative'
        Meteor.call 'refreshCreative', nmb

    'click .button-reqedit-creative-js': (e) ->
        nmb = Session.get 'view_creative'
        Meteor.call 'requestCreativeEdit', nmb, (error, result) ->
            Meteor.call 'refreshCreative', nmb