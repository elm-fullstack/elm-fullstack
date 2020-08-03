module EvaluateElmTests exposing (..)

import ElmEvaluation
import Expect
import Test


suite : Test.Test
suite =
    Test.describe "Elm evaluation"
        [ Test.test "Just a literal" <|
            \_ ->
                Expect.equal (Ok { valueAsJsonString = "\"just a literal ✔️\"", typeText = "String" })
                    (ElmEvaluation.evaluateExpressionStringWithoutModules """  "just a literal ✔️"  """)
        , Test.test "Concat string literal" <|
            \_ ->
                Expect.equal (Ok { valueAsJsonString = "\"first literal  second literal ✔️\"", typeText = "String" })
                    (ElmEvaluation.evaluateExpressionStringWithoutModules """  "first literal "  ++  " second literal ✔️"  """)
        , Test.test "Concat string via let" <|
            \_ ->
                Expect.equal (Ok { valueAsJsonString = "\"literal from let  second literal ✔️\"", typeText = "String" })
                    (ElmEvaluation.evaluateExpressionStringWithoutModules """
let
    binding_from_let =
        "literal from let "
in
binding_from_let ++ " second literal ✔️"
""")
        , Test.test "Dependency within let" <|
            \_ ->
                Expect.equal (Ok { valueAsJsonString = "\"literal\"", typeText = "String" })
                    (ElmEvaluation.evaluateExpressionStringWithoutModules """
let
    a = "literal"

    b = a
in
b
""")
        , Test.test "Support any order in let" <|
            \_ ->
                Expect.equal (Ok { valueAsJsonString = "\"literal\"", typeText = "String" })
                    (ElmEvaluation.evaluateExpressionStringWithoutModules """
let
    d = c

    a = "literal"

    c = b

    b = a
in
d
""")
        , Test.test "Value from module-level binding" <|
            \_ ->
                Expect.equal (Ok { valueAsJsonString = "\"literal\"", typeText = "String" })
                    (ElmEvaluation.evaluateExpressionString
                        [ """
module ModuleName exposing (module_level_binding)


module_level_binding : String
module_level_binding =
    "literal"

"""
                        ]
                        "ModuleName.module_level_binding"
                    )
        , Test.test "Concat string via module level function" <|
            \_ ->
                Expect.equal (Ok { valueAsJsonString = "\"literal from module  second literal ✔️\"", typeText = "String" })
                    (ElmEvaluation.evaluateExpressionString
                        [ """
module ModuleName exposing (module_level_binding)


module_level_binding : String -> String
module_level_binding param0 =
    "literal from module " ++ param0


""" ]
                        "ModuleName.module_level_binding \" second literal ✔️\""
                    )
        , Test.test "Depend on binding in current module" <|
            \_ ->
                Expect.equal (Ok { valueAsJsonString = "\"literal from module\"", typeText = "String" })
                    (ElmEvaluation.evaluateExpressionString
                        [ """
module ModuleName exposing (module_level_binding)


module_level_binding =
    other_module_level_binding


other_module_level_binding =
    "literal from module"

""" ]
                        "ModuleName.module_level_binding"
                    )
        , Test.test "Function with two named parameters" <|
            \_ ->
                Expect.equal (Ok { valueAsJsonString = "\"literal from module ab\"", typeText = "String" })
                    (ElmEvaluation.evaluateExpressionString
                        [ """
module ModuleName exposing (module_level_binding)


module_level_binding param0 param1 =
    "literal from module " ++ param0 ++ param1

""" ]
                        "ModuleName.module_level_binding  \"a\"  \"b\""
                    )
        , Test.test "Partial application" <|
            \_ ->
                Expect.equal (Ok { valueAsJsonString = "\"literal from module ab\"", typeText = "String" })
                    (ElmEvaluation.evaluateExpressionString
                        [ """
module ModuleName exposing (partially_applied_a)


partially_applied_a =
    function_with_two_parameters "a"


function_with_two_parameters param0 param1 =
    "literal from module " ++ param0 ++ param1

""" ]
                        "ModuleName.partially_applied_a \"b\""
                    )
        , Test.test "Partial application via multiple modules" <|
            \_ ->
                Expect.equal (Ok { valueAsJsonString = "\"a b c\"", typeText = "String" })
                    (ElmEvaluation.evaluateExpressionString
                        [ """
module ModuleA exposing (partially_applied_a)


partially_applied_a =
    function_with_three_parameters "a"


function_with_three_parameters param0 param1 param2 =
    param0 ++ " " ++ param1 ++ " " ++ param2

""", """
module ModuleB exposing (partially_applied_b)


partially_applied_b =
    ModuleA.partially_applied_a "b"


function_with_three_parameters param0 param1 param2 =
    param0 ++ " " ++ param1 ++ " " ++ param2

""" ]
                        "ModuleB.partially_applied_b \"c\""
                    )
        , Test.test "Literal List String" <|
            \_ ->
                Expect.equal (Ok { valueAsJsonString = """["a","b"]""", typeText = "List String" })
                    (ElmEvaluation.evaluateExpressionString
                        []
                        """ [ "a", "b" ] """
                    )
        , Test.test "Concat List String" <|
            \_ ->
                Expect.equal (Ok { valueAsJsonString = """["a","b","c"]""", typeText = "List String" })
                    (ElmEvaluation.evaluateExpressionString
                        []
                        """ [ "a", "b" ] ++ [ "c" ] """
                    )
        , Test.test "Literal Int" <|
            \_ ->
                Expect.equal (Ok { valueAsJsonString = "123", typeText = "Int" })
                    (ElmEvaluation.evaluateExpressionString
                        []
                        """ 123 """
                    )
        , Test.test "Add Int" <|
            \_ ->
                Expect.equal (Ok { valueAsJsonString = "18", typeText = "Int" })
                    (ElmEvaluation.evaluateExpressionString
                        []
                        """ 13 + 5 """
                    )
        , Test.test "Subtract Int" <|
            \_ ->
                Expect.equal (Ok { valueAsJsonString = "13", typeText = "Int" })
                    (ElmEvaluation.evaluateExpressionString
                        []
                        """ 16 - 3 """
                    )
        , Test.test "Multiply Int" <|
            \_ ->
                Expect.equal (Ok { valueAsJsonString = "15", typeText = "Int" })
                    (ElmEvaluation.evaluateExpressionString
                        []
                        """ 3 * 5 """
                    )
        , Test.test "Divide Int" <|
            \_ ->
                Expect.equal (Ok { valueAsJsonString = "4", typeText = "Int" })
                    (ElmEvaluation.evaluateExpressionString
                        []
                        """ 17 // 4 """
                    )
        , Test.test "Parentheses override operator associativity" <|
            \_ ->
                Expect.equal (Ok { valueAsJsonString = "12", typeText = "Int" })
                    (ElmEvaluation.evaluateExpressionString
                        []
                        """ (1 + 2) * (3 + 1) """
                    )
        ]
