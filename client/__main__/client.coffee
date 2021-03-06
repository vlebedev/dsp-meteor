@Advertisers = new Meteor.Collection null

Router.configure
    layoutTemplate: 'layout'
    notFoundTemplate: '404'
    loadingTemplate: 'loading'
    yieldTemplates:
        header:
            to: 'header'

Router.map ->

    @route 'home',      path: '/',          template: 'home'
    @route 'dashboard', path: '/dashboard', template: 'dashboard'
    @route 'creatives', path: '/creatives', template: 'creativesBrowser'
    @route 'templates', path: '/templates', template: 'templatesBrowser'
    @route 'macros',    path: '/macros',    template: 'macrosBrowser'
    @route 'files',     path: '/files',     template: 'filesBrowser'

    @route 'creative/edit/:nmb',
        template: 'editCreative'
        controller: 'EditController'
        before: ->
            Session.set 'edit_creative', parseInt(@params.nmb)

    @route 'creative/view/:nmb',
        template: 'viewCreative'
        controller: 'ViewController'
        before: ->
            Session.set 'view_creative', parseInt(@params.nmb)

class @AppController extends RouteController

    before: ->
        if _.isNull Meteor.user()
            @redirect 'home'

    run: ->
        CoffeeAlerts.clearSeen()
        super

Handlebars.registerHelper "isSelected", (name) ->
    if name == Router.current().template then 'active' else ''

Deps.autorun ->
    Meteor.subscribe 'bs.templates'
    Meteor.subscribe 'bs.macros'
    Meteor.subscribe 'creatives'
    Meteor.subscribe 'rtbfiles'

Meteor.startup ->
    Session.setDefault 'template_nmb', 1
    Session.setDefault 'macros_nmb', 1
    Session.setDefault 'show_spinner', false
    Session.setDefault 'show_alert_creatives', false
    Session.setDefault 'show_alert_files_uploaded', false
    Session.setDefault 'show_alert_files_synced', false
    Session.setDefault 'show_upload', false
    Session.setDefault 'view_creative', null
    Session.setDefault 'edit_creative', null
    Session.setDefault 'show_success', false

    Accounts.ui.config
        passwordSignupFields: 'EMAIL_ONLY'




