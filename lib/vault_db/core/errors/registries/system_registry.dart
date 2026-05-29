import '../../scheme/tables/system/categories/categories.dart';
import '../../scheme/tables/system/item_link/item_links.dart';
import '../../scheme/tables/system/tags/tags.dart';
import '../db_constraint_descriptor.dart';

final Map<String, DbConstraintDescriptor> systemRegistry = {
  // --- Categories ---
  CategoryConstraint.idNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_categories_id_not_blank',
    entity: 'category',
    table: 'categories',
    field: 'id',
    code: 'category.id.not_blank',
    message: 'ID категории не может быть пустым',
  ),
  CategoryConstraint.nameNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_categories_name_not_blank',
    entity: 'category',
    table: 'categories',
    field: 'name',
    code: 'category.name.not_blank',
    message: 'Название категории не может быть пустым',
  ),
  CategoryConstraint
      .nameNoOuterWhitespace
      .constraintName: const DbConstraintDescriptor(
    constraint: 'chk_categories_name_no_outer_whitespace',
    entity: 'category',
    table: 'categories',
    field: 'name',
    code: 'category.name.no_outer_whitespace',
    message:
        'Название категории не должно начинаться или заканчиваться пробелами',
  ),

  CategoryConstraint.parentIdNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_categories_parent_id_not_blank',
        entity: 'category',
        table: 'categories',
        field: 'parentId',
        code: 'category.parent_id.not_blank',
        message: 'ID родительской категории не может быть пустым',
      ),

  CategoryConstraint.colorRange.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_categories_color_range',
    entity: 'category',
    table: 'categories',
    field: 'color',
    code: 'category.color.range',
    message: 'Цвет должен быть в допустимом диапазоне',
  ),
  CategoryConstraint.iconRefIdNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_categories_icon_ref_id_not_blank',
        entity: 'category',
        table: 'categories',
        field: 'iconRefId',
        code: 'category.icon_ref_id.not_blank',
        message: 'ID иконки не может быть пустым',
      ),
  CategoryConstraint.noSelfParent.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_categories_no_self_parent',
    entity: 'category',
    table: 'categories',
    field: 'parentId',
    code: 'category.no_self_parent',
    message: 'Категория не может быть своим собственным родителем',
  ),

  // --- Tags ---
  TagConstraint.idNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_tags_id_not_blank',
    entity: 'tag',
    table: 'tags',
    field: 'id',
    code: 'tag.id.not_blank',
    message: 'ID тега не может быть пустым',
  ),
  TagConstraint.nameNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_tags_name_not_blank',
    entity: 'tag',
    table: 'tags',
    field: 'name',
    code: 'tag.name.not_blank',
    message: 'Название тега не может быть пустым',
  ),
  TagConstraint
      .nameNoOuterWhitespace
      .constraintName: const DbConstraintDescriptor(
    constraint: 'chk_tags_name_no_outer_whitespace',
    entity: 'tag',
    table: 'tags',
    field: 'name',
    code: 'tag.name.no_outer_whitespace',
    message: 'Название тега не должно начинаться или заканчиваться пробелами',
  ),
  TagConstraint.colorRange.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_tags_color_range',
    entity: 'tag',
    table: 'tags',
    field: 'color',
    code: 'tag.color.range',
    message: 'Цвет тега должен быть в допустимом диапазоне',
  ),

  // --- Item Links ---
  ItemLinkConstraint.idNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_item_links_id_not_blank',
    entity: 'itemLink',
    table: 'item_links',
    field: 'id',
    code: 'item_link.id.not_blank',
    message: 'ID связи не может быть пустым',
  ),
  ItemLinkConstraint.sourceItemIdNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_item_links_source_item_id_not_blank',
        entity: 'itemLink',
        table: 'item_links',
        field: 'sourceItemId',
        code: 'item_link.source_id.not_blank',
        message: 'ID источника не может быть пустым',
      ),
  ItemLinkConstraint.targetItemIdNotBlank.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_item_links_target_item_id_not_blank',
        entity: 'itemLink',
        table: 'item_links',
        field: 'targetItemId',
        code: 'item_link.target_id.not_blank',
        message: 'ID цели не может быть пустым',
      ),
  ItemLinkConstraint.noSelfLink.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_item_links_no_self_link',
    entity: 'itemLink',
    table: 'item_links',
    field: 'targetItemId',
    code: 'item_link.no_self_link',
    message: 'Нельзя связать запись саму с собой',
  ),
  ItemLinkConstraint.relationTypeOtherRequired.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_item_links_relation_type_other_required',
        entity: 'itemLink',
        table: 'item_links',
        field: 'relationTypeOther',
        code: 'item_link.relation_type_other.required',
        message: 'Укажите свой тип связи',
      ),
  ItemLinkConstraint.relationTypeOtherMustBeNull.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_item_links_relation_type_other_must_be_null',
        entity: 'itemLink',
        table: 'item_links',
        field: 'relationTypeOther',
        code: 'item_link.relation_type_other.must_be_null',
        message: 'Свой тип связи можно указывать только для значения other',
      ),
  ItemLinkConstraint.labelNotBlank.constraintName: const DbConstraintDescriptor(
    constraint: 'chk_item_links_label_not_blank',
    entity: 'itemLink',
    table: 'item_links',
    field: 'label',
    code: 'item_link.label.not_blank',
    message: 'Метка не может состоять из одних пробелов',
  ),
  ItemLinkConstraint.sortOrderNonNegative.constraintName:
      const DbConstraintDescriptor(
        constraint: 'chk_item_links_sort_order_non_negative',
        entity: 'itemLink',
        table: 'item_links',
        field: 'sortOrder',
        code: 'item_link.sort_order.negative',
        message: 'Порядок сортировки не может быть отрицательным',
      ),
};
