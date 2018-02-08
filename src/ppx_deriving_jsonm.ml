open Longident
open Location
open Asttypes
open Parsetree
open Ast_helper
open Ast_convenience
module P = Ppx_deriving_json_lib.Ppx_deriving_json

module Jsonm_deriver : P.Json_deriver = struct
  let name = "jsonm"
  let suffix_to = "to_jsonm"
  let suffix_of = "of_jsonm"
  let value_type = [%type: Json_of_jsonm_lib.Json_string.t]
  let is_value_type = function
    | [%type: Json_of_jsonm_lib.Json_string.t] -> true
    | _ -> false
  let runtime_module = "Ppx_deriving_json_lib_runtime"
  let fields_module = "Json_fields"
  let encode_float_function _attrs =
    [%expr fun x -> `Float x]
  let encode_integer_as_float to_float _attrs =
    [%expr fun x -> `Float ([%e to_float] x)]
  let encode_int_function =
    encode_integer_as_float [%expr float_of_int]
  let encode_int32_function =
    encode_integer_as_float [%expr Int32.to_float]
  let encode_int64_function =
    encode_integer_as_float [%expr Int64.to_float]
  let encode_nativeint_function =
    encode_integer_as_float [%expr Nativeint.to_float]
  let decode_float_function _attrs =
    [[%pat? `Float x], [%expr Result.Ok x]]
  let decode_integer_from_float of_float _attrs =
    [[%pat? `Float x], [%expr Result.Ok ([%e of_float] x)]]
  let decode_int_function =
    decode_integer_from_float [%expr int_of_float]
  let decode_int32_function =
    decode_integer_from_float [%expr Int32.of_float]
  let decode_int64_function =
    decode_integer_from_float [%expr Int64.of_float]
  let decode_nativeint_function =
    decode_integer_from_float [%expr NativeInt.of_float]
end

include P.Register (Jsonm_deriver)
