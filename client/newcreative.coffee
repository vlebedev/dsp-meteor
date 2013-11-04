newCreativeForm = new AutoForm Schema.newCreative

newCreativeForm.callbacks

    'newCreative': (error, result, template) ->

        if !error
            alert 'Креатив создан успешно'
        else
            alert "Ошибка создания креатива: #{error}"

newCreativeForm.beforeMethod = (doc, method) ->

    if method == 'newCreative'
        doc.TnsAdvertiserNmb = parseInt(doc.TnsAdvertiserNmb)
        doc.TemplateNmb = parseInt(doc.TemplateNmb)

    return doc

Template.newCreative.helpers

    newCreative: ->
        return newCreativeForm

Template.newCreative.rendered = ->

    for d in ['advertiser', 'template']
        do (d) ->
            $(".#{d}-newcreative-typeahead-js").typeahead

                items: 11

                minLength: 1

                source: (query, process) ->
                    safe = @query.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1")
                    Meteor.call 'dictSearch', d, safe, (err, res) ->
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
                            $("##{d}-newcreative").val(nmb) if !!nmb
                        return item
                    else
                        return ""

Template.newCreative.events

    'reset form': (event, template) ->
        for d in ['advertiser', 'template']
            do (d) ->
                $(template.find(".#{d}-newcreative-typeahead-js")).val('')
                $(template.find("##{d}-newcreative")).val('')

