Handlebars.registerHelper "isSelected", (name) ->
        if name == Router.current().template then 'active' else ''

