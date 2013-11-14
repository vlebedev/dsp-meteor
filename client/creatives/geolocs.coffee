Template.geolocs.geolocs = ->
    return Creatives.findOne({ CreativeNmb: Session.get('edit_creative') })?.GeoLocs

Template.geolocs.geolocs_exclude_checked = ->
    if Creatives.findOne({ CreativeNmb: Session.get('edit_creative') })?.GeoLocsExclude then 'checked="checked"' else ''

Template.geolocs.rendered = ->

    $(".targeting-geolocs-typeahead-js").typeahead

        items: 11

        minLength: 1

        source: (query, process) ->
            safe = @query.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1")
            Meteor.call 'dictSearch', 'geolocs', safe, (err, res) ->
                process res

        matcher: (item) ->
            safe = @query.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1")
            r = new RegExp ".*#{safe}.*", 'i'
            return r.test(safe) || item.indexOf('...and') != -1

        updater: (item) ->
            if item.indexOf('...and') == -1 then item else ''


Template.geolocs.events

    'click .targeting-geolocs-add-js': (e) ->
        item = $('.targeting-geolocs-typeahead-js').val()
        cnmb = Session.get('edit_creative')
        r = new RegExp "^.*\\((\\d+)\\)$"

        if r.test(item)
            [_, nmb] = r.exec(item)
            nmb = parseInt(nmb)
            Meteor.call 'updateGeoLocsList', cnmb, nmb, null

    'click .targeting-geolocs-remove-js': (e) ->
        nmb = -@Nmb
        cnmb = Session.get('edit_creative')
        Meteor.call 'updateGeoLocsList', cnmb, nmb, null

    'click .targeting-geolocs-update-js': (e) ->
        excl = $('.targeting-geolocs-exclude-js').prop('checked')
        cnmb = Session.get('edit_creative')
        Meteor.call 'updateGeoLocsList', cnmb, 0, excl, (err, res) ->
            CoffeeAlerts.success "Creative's Geo Locations have been succefully updated!"
