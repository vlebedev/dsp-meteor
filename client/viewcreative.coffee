Template.viewCreative.creative = ->
    Creatives.findOne { CreativeNmb: Session.get 'view_creative' }

htmlEscape = (str) ->
    return String(str).replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/'/g, '&#39;').replace(/</g, '&lt;').replace(/>/g, '&gt;')

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
            else "Unknown (#{@Moderation?.StatusNmb})"

    FmtDate: (d) ->
        if !d
            return ''
        else
            return moment(d).format("YYYY-MM-DD HH:mm:ss")

    Advertiser: ->
        a = Advertisers.findOne { nmb: @TnsAdvertiserNmb }
        if !!a
            return a.name
        else
            Meteor.call 'getAdvertiserName', @TnsAdvertiserNmb, (error, result) =>
                Advertisers.insert { nmb: @TnsAdvertiserNmb, name: result }

    Template: ->
        n = RTBTemplate.findOne({ nmb: @TemplateNmb })?.name
        return "#{n} (#{@TemplateNmb})"