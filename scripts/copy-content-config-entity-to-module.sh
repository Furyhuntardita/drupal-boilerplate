#!/bin/bash
#######################################
#  Copy a content config entity to a
#  given module, along with its view
#  modes, form displays, fields and
#  field storages.
#
#  Receive 3 required parameters:
#  - Entity type: paragraphs,
#  block_content, node or taxonomy
#  - Entity bundle
#  - Module name: where to copy the
#  configuration. The module should
#  exist.
#
#######################################

set -e

ENTITY_TYPE=$1
BUNDLE=$2
MODULE=$3

source ./scripts/copy-config-to-module.sh

function show_help {
cat << EOF
 Copy a content config entity, its fields, view modes and form display into a existing module.
 Usage: ./scripts/copy-config-to-module.sh ENTITY_TYPE BUNDLE MODULE_NAME

 Example:
  ./scripts/copy-config-to-module.sh paragraphs wysiwyg radix_ui_components_wysiwyg
EOF
}

if [ "$#" -ne 3 ]; then
    echo "Illegal number of parameters"
    show_help
fi

case $ENTITY_TYPE in
  paragraphs)
    BUNDLE_KEY="paragraphs_type"
    FIELD_PREFIX="paragraph"
    ;;
  block_content)
    BUNDLE_KEY="block"
    FIELD_PREFIX=$ENTITY_TYPE
    ;;
  node)
    BUNDLE_KEY="type"
    FIELD_PREFIX=$ENTITY_TYPE
    ;;
  taxonomy)
    BUNDLE_KEY="vocabulary"
    FIELD_PREFIX=$ENTITY_TYPE
    ;;
  *)
    echo "$ENTITY_TYPE is not supported. Supported entity types are paragraphs, block_content, node and taxonomy."
    show_help
    exit 1
    ;;
esac

ENTITY="$ENTITY_TYPE.$BUNDLE_KEY.$BUNDLE"

MODULE_DIR=$(find . -name $MODULE.info.yml | xargs dirname)
MODULE_DIR="$MODULE_DIR/config/install"
mkdir -p $MODULE_DIR

copy_config $ENTITY.yml $MODULE_DIR

# Get entities naming the current entity.
DEPENDANT_ENTITIES=( $(grep $ENTITY config/default/* \
  | cut -d: -f1 \
  | xargs -l basename \
  | egrep 'core.entity_form_display|core.entity_view_display|field.field') )

# Check for feld storage config entities.
for CONFIG in "${DEPENDANT_ENTITIES[@]}"
do

  copy_config $CONFIG $MODULE_DIR

  if [[ $CONFIG == field\.field\.* ]]
  then
    FIELD_NAME=$(echo $CONFIG | cut -d. -f5)
    FIELD_CONFIG_STORAGE="field.storage.$FIELD_PREFIX.$FIELD_NAME.yml"

    copy_config $FIELD_CONFIG_STORAGE $MODULE_DIR
  fi
done
