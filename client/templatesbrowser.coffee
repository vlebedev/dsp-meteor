Template.templatesBrowser.preserve ['.template-picker-js']

Template.templatesBrowser.templates = ->
    RTBTemplate.find {}

Template.templatesBrowser.count = ->
    RTBTemplate.find({}).count()

Template.templatesBrowser.isSelected = ->
    return if @nmb == Session.get 'template_nmb' then 'active' else ''

Template.templatesBrowser.selected = ->
    nmb = Session.get 'template_nmb'
    return RTBTemplate.findOne({ nmb: nmb })

Template.templatesBrowser.events =
    'click .link-template-chooser-js': (e) ->
        Session.set 'template_nmb', @nmb
