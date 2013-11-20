Template.articles.articles = ->
    return Creatives.findOne({ CreativeNmb: Session.get('edit_creative') })?.Articles

Template.articles.rendered = ->

    $(".targeting-articles-typeahead-js").typeahead

        items: 11

        minLength: 1

        source: (query, process) ->
            safe = @query.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1")
            Meteor.call 'dictSearch', 'articles', safe, (err, res) ->
                process res

        matcher: (item) ->
            safe = @query.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1")
            r = new RegExp ".*#{safe}.*", 'i'
            return r.test(safe) || item.indexOf('...and') != -1

        updater: (item) ->
            if item.indexOf('...and') == -1 then item else ''


Template.articles.events

    'click .targeting-articles-add-js': (e) ->
        item = $('.targeting-articles-typeahead-js').val()
        cnmb = Session.get('edit_creative')
        r = new RegExp "^.*\\((-*\\d+)\\)$"

        if r.test(item)
            [_, nmb] = r.exec(item)
            nmb = parseInt(nmb)
            Meteor.call 'updateArticlesList', cnmb, nmb, false

    'click .targeting-articles-remove-js': (e) ->
        cnmb = Session.get('edit_creative')
        Meteor.call 'updateArticlesList', cnmb, @Nmb, true

    'click .targeting-articles-update-js': (e) ->
        cnmb = Session.get('edit_creative')
        Meteor.call 'updateArticlesList', cnmb, 0, false, (err, res) ->
            CoffeeAlerts.success "Creative's TNS Articles have been succefully updated!"
