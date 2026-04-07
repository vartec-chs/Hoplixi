# Метаинформации, атрибуты для ресурса

## Yandex Disk API

Добавление метаинформации для ресурса Для любого файла или папки, доступной на
запись, можно задать дополнительные произвольные атрибуты. Эти атрибуты будут
возвращаться в ответ на все запросы метаинформации о ресурсах (список всех
файлов, последние загруженные и т. д.).

Формат запроса Запрос добавления метаинформации следует отправлять с помощью
метода PATCH.

https://cloud-api.yandex.net/v1/disk/resources/ ? path=<путь к ресурсу> &
[fields=<свойства, которые нужно включить в ответ>]

Описание query-параметров path\* Путь к нужному ресурсу относительно корневого
каталога Диска. Путь к ресурсу в Корзине следует указывать относительно
корневого каталога Корзины.

Путь в значении параметра следует кодировать в URL-формате.

fields Список свойств JSON, которые следует включить в ответ. Ключи, не
указанные в этом списке, будут отброшены при составлении ответа. Если параметр
не указан, ответ возвращается полностью, без сокращений.

Имена ключей следует указывать через запятую, а вложенные ключи разделять
точками. Например: name,\_embedded.items.path.

- Обязательный параметр.

Заголовок Authorization: OAuth <token> Content-Type: application/json

Тело запроса Добавляемые атрибуты следует передавать в теле запроса, в свойствах
объекта custom_properties (можно передавать любые части объекта Resource, но все
кроме custom_properties будет проигнорировано). Атрибуты могут быть только
свойствами вида имя:значение и, соответственно, не могут быть массивами или
родительскими объектами.

Ограничение

Ограничение на длину объекта custom_properties (имена и значения вложенных
ключей, а также синтаксические знаки) — 1024 символа.

Переданные атрибуты добавляются к уже имеющимся. Например, передается следующий
объект, с атрибутами foo и bar:

"custom_properties": {"foo":"1", "bar":"2"}

Если до этого в метаинформации ресурса не было объекта custom_properties, API
просто добавит к ней переданный объект.

Если же такой объект уже имеется (например, "custom_properties": {"oof":"3",
"bar":"0"}), API обновит ключи с совпадающими именами и добавит новые. В
метаинформации ресурса можно будет видеть такой объект:

"custom_properties": {"oof": "3", "bar":"0", "foo":"1"}

Чтобы удалить какой-либо атрибут, следует передать его со значением null,
например:

"custom_properties": {"foo": null}

Формат ответа Если запрос был обработан без ошибок, API отвечает кодом 200 OK и
возвращает метаинформацию о запрошенном ресурсе в теле ответа в объекте
Resource.

Если запрос вызвал ошибку, возвращается подходящий код ответа, а тело ответа
содержит описание ошибки.

Для непустых папок в ответ включается объект ResourceList (под именем
\_embedded). Каждый вложенный в папку ресурс является элементом массива
items.Вне зависимости от запрошенной сортировки, ресурсы в массиве упорядочены
по их виду: сначала перечисляются все вложенные папки, затем — вложенные файлы.

{ "public_key": "HQsmHLoeyBlJf8Eu1jlmzuU+ZaLkjPkgcvmokRUCIo8=", "\_embedded": {
"sort": "", "path": "disk:/foo", "items": [ { "path": "disk:/foo/bar", "type":
"dir", "name": "bar", "modified": "2014-04-22T10:32:49+04:00", "created":
"2014-04-22T10:32:49+04:00" }, { "name": "photo.png", "preview":
"https://downloader.disk.yandex.ru/preview/...", "created":
"2014-04-21T14:57:13+04:00", "modified": "2014-04-21T14:57:14+04:00", "path":
"disk:/foo/photo.png", "md5": "4334dc6379c8f95ddf11b9508cfea271", "type":
"file", "mime_type": "image/png", "size": 34567 } ], "limit": 20, "offset": 0 },
"name": "foo", "created": "2014-04-21T14:54:42+04:00", "custom_properties":
{"foo":"1", "bar":"2"}, "public_url": "https://yadi.sk/d/AaaBbb1122Ccc",
"modified": "2014-04-22T10:32:49+04:00", "path": "disk:/foo", "type": "dir" }

