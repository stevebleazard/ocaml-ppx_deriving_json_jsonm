[@@deriving jsonm]
===================

_deriving jsonm_ is a [ppx_deriving][pd] plugin that generates
[JSON][] serializers and deserializes that use the [jsonm][] library
from an OCaml type definition.

[pd]: https://github.com/whitequark/ppx_deriving
[json]: http://tools.ietf.org/html/rfc4627
[jsonm]: http://mjambon.com/jsonm.html

Installation
------------

_deriving jsonm_ can be installed via [OPAM](https://opam.ocaml.org):

    $ opam install ppx_deriving_json_jsonm

Usage
-----

In order to use _deriving jsonm_, require the package `ppx_deriving_json_jsonm`.

Syntax
------

_deriving jsonm_ generates three functions per type:

``` ocaml
# #require "ppx_deriving";;
# type ty = .. [@@deriving jsonm];;
val ty_of_jsonm : Json_of_jsonm_lib.Json_string.t -> (ty, string) Result.result
val ty_of_jsonm_exn : Json_of_jsonm_lib.Json_string.t -> ty
val ty_to_jsonm : ty -> Json_of_jsonm_lib.Json_string.t
```

When the deserializing function returns <code>\`Error loc</code>, `loc` points to the point in the JSON hierarchy where the error has occurred.

It is possible to generate only serializing or deserializing functions by using `[@@deriving to_jsonm]` or `[@@deriving of_jsonm]`. It is also possible to generate an expression for serializing or deserializing a type by using `[%to_jsonm:]` or `[%of_jsonm:]`; non-conflicting versions `[%derive.to_jsonm:]` or `[%derive.of_jsonm:]` are available as well.

If the type is called `t`, the functions generated are `{of,to}_jsonm` instead of `t_{of,to}_jsonm`.

The `ty_of_jsonm_exn` function raises `Failure err` on error instead of returning an `'a or_error`

Semantics
---------

_deriving jsonm_ handles tuples, records, normal and polymorphic variants; builtin types: `int`, `int32`, `int64`, `nativeint`, `float`, `bool`, `char`, `string`, `bytes`, `ref`, `list`, `array`, `option` and their `Mod.t` aliases.

The following table summarizes the correspondence between OCaml types and JSON values:

| OCaml type                            | JSON value | Remarks                          |
| ------------------------------------- | ---------- | -------------------------------- |
| `int`, `int32`, `float`               | Number     |                                  |
| `int64`, `nativeint`                  | Number     | Can exceed range of `double`     |
| `bool`                                | Boolean    |                                  |
| `string`, `bytes`                     | String     |                                  |
| `char`                                | String     | Strictly one character in length |
| `list`, `array`                       | Array      |                                  |
| `ref`                                 | 'a         |                                  |
| `option`                              | Null or 'a |                                  |
| A record                              | Object     |                                  |
| `Json_of_jsonm_lib.Json_string.t`     | any        | Identity transformation          |

Variants (regular and polymorphic) are represented using arrays; the first element is a string with the name of the constructor, the rest are the arguments. Note that the implicit tuple in a polymorphic variant is flattened. For example:

``` ocaml
# type pvs = [ `A | `B of int | `C of int * string ] list [@@deriving jsonm];;
# type v = A | B of int | C of int * string [@@deriving jsonm];;
# type vs = v list [@@deriving jsonm];;
# print_endline (Json_of_jsonm_lib.Json_string.to_string (vs_to_jsonm [A; B 42; C (42, "foo")]));;
[["A"],["B",42],["C",42,"foo"]]
# print_endline (Json_of_jsonm_lib.Json_string.to_string (pvs_to_jsonm [`A; `B 42; `C (42, "foo")]));;
[["A"],["B",42],["C",42,"foo"]]
```

Record variants are represented in the same way as if the nested structure was defined separately. For example:

```ocaml
# type v = X of { v: int } [@@deriving jsonm];;
# print_endline (Json_of_jsonm_lib.Json_string.to_string (v_to_jsonm (X { v = 0 })));;
["X",{"v":0}]
```

Record variants are currently not supported for extensible variant types.

By default, objects are deserialized strictly; that is, all keys in the object have to correspond to fields of the record. Passing `strict = false` as an option to the deriver  (i.e. `[@@deriving jsonm { strict = false }]`) changes the behavior to ignore any unknown fields.

#### Optional fields module
Sometimes a list of JSON key names is useful, especially when using the `[@key ...]` feature (see the options section).
This is supported via the `fields` deriver option,  eg. `[@@deriving jsonm { fields = true }]`.
When enabled the `Yosjon_fields_ty` module is created containing the value `keys` which as a `string list` of JSON keys.
Note that if `ty` is `t` then the module is called `Yosjon_fields` instead

### Options

Option attribute names may be prefixed with `jsonm.` to avoid conflicts with other derivers.

#### [@key]

If the JSON object keys differ from OCaml conventions, lexical or otherwise, it is possible to specify the corresponding JSON key implicitly using <code>[@key "field"]</code>, e.g.:

``` ocaml
type geo = {
  lat : float [@key "Latitude"];
  lon : float [@key "Longitude"];
}
[@@deriving jsonm]
```

#### [@name]

If the JSON variant names differ from OCaml conventions, it is possible to specify the corresponding JSON string explicitly using <code>[@name "constr"]</code>, e.g.:

``` ocaml
type units =
| Metric   [@name "metric"]
| Imperial [@name "imperial"]
[@@deriving jsonm]
```

#### [@encoding]

Very large `int64` and `nativeint` numbers can wrap when decoded in a runtime which represents all numbers using double-precision floating point, e.g. JavaScript and Lua. It is possible to specify the <code>[@encoding \`string]</code> attribute to encode them as strings.

#### [@default]

It is possible to specify a default value for fields that can be missing from the JSON object, e.g.:

``` ocaml
type pagination = {
  pages   : int;
  current : (int [@default 0]);
} [@@deriving jsonm]
```

Fields with default values are not required to be present in inputs and will not be emitted in outputs.

License
-------

_deriving jsonm_ is distributed under the terms of [MIT license](LICENSE.txt).
