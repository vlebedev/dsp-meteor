fs = Meteor.require 'fs'
path = Meteor.require 'path'
constants = Meteor.require 'constants'
Buffer = Meteor.require('buffer').Buffer

## BannerStore client handler

Store = new BannerStore
    host: process.env.YANDEX_BANNERSTORE_HOST
    port: process.env.YANDEX_BANNERSTORE_PORT
    login: process.env.YANDEX_BANNERSTORE_LOGIN
    password: process.env.YANDEX_BANNERSTORE_PASSWORD

## Dictionaries

BS_Advertisers  = new Meteor.Collection 'bs.advertisers'
BS_Articles     = new Meteor.Collection 'bs.articles'
BS_Brands       = new Meteor.Collection 'bs.brands'
BS_GeoLocs      = new Meteor.Collection 'bs.geolocs'
BS_Sites        = new Meteor.Collection 'bs.sites'

Dictionaries =
    'advertisers':
        coll: BS_Advertisers
        method: 'GetTnsAdvertiser'
    'articles':
        coll: BS_Articles
        method: 'GetTnsArticle'
    'brands':
        coll: BS_Brands
        method: 'GetTnsBrand'
    'geolocs':
        coll: BS_GeoLocs
        method: 'GetGeo'
    'macros':
        coll: BS_Macros
        method: 'GetMacros'
    'sites':
        coll: BS_Sites
        method: 'GetSite'
    'templates':
        coll: BS_Templates
        method: 'GetTemplate'

## GridFS

FilesFS.allow
    insert: ->
        return true

    update: ->
        return true

    remove: ->
        return false

FilesFS.filter
    allow:
        contentTypes: ['image/*']

FilesFSHandler =
    'default1': (options) ->
        # console.log("default 1 options: ", options);
        return {
            blob: options.blob,
            fileRecord: options.fileRecord
        }

FilesFS.fileHandlers FilesFSHandler

Creatives.allow

    update: ->
        return true

    insert: ->
        return true

    remove: ->
        return false

Meteor.publish 'rtbfiles', ->
    return Files.find {}

Meteor.publish 'files', ->
    return FilesFS.find { complete: filter.completed },
        { _id: 1, filename: 1, handledAt: 1, metadata: 1 }

Meteor.publish 'bs.templates', ->
    return BS_Templates.find {}

Meteor.publish 'bs.macros', ->
    return BS_Macros.find {}

Meteor.publish 'creatives', ->
    return Creatives.find {}

## Helper functions, wrapped in Fibers
######################################

## Sync dict method call

dictMethodCallSync = Meteor._wrapAsync (m, cb) ->
    Store.dictMethodCall m, cb

## Sync method call with logon

methodCallSync = Meteor._wrapAsync (m, d, cb) ->
    Store.methodCall m, d, cb

## Creatives

createCreative = Meteor._wrapAsync (c, cb) ->
    Store.methodCall "CreateCreative", c, cb

getCreative = Meteor._wrapAsync (x, cb) ->
    switch typeof x
        when "number"
            Store.methodCall "GetCreativeByNmb", x, cb
        when "string"
            Store.methodCall "GetCreativeByTag", x, cb
        else
            cb null

getCreativeMacros = Meteor._wrapAsync (nmb, cb) ->
    Store.methodCall "GetCreativeMacros", nmb, cb

updateCreativeMacros = (list) ->
    return unless !!list

    boundFn = Meteor._wrapAsync (l, cb) ->
        async.each l,
            (item, callback) ->
                Store.methodCall 'UpdateCreativeMacros', item, callback
            , (error, result) =>
                cb && cb error

    try
        boundFn list
        refreshCreativeMacros list[0].CreativeNmb
    catch e
        throw new Meteor.Error(500, e.faultString, e)

updateCreativeDynamicMacros = (list) ->
    return unless !!list

    boundFn = Meteor._wrapAsync (l, cb) ->
        async.each l,
            (item, callback) ->
                Store.methodCall 'UpdateCreativeDynamicMacros', item, callback
            , (error, result) =>
                cb && cb error

    try
        boundFn list
        refreshCreativeMacros list[0].CreativeNmb
    catch e
        throw new Meteor.Error(500, e.faultString, e)