Описание элементов ответа

Элемент

Описание

public_key

Ключ опубликованного ресурса.

Включается в ответ только если указанный файл или папка опубликован.

public_url

Ссылка на опубликованный ресурс.

Включается в ответ только если указанный файл или папка опубликован.

\_embedded

Ресурсы, непосредственно содержащиеся в папке (содержит объект ResourceList).

Включается в ответ только при запросе метаинформации о папке.

preview

Ссылка на уменьшенное изображение из файла (превью). Включается в ответ только
для файлов поддерживаемых графических форматов.

Запросить превью можно только с OAuth-токеном пользователя, имеющего доступ к
самому файлу.

name

Имя ресурса.

custom_properties

Объект со всеми атрибутами, заданными с помощью запроса Добавление
метаинформации для ресурса. Содержит только ключи вида имя:значение (объекты или
массивы содержать не может).

created

Дата и время создания ресурса, в формате ISO 8601.

modified

Дата и время изменения ресурса, в формате ISO 8601.

path

Полный путь к ресурсу на Диске.

В метаинформации опубликованной папки пути указываются относительно самой папки.
Для опубликованных файлов значение ключа всегда «/».

Для ресурса, находящегося в Корзине, к атрибуту может быть добавлен уникальный
идентификатор (например, trash:/foo_1408546879). С помощью этого идентификатора
ресурс можно отличить от других удаленных ресурсов с тем же именем.

origin_path

Путь к ресурсу до перемещения в Корзину.

Включается в ответ только для запроса метаинформации о ресурсе в Корзине.

md5

MD5-хэш файла.

type

Тип ресурса:

«dir» — папка; «file» — файл. mime_type

MIME-тип файла.

size

Размер файла. Элемент Описание sort Поле, по которому отсортирован список.
public_key Ключ опубликованной папки, в которой содержатся ресурсы из данного
списка. Включается только в ответ на запрос метаинформации о публичной папке.
items Массив ресурсов (Resource), содержащихся в папке. Вне зависимости от
запрошенной сортировки, ресурсы в массиве упорядочены по их виду: сначала
перечисляются все вложенные папки, затем — вложенные файлы. limit Максимальное
количество элементов в массиве items, заданное в запросе. offset Смещение начала
списка от первого ресурса в папке. path Путь к папке, чье содержимое описывается
в данном объекте ResourceList. Для публичной папки значение атрибута всегда
равно «/». total Общее количество ресурсов в папке.

## Google Drive API

Добавить пользовательские свойства файла

Пользовательские свойства файла — это пары «ключ-значение», используемые для
хранения пользовательских метаданных для файла Google Drive (например, тегов),
идентификаторов из других хранилищ данных, информации, передаваемой между
приложениями рабочих процессов, и так далее. Например, вы можете добавить
свойства файла ко всем документам, созданным отделом продаж в первом квартале.

Чтобы добавить свойства, видимые для всех приложений, используйте поле
properties ресурса files . Чтобы добавить свойства, доступные только вашему
приложению, используйте поле appProperties ресурса files .

Примечание: Если вы используете более старую версию Google Drive API (v2),
используйте ресурс properties для добавления свойств в ваше приложение с помощью
properties.insert . Полный список различий между версиями см. в справочнике
сравнения Drive API v2 и v3 . Свойства также могут использоваться в поисковых
выражениях .

Это структура типичного свойства, которое может использоваться для хранения
идентификатора файла в базе данных Google Диска.

Drive API v3 Drive API v2

"appProperties": { "additionalID": "ID", } Работа с пользовательскими свойствами
файлов В этом разделе объясняется, как выполнять некоторые задачи, связанные с
пользовательскими свойствами файлов, которые затрагивают все приложения.

Примечание: В пользовательском интерфейсе Google Drive отсутствует встроенная
функция редактирования пользовательских свойств. Добавление или обновление
пользовательских свойств файла Чтобы добавить или обновить свойства, видимые
всем приложениям, используйте метод files.update для установки поля properties
ресурса files .

PATCH https://www.googleapis.com/drive/v3/files/FILE_ID

