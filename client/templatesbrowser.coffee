Template.templatesBrowser.preserve ['.template-picker-js']

Template.templatesBrowser.templates = ->
    RTBTemplate.find {}

Template.templatesBrowser.count = ->
    RTBTemplate.find({}).count()

Template.templatesBrowser.sel_data = ->
    nmb = Session.get 'template_nmb'
    if !!nmb
        return RTBTemplate.findOne({nmb: nmb})?.data
    else
        ''
Template.templatesBrowser.sel_name = ->
    nmb = Session.get 'template_nmb'
    if !!nmb
        return RTBTemplate.findOne({nmb: nmb})?.name
    else
        ''

Template.templatesBrowser.sel_enabled = ->
    nmb = Session.get 'template_nmb'
    if !!nmb
        return RTBTemplate.findOne({nmb: nmb})?.isenabled
    else
        ''

Template.templatesBrowser.sel_approved = ->
    nmb = Session.get 'template_nmb'
    if !!nmb
        return RTBTemplate.findOne({nmb: nmb})?.isapproved
    else
        ''

Template.templatesBrowser.events =
    'change .template-picker-js': (e) ->
        Session.set 'template_nmb', parseInt $(e.target).val()
