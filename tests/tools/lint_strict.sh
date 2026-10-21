#!/usr/bin/env bash
# Strict GDScript check: temporarily turns typing / unsafe / unused warnings
# into errors (override.cfg) and parses every project script outside addons/.
# Exit 1 on any finding. Usage: tests/tools/lint_strict.sh [godot-binary]
set -u
GODOT="${1:-godot}"
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
cd "$ROOT"
if [ -e override.cfg ]; then echo "override.cfg already exists, aborting"; exit 2; fi
cat > override.cfg <<'CFG'
[debug]
gdscript/warnings/untyped_declaration=2
gdscript/warnings/unused_variable=2
gdscript/warnings/unused_parameter=2
gdscript/warnings/unused_local_constant=2
gdscript/warnings/shadowed_variable=2
gdscript/warnings/shadowed_variable_base_class=2
gdscript/warnings/shadowed_global_identifier=2
gdscript/warnings/unsafe_call_argument=2
gdscript/warnings/unsafe_method_access=2
gdscript/warnings/unsafe_property_access=2
gdscript/warnings/unsafe_cast=2
gdscript/warnings/inference_on_variant=2
gdscript/warnings/integer_division=2
gdscript/warnings/narrowing_conversion=2
gdscript/warnings/unreachable_code=2
gdscript/warnings/standalone_expression=2
gdscript/warnings/incompatible_ternary=2
gdscript/warnings/static_called_on_instance=2
gdscript/warnings/confusable_local_declaration=2
gdscript/warnings/confusable_local_usage=2
gdscript/warnings/int_as_enum_without_cast=2
gdscript/warnings/int_as_enum_without_match=2
gdscript/warnings/enum_variable_without_default=2
gdscript/warnings/unassigned_variable=2
gdscript/warnings/unassigned_variable_op_assign=2
CFG
trap 'rm -f "$ROOT/override.cfg"' EXIT
status=0
while IFS= read -r f; do
  out=$("$GODOT" --headless --path . --check-only -s "res://$f" 2>&1 | grep -vE '^Godot Engine|^$')
  if [ -n "$out" ]; then echo "== $f"; echo "$out"; status=1; fi
done < <(find scripts tests -name '*.gd' | sort)
[ $status -eq 0 ] && echo "lint_strict: OK"
exit $status