{ "properties": { "name": "wrench", "mass": "1.3kg", "count": "3" } } Вы также
можете добавить пользовательское свойство к файлу, используя расширенные
возможности службы Google Drive в Google Apps Script. Для получения
дополнительной информации см. раздел «Добавление пользовательских свойств» .

Получить или перечислить свойства пользовательского файла Чтобы просмотреть
свойства, видимые всем приложениям, используйте метод files.get для получения
пользовательских свойств файла.

GET https://www.googleapis.com/drive/v3/files/FILE_ID?fields=properties В ответе
содержится объект properties , включающий набор пар ключ-значение.

{ "properties": { "name": "wrench", "mass": "1.3kg", "count": "3" } } Удаление
пользовательских свойств файла Чтобы удалить значения свойств, видимые всем
приложениям, используйте метод files.update для установки значения поля
properties ресурса files в null.

PATCH https://www.googleapis.com/drive/v3/files/FILE_ID

{ "name": null } Чтобы увидеть изменения, вызовите метод files.get для получения
объекта properties файла.

{ "properties": { "mass": "1.3kg", "count": "3" } } Ограничения на использование
пользовательских свойств файлов Для пользовательских свойств установлены
следующие ограничения:

Максимальное количество пользовательских свойств в одном файле — 100,
суммированное количество — из всех источников. Максимальное количество
общедоступных объектов в одном файле — 30, суммированное количество — из всех
источников. В одном файле одного приложения может быть не более 30 частных
объектов недвижимости. В кодировке UTF-8 максимальный размер строки свойства
(включая ключ и значение) составляет 124 байта. Например, свойство с ключом
длиной 10 символов может содержать в значении не более 114 символов. Аналогично,
свойство, для значения которого требуется 100 символов, может использовать до 24
символов для ключа. Для получения дополнительной информации см. ресурс files .
Для Drive API v2 см. ресурс properties .

Доступ к закрытым пользовательским свойствам файла Получить доступ к закрытым
свойствам можно только через поле appProperties с помощью аутентифицированного
запроса, использующего токен доступа, полученный с помощью идентификатора
клиента OAuth 2.0. Использование ключа API для получения закрытых свойств
невозможно.

## Dropbox API

file_properties /properties/add Version

1

Description Add property groups to a Dropbox file.

This endpoint does not support apps with the app folder permission.

URL Structure https://api.dropboxapi.com/2/file_properties/properties/add
Authentication User Authentication Endpoint format RPC Required Scope
files.metadata.write Example Get access token for: Hoplixi curl -X POST
https://api.dropboxapi.com/2/file_properties/properties/add \
 --header "Authorization: Bearer <get access token>" \
 --header "Content-Type: application/json" \
 --data
"{\"path\":\"/my*awesome/word.docx\",\"property_groups\":[{\"fields\":[{\"name\":\"Security
Policy\",\"value\":\"Confidential\"}],\"template_id\":\"ptid:1a5n2i6d3OYEAAAAAAAAAYa\"}]}"
Parameters { "path": "/my_awesome/word.docx", "property_groups": [ { "fields": [
{ "name": "Security Policy", "value": "Confidential" } ], "template_id":
"ptid:1a5n2i6d3OYEAAAAAAAAAYa" } ] } AddPropertiesArg
pathString(pattern="/(.|[\r\n])*|id:._|(ns:[0-9]+(/._)?)")A unique identifier
for the file or folder. property*groupsList of (PropertyGroup)The property
groups which are to be added to a Dropbox file. No two groups in the input
should refer to the same template. Returns No return values. Errors Example:
restricted_content { "error": { ".tag": "restricted_content" }, "error_summary":
"restricted_content/..." } Example: other { "error": { ".tag": "other" },
"error_summary": "other/..." } Example: unsupported_folder { "error": { ".tag":
"unsupported_folder" }, "error_summary": "unsupported_folder/..." } Example:
property_field_too_large { "error": { ".tag": "property_field_too_large" },
"error_summary": "property_field_too_large/..." } Example: does_not_fit_template
{ "error": { ".tag": "does_not_fit_template" }, "error_summary":
"does_not_fit_template/..." } Example: duplicate_property_groups { "error": {
".tag": "duplicate_property_groups" }, "error_summary":
"duplicate_property_groups/..." } Example: property_group_already_exists {
"error": { ".tag": "property_group_already_exists" }, "error_summary":
"property_group_already_exists/..." } AddPropertiesError (union)
template_not_foundString(min_length=1, pattern="(/|ptid:).*")Template does not
exist for the given identifier. restricted_contentVoidYou do not have permission
to modify this template. pathLookupError unsupported_folderVoidThis folder
cannot be tagged. Tagging folders is not supported for team-owned templates.
property_field_too_largeVoidOne or more of the supplied property field values is
too large. does_not_fit_templateVoidOne or more of the supplied property fields
does not conform to the template specifications.
duplicate_property_groupsVoidThere are 2 or more property groups referring to
the same templates in the input. property_group_already_existsVoidA property
group associated with this template and file already exists. See also general
errors. /properties/overwrite Version

