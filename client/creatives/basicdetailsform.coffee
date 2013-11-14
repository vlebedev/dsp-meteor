Template.basicDetailsForm.CreativesCollection = ->
    return Creatives

Template.basicDetailsForm.selectedCreative = ->
    return Creatives.findOne { CreativeNmb: Session.get 'edit_creative' }

Template.basicDetailsForm.rendered = ->

    for d in ['advertiser', 'template']
        do (d) ->
            $(".#{d}-basic-typeahead-js").typeahead

                items: 11

                minLength: 1

                source: (query, process) ->
                    safe = @query.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1")
                    Meteor.call 'dictSearch', "#{d}s", safe, (err, res) ->
                        process res

                matcher: (item) ->
                    safe = @query.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1")
                    r = new RegExp ".*#{safe}.*", 'i'
                    return r.test(safe) || item.indexOf('...and') != -1

                updater: (item) ->
                    if item.indexOf('...and') == -1
                        r = new RegExp "^.*\\((\\d+)\\)$"
                        if r.test(item)
                            nmb = parseInt(r.exec(item)[1])
                            $("##{d}-basic-js").val(nmb) if !!nmb
                        return item
                    else
                        return ""

            x = parseInt($("##{d}-basic-js").val())

            if !!x
                switch d
                    when 'advertiser'
                        n = GetAdvertiserName x
                        if !!n
                            $(".#{d}-basic-typeahead-js").val("#{n} (#{x})")
                        else
                            setTimeout(
                                ->
                                    n = Advertisers.findOne({ Nmb: x }).Name
                                    $(".#{d}-basic-typeahead-js").val("#{n} (#{x})")
                            , 1000
                            )
                    when 'template'
                        n = BS_Templates.findOne({ Nmb: x }).Name
                        $(".#{d}-basic-typeahead-js").val("#{n} (#{x})")

Template.basicDetailsForm.events

    'reset form': (event, template) ->
        for d in ['advertiser', 'template']
            do (d) ->
                $(template.find(".#{d}-basic-typeahead-js")).val('')
                $(template.find("##{d}-basic-js")).val('')
