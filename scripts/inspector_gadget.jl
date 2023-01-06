modules(m::Module) = ccall(:jl_module_usings, Any, (Any,), m)

"""
Write some function to define all functions and types in a module an submodules.
    And a "search" function
"""
