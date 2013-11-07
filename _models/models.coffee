@RTBTemplate = new Meteor.Collection 'template'
@Macros = new Meteor.Collection 'macros'
@Files = new Meteor.Collection 'files'
@FilesFS = new CollectionFS 'files'

@Creatives = new Meteor.Collection2 'creatives',
    schema:
        CreativeNmb:
            type: Number
            label: 'Номер креатива'
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
            label: 'Метка кретива'
            max: 200
        Note:
            type: String
            label: 'Произвольное описание креатива'
            max: 1024
            optional: true
        TemplateData:
            type: String
            label: 'Фрагмент кода с нераскрытыми макросами'
            optional: true
        Data:
            type: String
            label: 'Фрагмент кода с раскрытыми макросами'
            optional: true
        IsDeployed:
            type: Boolean
            label: 'Медиафайлы доступны по прямым ссылкам'
            optional: true
        Token:
            type: String
            label: 'Цифровая подпись для участия в аукционе'
            optional: true
        Properties:
            type: String
            label: 'Строка для участия в аукционе'
            optional: true
        Moderation:
            type: Object
            optional: true
        'Moderation.StatusNmb':
            type: Number
            label: 'Результат проверки креатива'
            optional: true
        'Moderation.ModeratedDate':
            type: Date
            label: 'Дата и время проверки'
            optional: true
        'Moderation.Message':
            type: String
            label: 'Сообщение от модератора'
            optional: true
        'Moderation.RequestDate':
            type: Date
            label: 'Дата и время отправки креатива на проверку'
            optional: true
        'Moderation.Log':
            type: [Object]
            optional: true
        'Moderation.Log.Date':
            type: Date
            label: 'Дата и время проверки'
            optional: true
        'Moderation.Log.StatusNmb':
            type: Number
            label: 'Результат проверки креатива'
            optional: true
        'Moderation.Log.Message':
            type: String
            label: 'Сообщение от модератора'
            optional: true