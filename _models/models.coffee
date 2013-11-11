@RTBTemplate = new Meteor.Collection 'template'
@Macros = new Meteor.Collection 'macros'
@Files = new Meteor.Collection 'files'
@FilesFS = new CollectionFS 'files'

@Creatives = new Meteor.Collection2 'creatives',
    schema:
        CreativeNmb:
            type: Number
            label: 'Creative Number'
        CreativeName:
            type: String
            label: 'Creative Name'
            max: 200
        TnsAdvertiserNmb:
            type: Number
            label: 'TNS Advertiser'
        TemplateNmb:
            type: Number
            label: 'Template'
        ExpireDate:
            type: Date
            label: 'Expires At'
        Tag:
            type: String
            label: 'Tag'
            max: 200
        Note:
            type: String
            label: 'Note'
            max: 1024
            optional: true
        TemplateData:
            type: String
            label: 'Code fragment with unexpanded macros'
            optional: true
        Data:
            type: String
            label: 'Code fragment with expanded macros'
            optional: true
        IsDeployed:
            type: Boolean
            label: 'Direct links to media files are available'
            optional: true
        Token:
            type: String
            label: 'Digital signature'
            optional: true
        Properties:
            type: String
            label: 'Auction properties'
            optional: true
        Moderation:
            type: Object
            optional: true
        'Moderation.StatusNmb':
            type: Number
            label: 'Moderation status'
            optional: true
        'Moderation.ModeratedDate':
            type: Date
            label: 'Date and time of last moderation response'
            optional: true
        'Moderation.Message':
            type: String
            label: 'Last message from moderator'
            optional: true
        'Moderation.RequestDate':
            type: Date
            label: 'Date and time of last moderation request'
            optional: true
        'Moderation.Log':
            type: [Object]
            optional: true
        'Moderation.Log.Date':
            type: Date
            label: 'Date and time of moderation'
            optional: true
        'Moderation.Log.StatusNmb':
            type: Number
            label: 'Moderation status'
            optional: true
        'Moderation.Log.Message':
            type: String
            label: 'Message from moderator'
            optional: true