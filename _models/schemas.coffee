@Schema = {}

@Schema.basicDetails = new SimpleSchema
    CreativeName:
        type: String
        label: 'Creative name'
        max: 200
    TnsAdvertiserNmb:
        type: Number
        label: 'Advertiser'
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