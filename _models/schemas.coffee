@Schema = {}

@Schema.newCreative = new SimpleSchema
    CreativeName:
        type: String
        label: 'Название креатива'
        max: 200
    TnsAdvertiserNmb:
        type: Number
        label: 'Идентификатор рекламодателя'
    TemplateNmb:
        type: Number
        label: 'Идентификатор шаблона'
    ExpireDate:
        type: Date
        label: 'Момент экспирации'
    Tag:
        type: String
        label: 'Метка креатива'
        max: 200
    Note:
        type: String
        label: 'Произвольное описание креатива'
        max: 1024