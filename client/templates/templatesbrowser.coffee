class @TemplatesController extends AppController

Template.templatesBrowser.templates = ->
    BS_Templates.find {}

Template.templatesBrowser.count = ->
    BS_Templates.find({}).count()

Template.templatesBrowser.isSelected = ->
    return if @Nmb == Session.get 'template_nmb' then 'active' else ''

Template.templatesBrowser.selected = ->
    nmb = Session.get 'template_nmb'
    return BS_Templates.findOne({ Nmb: nmb })

Template.templatesBrowser.selectedName = ->
    nmb = Session.get 'template_nmb'
    t = BS_Templates.findOne({ Nmb: nmb })
    return "#{t.Name} (#{t.Nmb})"

Template.templatesBrowser.events =
    'click .link-template-chooser-js': (e) ->
        Session.set 'template_nmb', @Nmb
        console.log @Name
        $('.template-name-js').html()
