Template.macros.macros = ->
    cnmb = Session.get('edit_creative')
    list = Creatives.findOne({ CreativeNmb: cnmb })?.Macros
    if !list
        Meteor.call 'refreshCreativeMacros', cnmb
        return []
    # filter out deprecated dynamic macros, then sort by macros type
    return _.sortBy(_.filter(list, (x) -> x.MacrosTypeNmb != 5), 'MacrosTypeNmb')

Template.macros.helpers

    template_data: ->
        return Creatives.findOne(
            { CreativeNmb: Session.get('edit_creative') }
        )?.TemplateData

Template.macros.events

    'click .macros-update-js': (e) ->
        cnmb = Session.get('edit_creative')
        mlist = Creatives.findOne({ CreativeNmb: cnmb })?.Macros

        if mlist
            normal = []
            dynamic = []
            _.each mlist, (m) ->
                obj =
                    CreativeNmb: cnmb
                    MacrosNmb: m.Nmb
                    Value: $("#macros-#{m.Nmb}").val()

                mtype = m.MacrosTypeNmb
                switch
                    when (mtype == 1) || (mtype == 3) || (mtype == 4)
                        normal.push obj
                    when (mtype == 2) && !!obj.Value
                        normal.push obj
                    # dynamic macros are deprecated by Yandex
                    when (mtype == 5) && !!obj.Value
                        dynamic.push obj

        if !!normal
            Meteor.call 'updateCreativeMacros', normal,
                (error, result) ->
                    if error
                        CoffeeAlerts.error 'Error: '+error.message
                    else
                        CoffeeAlerts.success "Macros have been succefully updated!"

Template.macros.rendered = ->
    cnmb = Session.get 'edit_creative'
    ml = Creatives.findOne({ CreativeNmb: cnmb })?.Macros
    $('.select2').select2()
    _.each ml, (m) ->
        if m.MacrosTypeNmb == 2
            $("#macros-#{m.Nmb}").val(m.Value).trigger('change')

Template.macroinput.files = ->
    Files.find {}

Template.macroinput.helpers

    isType: (n) ->
        return @MacrosTypeNmb == n

    placeholder: ->
        switch @MacrosTypeNmb
            when 1
                return 'Enter value...'
            when 2
                return 'Choose a file...'
            when 3
                return 'Enter advertiser URL...'
            when 4
                return 'Enter analytics URL...'
            when 5
                return 'Choose files...'
            else
                return ''