refreshCreativeMacros = (cnmb) ->
    c = Creatives.findOne { CreativeNmb: Number(cnmb) }

    if c
        defined_macros = methodCallSync 'GetCreativeMacros', cnmb
        # console.log defined_macros
    else
        throw new Meteor.Error(500, "Creative is not found: #{cnmb}")

    if c.TemplateData
        re = /[^\$]({\w+})/ig
        ml = []

        while found = re.exec c.TemplateData
            ml.push found[1].toLowerCase()

        ml = _.uniq ml
        ml = _.union(ml, _.pluck(defined_macros, 'MacrosName'))
        ml = ml.sort()
        arr = []

        if ml
            _.each ml, (name) ->
                macros = BS_Macros.findOne { Name: name }
                if macros
                    existing_macros = _.find defined_macros,
                        (m) -> m.MacrosNmb == macros.Nmb
                    if existing_macros
                        macros.Value = existing_macros.VALUE
                    else
                        macros.Value = ''
                    delete macros._id
                    arr.push macros
                else
                    console.log "Warning: unknown macros: #{name}"

        Creatives._collection.update c._id, { $set: { Macros: arr } }

## Files

# Upload file from GridFS to Yandex BannerStore
# The file is assumed to be already uploaded from
# client to GridFS
uploadFileToBS = Meteor._wrapAsync (id, cb) ->
    file = FilesFS.findOne(id)

    if file

        while !buffer # very dirty, but who cares?
            buffer = FilesFS.retrieveBuffer(file._id)

        data =
            CdnNmb: 2
            FileName: file.filename
            Bytes: buffer
            Tag: file.metadata.tag

        Store.methodCall 'UploadFile', data, cb
    else
        cb null

# MimeTypeNmb decoder
getContentType = (t) ->
    switch t
        when 1 then 'image/jpeg'
        when 2 then 'image/gif'
        when 3 then 'image/swf'
        when 4 then 'image/png'
        when 5 then 'video/x-flv'
        when 6 then 'audio/x-mp3'
        else 'text/plain'


## Meteor methods