1

Description Overwrite property groups associated with a file.

This endpoint does not support apps with the app folder permission.

URL Structure https://api.dropboxapi.com/2/file_properties/properties/overwrite
Authentication User Authentication Endpoint format RPC Required Scope
files.metadata.write Example Get access token for: Hoplixi curl -X POST
https://api.dropboxapi.com/2/file_properties/properties/overwrite \
 --header "Authorization: Bearer <get access token>" \
 --header "Content-Type: application/json" \
 --data
"{\"path\":\"/my*awesome/word.docx\",\"property_groups\":[{\"fields\":[{\"name\":\"Security
Policy\",\"value\":\"Confidential\"}],\"template_id\":\"ptid:1a5n2i6d3OYEAAAAAAAAAYa\"}]}"
Parameters { "path": "/my_awesome/word.docx", "property_groups": [ { "fields": [
{ "name": "Security Policy", "value": "Confidential" } ], "template_id":
"ptid:1a5n2i6d3OYEAAAAAAAAAYa" } ] } OverwritePropertyGroupArg
pathString(pattern="/(.|[\r\n])*|id:._|(ns:[0-9]+(/._)?)")A unique identifier
for the file or folder. property*groupsList of (PropertyGroup, min_items=1)The
property groups "snapshot" updates to force apply. No two groups in the input
should refer to the same template. Returns No return values. Errors Example:
restricted_content { "error": { ".tag": "restricted_content" }, "error_summary":
"restricted_content/..." } Example: other { "error": { ".tag": "other" },
"error_summary": "other/..." } Example: unsupported_folder { "error": { ".tag":
"unsupported_folder" }, "error_summary": "unsupported_folder/..." } Example:
property_field_too_large { "error": { ".tag": "property_field_too_large" },
"error_summary": "property_field_too_large/..." } Example: does_not_fit_template
{ "error": { ".tag": "does_not_fit_template" }, "error_summary":
"does_not_fit_template/..." } Example: duplicate_property_groups { "error": {
".tag": "duplicate_property_groups" }, "error_summary":
"duplicate_property_groups/..." } InvalidPropertyGroupError (union)
template_not_foundString(min_length=1, pattern="(/|ptid:).*")Template does not
exist for the given identifier. restricted_contentVoidYou do not have permission
to modify this template. pathLookupError unsupported_folderVoidThis folder
cannot be tagged. Tagging folders is not supported for team-owned templates.
property_field_too_largeVoidOne or more of the supplied property field values is
too large. does_not_fit_templateVoidOne or more of the supplied property fields
does not conform to the template specifications.
duplicate_property_groupsVoidThere are 2 or more property groups referring to
the same templates in the input. See also general errors. /properties/remove
Version

1

Description Permanently removes the specified property group from the file.

This endpoint does not support apps with the app folder permission.

URL Structure https://api.dropboxapi.com/2/file_properties/properties/remove
Authentication User Authentication Endpoint format RPC Required Scope
files.metadata.write Example Get access token for: Hoplixi curl -X POST
https://api.dropboxapi.com/2/file_properties/properties/remove \
 --header "Authorization: Bearer <get access token>" \
 --header "Content-Type: application/json" \
 --data
