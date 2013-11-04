Store = new BannerStore
    host: process.env.YANDEX_BANNERSTORE_HOST
    port: process.env.YANDEX_BANNERSTORE_PORT
    login: process.env.YANDEX_BANNERSTORE_LOGIN
    password: process.env.YANDEX_BANNERSTORE_PASSWORD

Geo = new Meteor.Collection 'geo'
Site = new Meteor.Collection 'site'
Advertiser = new Meteor.Collection 'tnsadvertiser'
TNSArticle = new Meteor.Collection 'tnsarticle'
TNSBrand = new Meteor.Collection 'tnsbrand'
Template = new Meteor.Collection 'template'
Macros = new Meteor.Collection 'macros'

DictColls =
    "geo": Geo
    "site": Site
    "advertiser": Advertiser
    "tnsarticle": TNSArticle
    "tnsbrand": TNSBrand
    "template": Template
    "macros": Macros

Meteor.methods

    'dictSearch': (dict, query) ->
        num = new RegExp "^\\d+$"

        return [] unless !!DictColls[dict]

        if num.test(query)
            res = DictColls[dict].findOne({ nmb: parseInt(query) })
            if res
                return ["#{res.name} (#{res.nmb})"]
            else
                return []
        else
            total_found = DictColls[dict].find({ name: { $regex: ".*#{query}.*", $options: 'ui' } }).count()
            if !!total_found
                res = DictColls[dict].find({ name: { $regex: ".*#{query}.*", $options: 'ui' } }, { limit: 7 })?.fetch()
                if res
                    res = _.map(res, (x) -> "#{x.name} (#{x.nmb})")
                    if total_found > 7
                        res.push "<i>...и еще <strong>#{total_found-7}</strong> результатов</i>", ""
                    return res
            return []

    # Form support methods

    'newCreative': (c) ->
        check c, Schema.newCreative

        boundFn = Meteor.bindEnvironment (error, result) ->
            if error
                console.log 'newCreative method:CREATECREATIVE:ERROR: ', err
                throw error
            else
                _.extend c,
                    CreativeNmb: result
                console.log 'method:newCreative:INFO:CREATEDOK: ', c.CreativeNmb
                Creatives.insert c, (err, res) ->
                    if err
                        console.log 'method:newCreative:ERROR:INSERT: ', err
                        console.log 'method:newCreative:ERROR:INVALID KEYS: ', Creatives.namedContext("default").invalidKeys()
                        throw err
                    return
            return
        , (e) ->
            throw e

        Store.createCreative c, boundFn
