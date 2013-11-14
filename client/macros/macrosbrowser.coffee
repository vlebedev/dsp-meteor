class @MacrosController extends AppController

Template.macrosBrowser.macros = ->
    BS_Macros.find {}

Template.macrosBrowser.count = ->
    BS_Macros.find({}).count()

Template.macrosBrowser.selected = ->
    nmb = Session.get 'macros_nmb'
    return BS_Macros.findOne({ Nmb: nmb })

Template.macrosBrowser.Type = ->
    switch @MacrosTypeNmb
        when 1
            "type 1, any value"
        when 2
            "type 2, media file number (will be substituted with CDN URL)"
        when 3
            "type 3, advertiser link"
        when 4
            "type 4, statistics link"
        when 5
            "type 5, dynamic macros"

Template.macrosBrowser.events =
    'click .link-macros-chooser-js': (e) ->
        Session.set 'macros_nmb', @Nmb
        $('.namenmb-macros-js').val("#{@Name} (#{@Nmb})")