"{\"path\":\"/my*awesome/word.docx\",\"property_template_ids\":[\"ptid:1a5n2i6d3OYEAAAAAAAAAYa\"]}"
Parameters { "path": "/my_awesome/word.docx", "property_template_ids": [
"ptid:1a5n2i6d3OYEAAAAAAAAAYa" ] } RemovePropertiesArg
pathString(pattern="/(.|[\r\n])*|id:._|(ns:[0-9]+(/._)?)")A unique identifier
for the file or folder. property*template_ids List of (String(min_length=1,
pattern="(/|ptid:).*"))A list of identifiers for a template created by
templates/add_for_user or templates/add_for_team. Returns No return values.
Errors Example: restricted_content { "error": { ".tag": "restricted_content" },
"error_summary": "restricted_content/..." } Example: other { "error": { ".tag":
"other" }, "error_summary": "other/..." } Example: unsupported_folder { "error":
{ ".tag": "unsupported_folder" }, "error_summary": "unsupported_folder/..." }
RemovePropertiesError (union) template_not_foundString(min_length=1,
pattern="(/|ptid:).\*")Template does not exist for the given identifier.
restricted_contentVoidYou do not have permission to modify this template.
pathLookupError unsupported_folderVoidThis folder cannot be tagged. Tagging
folders is not supported for team-owned templates.
property_group_lookupLookUpPropertiesError See also general errors.
/properties/search Version

1

Description Search across property templates for particular property field
values.

This endpoint does not support apps with the app folder permission.

URL Structure https://api.dropboxapi.com/2/file_properties/properties/search
Authentication User Authentication Endpoint format RPC Required Scope
files.metadata.read Example Get access token for: Hoplixi curl -X POST
https://api.dropboxapi.com/2/file_properties/properties/search \
 --header "Authorization: Bearer <get access token>" \
 --header "Content-Type: application/json" \
 --data
"{\"queries\":[{\"logical_operator\":\"or_operator\",\"mode\":{\".tag\":\"field_name\",\"field_name\":\"Security\"},\"query\":\"Confidential\"}],\"template_filter\":\"filter_none\"}"
Parameters { "queries": [ { "logical_operator": "or_operator", "mode": { ".tag":
"field_name", "field_name": "Security" }, "query": "Confidential" } ],
"template_filter": "filter_none" } PropertiesSearchArg queriesList of
(PropertiesSearchQuery, min_items=1)Queries to search.
template_filterTemplateFilterFilter results to contain only properties
associated with these template IDs. The default for this union is filter_none.
Returns { "matches": [ { "id": "id:a4ayc_80_OEAAAAAAAAAXz", "is_deleted": false,
"path": "/my_awesome/word.docx", "property_groups": [ { "fields": [ { "name":
"Security Policy", "value": "Confidential" } ], "template_id":
"ptid:1a5n2i6d3OYEAAAAAAAAAYa" } ] } ] } PropertiesSearchResult matchesList of
(PropertiesSearchMatch)A list (possibly empty) of matches for the query. cursor
String(min_length=1)?Pass the cursor into properties/search/continue to continue
to receive search results. Cursor will be null when there are no more results.
This field is optional. Errors PropertiesSearchError (open union)
property_group_lookupLookUpPropertiesError See also general errors.
/properties/search/continue Version

1

Description Paginate through search results.

This endpoint does not support apps with the app folder permission.

URL Structure
https://api.dropboxapi.com/2/file_properties/properties/search/continue
Authentication User Authentication Endpoint format RPC Required Scope
files.metadata.read Example Get access token for: Hoplixi curl -X POST
https://api.dropboxapi.com/2/file_properties/properties/search/continue \
 --header "Authorization: Bearer <get access token>" \
 --header "Content-Type: application/json" \
 --data "{\"cursor\":\"ZtkX9_EHj3x7PMkVuFIhwKYXEpwpLwyxp9vMKomUhllil9q7eWiAu\"}"
