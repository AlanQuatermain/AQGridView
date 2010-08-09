#!/bin/bash

PNG_HEADER="${DERIVED_FILES_DIR}/AQGridViewCell_png.h"

rm -f "${PNG_HEADER}"
mkdir -p "${DERIVED_FILES_DIR}"

cd Resources
for png in *; do
	xxd -i "$png" >> "${PNG_HEADER}"
done
