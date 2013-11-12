Template.basicDetailsForm.CreativesCollection = ->
    return Creatives

Template.basicDetailsForm.selectedCreative = ->
    return Creatives.findOne { CreativeNmb: Session.get 'edit_creative' }

Creatives.callbacks
    update: (error, result) ->
        if error
            console.log "Creatives insert error: #{error}"
        else
            Meteor.call 'updateCreative', result.data._doc.CreativeNmb, (error, result) ->
                Session.set 'show_success', true

    insert: (error, result) ->
        if error
            console.log "Creatives insert error: #{error}"
        else
            Meteor.call 'newCreative', result, (err, res) ->
                console.log res
                Session.set 'show_success', true
                setTimeout(
                    ->
                        Router.go "/creative/edit/#{res}"
                , 100)

Creatives.beforeUpdate = (docId, doc) ->
    doc['$set'].TnsAdvertiserNmb = parseInt(doc['$set'].TnsAdvertiserNmb)
    doc['$set'].TemplateNmb = parseInt(doc['$set'].TemplateNmb)
    return doc

Creatives.beforeInsert = (doc) ->
    doc.TnsAdvertiserNmb = parseInt(doc.TnsAdvertiserNmb)
    doc.TemplateNmb = parseInt(doc.TemplateNmb)
    return doc

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
                    return r.test(safe) || item.indexOf('...и еще ') != -1

                updater: (item) ->
                    if item.indexOf('...и еще ') == -1
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