Parameters { "cursor": "ZtkX9_EHj3x7PMkVuFIhwKYXEpwpLwyxp9vMKomUhllil9q7eWiAu" }
PropertiesSearchContinueArg cursorString(min_length=1)The cursor returned by
your last call to properties/search or properties/search/continue. Returns {
"matches": [ { "id": "id:a4ayc_80_OEAAAAAAAAAXz", "is_deleted": false, "path":
"/my_awesome/word.docx", "property_groups": [ { "fields": [ { "name": "Security
Policy", "value": "Confidential" } ], "template_id":
"ptid:1a5n2i6d3OYEAAAAAAAAAYa" } ] } ] } PropertiesSearchResult matchesList of
(PropertiesSearchMatch)A list (possibly empty) of matches for the query. cursor
String(min_length=1)?Pass the cursor into properties/search/continue to continue
to receive search results. Cursor will be null when there are no more results.
This field is optional. Errors Example: reset { "error": { ".tag": "reset" },
"error_summary": "reset/..." } Example: other { "error": { ".tag": "other" },
"error_summary": "other/..." } PropertiesSearchContinueError (open union)
resetVoidIndicates that the cursor has been invalidated. Call properties/search
to obtain a new cursor. See also general errors. /properties/update Version

1

Description Add, update or remove properties associated with the supplied file
and templates.

This endpoint does not support apps with the app folder permission.

URL Structure https://api.dropboxapi.com/2/file_properties/properties/update
Authentication User Authentication Endpoint format RPC Required Scope
files.metadata.write Example Get access token for: Hoplixi curl -X POST
https://api.dropboxapi.com/2/file_properties/properties/update \
 --header "Authorization: Bearer <get access token>" \
 --header "Content-Type: application/json" \
 --data
"{\"path\":\"/my*awesome/word.docx\",\"update_property_groups\":[{\"add_or_update_fields\":[{\"name\":\"Security
Policy\",\"value\":\"Confidential\"}],\"remove_fields\":[],\"template_id\":\"ptid:1a5n2i6d3OYEAAAAAAAAAYa\"}]}"
Parameters { "path": "/my_awesome/word.docx", "update_property_groups": [ {
"add_or_update_fields": [ { "name": "Security Policy", "value": "Confidential" }
], "remove_fields": [], "template_id": "ptid:1a5n2i6d3OYEAAAAAAAAAYa" } ] }
UpdatePropertiesArg pathString(pattern="/(.|[\r\n])*|id:._|(ns:[0-9]+(/._)?)")A
unique identifier for the file or folder. update*property_groupsList of
(PropertyGroupUpdate)The property groups "delta" updates to apply. Returns No
return values. Errors Example: restricted_content { "error": { ".tag":
"restricted_content" }, "error_summary": "restricted_content/..." } Example:
other { "error": { ".tag": "other" }, "error_summary": "other/..." } Example:
unsupported_folder { "error": { ".tag": "unsupported_folder" }, "error_summary":
"unsupported_folder/..." } Example: property_field_too_large { "error": {
".tag": "property_field_too_large" }, "error_summary":
"property_field_too_large/..." } Example: does_not_fit_template { "error": {
".tag": "does_not_fit_template" }, "error_summary": "does_not_fit_template/..."
} Example: duplicate_property_groups { "error": { ".tag":
"duplicate_property_groups" }, "error_summary": "duplicate_property_groups/..."
} UpdatePropertiesError (union) template_not_foundString(min_length=1,
pattern="(/|ptid:).*")Template does not exist for the given identifier.
restricted_contentVoidYou do not have permission to modify this template.
pathLookupError unsupported_folderVoidThis folder cannot be tagged. Tagging
folders is not supported for team-owned templates.
property_field_too_largeVoidOne or more of the supplied property field values is
too large. does_not_fit_templateVoidOne or more of the supplied property fields
does not conform to the template specifications.
duplicate_property_groupsVoidThere are 2 or more property groups referring to
the same templates in the input. property_group_lookupLookUpPropertiesError See
also general errors.

## OneDrive API

Open Extensions (рекомендуется)

Самый близкий аналог кастомных атрибутов.

Позволяет добавлять свои поля к объектам (например, файлам).

📌 Пример POST /me/drive/items/{item-id}/extensions Content-Type:
application/json

{ "@odata.type": "microsoft.graph.openTypeExtension", "extensionName":
"com.yourapp.metadata", "customField1": "value1", "customField2": 123 } 📥
Получение: GET /me/drive/items/{item-id}/extensions
