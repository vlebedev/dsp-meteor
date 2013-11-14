Template.sites.sites = ->
    return Creatives.findOne({ CreativeNmb: Session.get('edit_creative') })?.Sites

Template.sites.sites_exclude_checked = ->
    if Creatives.findOne({ CreativeNmb: Session.get('edit_creative') })?.SitesExclude then 'checked="checked"' else ''

Template.sites.rendered = ->

    $(".targeting-sites-typeahead-js").typeahead

        items: 11

        minLength: 1

        source: (query, process) ->
            safe = @query.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1")
            Meteor.call 'dictSearch', 'sites', safe, (err, res) ->
                process res

        matcher: (item) ->
            safe = @query.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1")
            r = new RegExp ".*#{safe}.*", 'i'
            return r.test(safe) || item.indexOf('...and') != -1

        updater: (item) ->
            if item.indexOf('...and') == -1 then item else ''


Template.sites.events

    'click .targeting-sites-add-js': (e) ->
        item = $('.targeting-sites-typeahead-js').val()
        cnmb = Session.get('edit_creative')
        r = new RegExp "^.*\\((\\d+)\\)$"

        if r.test(item)
            [_, nmb] = r.exec(item)
            nmb = parseInt(nmb)
            Meteor.call 'updateSitesList', cnmb, nmb, null

    'click .targeting-sites-remove-js': (e) ->
        nmb = -@Nmb
        cnmb = Session.get('edit_creative')
        Meteor.call 'updateSitesList', cnmb, nmb, null

    'click .targeting-sites-update-js': (e) ->
        excl = $('.targeting-sites-exclude-js').prop('checked')
        cnmb = Session.get('edit_creative')
        Meteor.call 'updateSitesList', cnmb, 0, excl, (err, res) ->
            CoffeeAlerts.success "Creative's Sites have been succefully updated!"
