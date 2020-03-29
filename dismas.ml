#!/usr/bin/env ocaml

(*
 * Copyright (C) 2020 Daniil Baturin <daniil at baturin dot org>
 *
 * Permission is hereby granted, free of charge,
 * to any person obtaining a copy of this software
 * and associated documentation files (the "Software"),
 * to deal in the Software without restriction,
 * including without limitation the rights to use,
 * copy, modify, merge, publish, distribute, sublicense,
 * and/or sell copies of the Software, and to permit persons
 * to whom the Software is furnished to do so, subject
 * to the following conditions:
 *
 * The above copyright notice and this permission notice
 * shall be included in all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 * EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 * OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
 * IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
 * DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
 * TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE
 * OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 *
 * Synopsis: automatically makes cross-versions of OCaml packages
 *)


#use "topfind";;
#require "opam-file-format";;

open OpamParserTypes


(* Some constraints, notably {with-test} and {with-doc} make no sense for cross-versions of packages
   since running tests of cross-compiled libraries is generally impossible,
   and docs are better left to native versions. *)

let useless_targets = ["with-doc"; "with-test"]

let in_list x xs =
  let res = List.find_opt ((=) x) xs in
  match res with
  | None -> false
  | _ -> true

let rec is_useless_target opt =
  match opt with
  | Ident (_, i) -> in_list i useless_targets
  | Logop (_, _, l, r) -> (is_useless_target l) || (is_useless_target r)
  | _ -> false

let has_useless_target opts =
  let res = List.find_opt is_useless_target opts in
  match res with
  | None -> false
  | _ -> true

(* One thing we need to fix is build commands.

   The first thing to fix is the command used to build the package.
   That involves adding a cross-toolchain option and replacing metavariables.
 *)

(* If a list starts with "dune", it must be a dune command. *)
let is_dune_command opts =
  match opts with
  | String (_, "dune") :: _ -> true
  | _ -> false

(* Fixing the dune build command.

   For cross-versions, ["dune", "-p", name] doesn't work because the opam package name is
   $package-$target (e.g. frobnicate-windows), while dune package name stays the same.
   We have to hardcode the package name instead.

   Positions get messed up, but it shouldn't matter.
*)
let rec fix_dune_package_name package opts =
  match opts with
  | [] -> []
  | String (pos1, "-p") :: Ident (pos2, "name") :: ds' ->
    String (pos1, "-p") :: String (pos2, package) :: ds'
  | opt :: opts' -> opt :: (fix_dune_package_name package opts')

(* Fix the build section.

   We need to
     1. Adjust the build commands to take the cross-toolchain into account
     2. Remove useless targets like {with-test} and {with-doc} that make no sense for cross-versions
 *)
let rec fix_build_section target package bopts =
  match bopts with
  | [] -> []
  | (List (pos, opts)) :: bopts' ->
    if (is_dune_command opts) then
      (* Dune supports explicit toolchain option (-x $target), so we need to fix the package name
         and add that option.

         Positions for the new options are completely fake, but since the formatter ignores them,
         it shouldn't be a problem.
       *)
      (List (pos, (List.append (fix_dune_package_name package opts) [String (pos, "-x"); String (pos, target)])) ::
        (fix_build_section target package bopts'))
    else (List (pos, opts)) :: (fix_build_section target package bopts')
  | (Option (pos, opts, constraints) as bopt) :: bopts' ->
    if (has_useless_target constraints) then (fix_build_section target package bopts')
    else bopt :: (fix_build_section target package bopts')
  | bopt :: bopts' -> bopt :: (fix_build_section target package bopts')
  

(* Next step is fixing dependencies.

   Most of the time, a cross-version of a package requires cross-versions of all its dependencies,
   though in some cases both native and cross-version are needed.

   We also remove dependencies that are only needed for build targets like {with-doc} and {with-test}.
 *)

(* Build tools are always native and do not have cross-versions.
   Thus build tool dependencies should never be rewritten. *)
let no_cross_deps = ["dune"; "dune-configurator"; "ocamlbuild"; "oasis"; "ocamlfind"]

let make_cross_dep target dep =
  if not (in_list dep no_cross_deps) then Printf.sprintf "%s-%s" dep target
  else dep

let rec fix_dependencies target deps =
  match deps with
  | [] -> []
  | (String (pos, dep)) :: deps ->
    (String (pos, make_cross_dep target dep)) :: (fix_dependencies target deps)
  | (Option (pos1, (String (pos2, dep)), constraints)) :: deps ->
    if has_useless_target constraints then fix_dependencies target deps
    else (Option (pos1, (String (pos2, make_cross_dep target dep)), constraints)) :: (fix_dependencies target deps)
  | dep :: deps' -> dep :: fix_dependencies target deps

let rec apply_fixes target package opts =
  match opts with
  | [] -> []
  | Variable (pos1, "build", (List (pos2, bs))) :: opts' ->
    (Variable (pos1, "build", (List (pos2, fix_build_section target package bs)))) :: apply_fixes target package opts'
  | Variable (pos1, "depends", (List (pos2, ds))) :: opts' ->
    (Variable (pos1, "depends", (List (pos2, fix_dependencies target ds)))) :: apply_fixes target package opts'
  | opt :: opts' -> opt :: apply_fixes target package opts'

let fix_opam_file target package opam_file =
  let new_contents = apply_fixes target package opam_file.file_contents in
  OpamPrinter.opamfile {opam_file with file_contents=new_contents}

let () =
  let target = Sys.argv.(1) in
  let package = Sys.argv.(2) in
  let file = Sys.argv.(3) in
  let opam_file = OpamParser.file file in
  let new_file = fix_opam_file target package opam_file in
  print_endline new_file