Meteor.methods

    'dictSearch': (dict, query) ->
        num = new RegExp "^\\d+$"
        console.log query

        return [] unless !!Dictionaries[dict]

        if num.test(query)
            res = Dictionaries[dict].coll.findOne({ Nmb: parseInt(query) })
            if res
                return ["#{res.Name} (#{res.Nmb})"]
            else
                return []
        else
            total_found = Dictionaries[dict].coll.find(
                { Name: { $regex: ".*#{query}.*", $options: 'ui' } }
            ).count()
            if !!total_found
                res = Dictionaries[dict].coll.find(
                    { Name: { $regex: ".*#{query}.*", $options: 'ui' } },
                    { limit: 10 }
                )?.fetch()
                if res
                    res = _.map(res, (x) -> "#{x.Name} (#{x.Nmb})")
                    if total_found > 10
                        res.push "<i>...and <strong>#{total_found-10}"+
                          "</strong> more results</i>"
                    return res
            return []

    'getAdvertiserName': (nmb) ->
        BS_Advertisers.findOne({ Nmb: nmb })?.Name

    # Form support methods

    'newCreative': (id) ->
        c = Creatives.findOne { id }
        nmb = 0

        if c
            nmb = createCreative c
            nc = getCreative nmb
            Creatives._collection.update id, { $set: nc }

        return nmb

    'updateCreative': (nmb) ->
        c = Creatives.findOne { CreativeNmb: nmb }
        u =
            CreativeNmb: c.CreativeNmb
            CreativeName: c.CreativeName
            TnsAdvertiserNmb: c.TnsAdvertiserNmb
            TemplateNmb: c.TemplateNmb
            ExpireDate: c.ExpireDate
            Tag: c.Tag
            Note: c.Note
        Store.methodCall 'UpdateCreative', u
        return

    'updateGeoLocsList': (cnmb, nmb, rmflag, excl) ->
        creative = Creatives.findOne({ CreativeNmb: cnmb })

        throw new Error("Creative #{nmb} not exists") unless creative


        if nmb == 0
            Creatives._collection.update creative._id,
                { $set: { GeoLocsExclude: excl } }

        else if !rmflag
            name = BS_GeoLocs.findOne({ Nmb: nmb }).Name
            geo =
                Nmb: nmb
                Name: name

            if creative.GeoLocs
                excl = !!creative.GeoLocsExclude
                Creatives._collection.update creative._id,
                    { $addToSet: { GeoLocs: geo } }
            else
                excl = false
                Creatives._collection.update creative._id,
                    {
                        $push: { GeoLocs: geo },
                        $set: { GeoLocsExclude: false }
                    }

        else
            excl = !!creative.GeoLocsExclude
            name = BS_GeoLocs.findOne({ Nmb: nmb }).Name
            geo =
                Nmb: nmb
                Name: name
            Creatives._collection.update creative._id,
                { $pull: { GeoLocs: geo } }

        list = Creatives.findOne(creative._id).GeoLocs

        list = if list then _.pluck list, 'Nmb' else []

        geoLocs =
            CreativeNmb: cnmb
            GeoNmb: list
            Exclude: excl

        console.log geoLocs

        Store.methodCall 'UpdateCreativeGeo', geoLocs, (err, res) ->
            err && console.log err

    'updateSitesList': (cnmb, nmb, rmflag, excl) ->
        creative = Creatives.findOne({ CreativeNmb: cnmb })

        throw new Error "Creative #{nmb} not exists" unless creative

        if nmb == 0
            Creatives._collection.update creative._id,
                { $set: { SitesExclude: excl } }

        else if !rmflag
            name = BS_Sites.findOne({ Nmb: nmb }).Name
            site =
                Nmb: nmb
                Name: name

            if creative.Sites
                excl = !!creative.SitesExclude
                Creatives._collection.update creative._id,
                    { $addToSet: { Sites: site } }
            else
                excl = false
                Creatives._collection.update creative._id,
                    {
                        $push: { Sites: site },
                        $set: { SitesExclude: false }
                    }

        else
            excl = !!creative.SitesExclude
            name = BS_Sites.findOne({ Nmb: nmb }).Name
            site =
                Nmb: nmb
                Name: name
            Creatives._collection.update creative._id,
                { $pull: { Sites: site } }

        list = Creatives.findOne(creative._id).Sites

        list = if list then _.pluck list, 'Nmb' else []

        sites =
            CreativeNmb: cnmb
            SiteNmb: list
            Exclude: excl

        console.log sites

        Store.methodCall 'UpdateCreativeSite', sites, (err, res) ->
            err && console.log err

    'updateArticlesList': (cnmb, nmb, rmflag) ->
        creative = Creatives.findOne { CreativeNmb: cnmb }

        throw new Error "Creative #{nmb} not exists" unless creative

        if !!nmb

            if !rmflag
                name = BS_Articles.findOne({ Nmb: nmb })?.Name
                article =
                    Nmb: nmb
                    Name: name

                if creative.Articles

                    Creatives._collection.update creative._id,
                        { $addToSet: { Articles: article } }
                else
                    Creatives._collection.update creative._id,
                        { $push: { Articles: article } }

            else
                name = BS_Articles.findOne({ Nmb: nmb })?.Name
                article =
                    Nmb: nmb
                    Name: name
                Creatives._collection.update creative._id,
                    { $pull: { Articles: article } }

        list = Creatives.findOne(creative._id).Articles

        list = if list then _.pluck list, 'Nmb' else []

        articles =
            CreativeNmb: cnmb
            Article: list

        console.log articles

        Store.methodCall 'UpdateCreativeTnsArticle', articles, (err, res) ->
            err && console.log err

    'updateBrandsList': (cnmb, nmb, rmflag) ->
        creative = Creatives.findOne { CreativeNmb: cnmb }

        throw new Error "Creative #{nmb} not exists" unless creative

        if !!nmb

            if !rmflag
                name = BS_Brands.findOne({ Nmb: nmb }).Name
                brand =
                    Nmb: nmb
                    Name: name

                if creative.Brands
                    Creatives._collection.update creative._id,
                        { $addToSet: { Brands: brand } }
                else
                    Creatives._collection.update creative._id,
                        { $push: { Brands: brand } }

            else
                name = BS_Brands.findOne({ Nmb: nmb }).Name
                brand =
                    Nmb: nmb
                    Name: name
                Creatives._collection.update creative._id,
                    { $pull: { Brands: brand } }

        list = Creatives.findOne(creative._id).Brands

        list = if list then _.pluck list, 'Nmb' else []

        brands =
            CreativeNmb: cnmb
            Brand: list

        console.log brands

        Store.methodCall 'UpdateCreativeTnsBrand', brands, (err, res) ->
            err && console.log err

    'refreshCreative': (cnmb) ->
        c = getCreative cnmb
        Creatives._collection.update { CreativeNmb: cnmb }, { $set: c }

    # Retrieve all CreativeInfo objects from Yandex BannerStore for all
    # creatives in Creatives collection and upsert them into
    # Creatives collection
    'refreshCreatives': ->
        # Scan Creatives collection, get list of CreativeNmb
        creativeNmbs = _.pluck(
            Creatives.find(
                {},
                { fields: { CreativeNmb: 1 } }
            ).fetch(),
            'CreativeNmb'
        )

        # For each number retrieve CreativeInfo object from Yandex BannerStore
        # and upsert it into Creatives collection using $set (to keep
        # 'TemplateNmb' property)
        _.each creativeNmbs, (n) ->
            c = getCreative n
            Creatives._collection.upsert(
                { CreativeNmb: c.CreativeNmb },
                { $set: c }
            )
        return

    # Retrieve all CreativeInfo objects from Yandex BannerStore by tag
    # and upsert them into Creatives collection
    'refreshCreativesByTag': (tag) ->
        # Retrieve array of CreativeInfo objects from Yandex BannerStore
        cArray = getCreative tag

        # Upsert each CreativeInfo object into Creatives collection
        _.each cArray, (c) ->
            Creatives._collection.upsert(
                { CreativeNmb: c.CreativeNmb },
                { $set : c }
            )
        return

    # Upload file to Yandex BannerStore, get its number,
    # retrieve FileInfo object and store it into Files collection
    'uploadToBSAndRefreshFile': (fileId) ->
        fileNmb = uploadFileToBS fileId
        FilesFS.update fileId, { $set: { "metadata.FileNmb": fileNmb } }
        file = methodCallSync 'GetFileByNmb', fileNmb
        delete file.Data # do not store base64 file Data in mongo
        Files._collection.upsert { FileNmb: file.FileNmb }, file

        return

    # Retrieve all FileInfo objects from Yandex BannerStore for all files
    # in GridFS and store them into Files collection
    'refreshFiles': ->

        # Scan GridFS and extract BannerStoreNmb from metadata properties
        fileNmbs = _.map(
            FilesFS.find({}, { fields: { "metadata.FileNmb": 1 } }).fetch(),
            (f) ->
                if f.metadata?.FileNmb then f.metadata.FileNmb else null
        )
        fileNmbs = _.filter fileNmbs, (n) -> !!n

        # Retrieve FileInfo object for each file number and store it into Files
        # collection
        _.each fileNmbs, (n) ->
            file = methodCallSync 'GetFileByNmb', n
            Files._collection.upsert { FileNmb: file.FileNmb }, file

        return

    'refreshFilesByTag': (tag) ->
        console.log "Refreshing Files from Yandex BannerStore By Tag: #{tag}"

        console.log '  downloading...'
        list = methodCallSync 'GetFileByTag', tag

        console.log '  upserting and storing content into GridFS...'
        _.each list, (file) ->
            Files.upsert { FileNmb: file.FileNmb }, file
            if !FilesFS.find({ "metadata.FileNmb": file.FileNmb }).count()
                FilesFS.storeBuffer file.FileName, file.Data,
                    contentType: getContentType file.MimeTypeNmb
                    noProgress: true
                    metadata:
                        FileNmb: file.FileNmb

        console.log 'Done'

    'getCreativeMacros': (nmb) ->
        return getCreativeMacros nmb

    'refreshCreativeMacros': refreshCreativeMacros

    'updateCreativeMacros': updateCreativeMacros

    'updateCreativeDynamicMacros': updateCreativeDynamicMacros

    # Absolutely non-multiuser safe. Use with care!!!
    'recreateDictionaries': ->
        console.log 'Recreating Yandex BannerStore Dictionaries'
        for k, v of Dictionaries
            console.log 'Dictionary:', k
            console.log '  erasing...'
            v.coll.remove {}
            v.coll._ensureIndex 'Nmb', { unique: 1, sparse: 1 }
            v.coll._ensureIndex 'Name', { sparse: 1 }
            console.log '  downloading...'
            list = dictMethodCallSync v.method
            console.log '  storing...'
            _.each list, (elem) ->
                v.coll.insert elem
        console.log 'Done'

    # Absolutely non-multiuser safe. Use with care!!!
    'recreateDictionary': (d) ->
        console.log 'Recreating Yandex BannerStore Dictionary'
        v = Dictionaries[d]
        if v
            console.log 'Dictionary:', d
            console.log '  erasing...'
            v.coll.remove {}
            v.coll._ensureIndex 'Nmb', { unique: 1, sparse: 1 }
            v.coll._ensureIndex 'Name', { sparse: 1 }
            console.log '  downloading...'
            list = dictMethodCallSync v.method
            console.log '  storing...'
            _.each list, (elem) ->
                v.coll.insert elem
        console.log 'Done'

    'refreshDictionaries': ->
        console.log 'Refreshing Yandex BannerStore Dictionaries'
        for k, v of Dictionaries
            console.log 'Dictionary:', k
            console.log '  downloading...'
            list = dictMethodCallSync v.method
            console.log '  upserting...'
            _.each list, (elem) ->
                v.coll.upsert { Nmb: elem.Nmb }, elem
        console.log 'Done'

    'requestCreativeModeration': (cnmb) ->
        methodCallSync 'RequestCreativeModeration', { CreativeNmb: cnmb }

    'requestCreativeEdit': (cnmb) ->
        methodCallSync 'RequestCreativeEdit', { CreativeNmb: cnmb }


Meteor.startup ->
    AccountsEntry.config
        signupCode: 'freshcocoa153'

