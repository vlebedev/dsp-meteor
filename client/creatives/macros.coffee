Template.macros.macros = ->
    BS_Macros.find {}

Template.macros.events

    'click .macros-add-js': (e) ->
        item = $('.macros-selected-js').val()
        cnmb = Session.get('edit_creative')
        r = new RegExp "^(.*)\ \\((\\d+)\\)$"

        if r.test(item)
            [_, name, nmb] = r.exec(item)
            nmb = parseInt(nmb)
            Meteor.call 'updateMacros', cnmb, nmb, value, (err, result) ->
                CoffeeAlerts.success "Macros #{name} (#{nmb}) has been succefully updated!"

    'click .macros-remove-js': (e) ->
        nmb = -@Nmb
        cnmb = Session.get('edit_creative')
        Meteor.call 'updateBrandsList', cnmb, nmb, (err, result) ->
                CoffeeAlerts.success "Macros #{nmb} has been removed from the creative!"

    'click .macros-choose-js': (e) ->
        Session.set 'macros_nmb', @Nmb
        $('.macros-button-js').html("#{@Name} (#{@Nmb}) <span class='caret'></span>")
