Router.configure
    layoutTemplate: 'layout'

Router.map ->
    @route 'creatives', { path: '/', template: 'creativesBrowser' }
    @route 'templates', { path: '/templates', template: 'templatesBrowser' }
    @route 'files', { path: '/files', template: 'filesBrowser' }
    @route 'creative/:nmb/view',
        template: "creativeViewer"
        before: ->
            Session.set 'current_creative', @params.nmb

Deps.autorun ->
    Meteor.subscribe 'template'
    Meteor.subscribe 'creatives'
    Meteor.subscribe 'rtbfiles'

Meteor.startup ->
    Session.setDefault 'template_nmb', 1
    Session.setDefault 'show_spinner', false
    Session.setDefault 'show_alert_creatives', false
    Session.setDefault 'show_alert_files_uploaded', false
    Session.setDefault 'show_alert_files_synced', false
    Session.setDefault 'show_upload', false
    Session.setDefault 'current_creative', null
