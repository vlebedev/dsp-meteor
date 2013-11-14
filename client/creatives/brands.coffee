Template.brands.brands = ->
    return Creatives.findOne({ CreativeNmb: Session.get('edit_creative') })?.Brands

Template.brands.rendered = ->

    $(".targeting-brands-typeahead-js").typeahead

        items: 11

        minLength: 1

        source: (query, process) ->
            safe = @query.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1")
            Meteor.call 'dictSearch', 'brands', safe, (err, res) ->
                process res

        matcher: (item) ->
            safe = @query.replace(/([.*+?^=!:${}()|\[\]\/\\])/g, "\\$1")
            r = new RegExp ".*#{safe}.*", 'i'
            return r.test(safe) || item.indexOf('...and') != -1

        updater: (item) ->
            if item.indexOf('...and') == -1 then item else ''


Template.brands.events

    'click .targeting-brands-add-js': (e) ->
        item = $('.targeting-brands-typeahead-js').val()
        cnmb = Session.get('edit_creative')
        r = new RegExp "^.*\\((\\d+)\\)$"

        if r.test(item)
            [_, nmb] = r.exec(item)
            nmb = parseInt(nmb)
            Meteor.call 'updateBrandsList', cnmb, nmb

    'click .targeting-brands-remove-js': (e) ->
        nmb = -@Nmb
        cnmb = Session.get('edit_creative')
        Meteor.call 'updateBrandsList', cnmb, nmb

    'click .targeting-brands-update-js': (e) ->
        cnmb = Session.get('edit_creative')
        Meteor.call 'updateBrandsList', cnmb, 0, (err, res) ->
            CoffeeAlerts.success "Creative's TNS Brands have been succefully updated!"
