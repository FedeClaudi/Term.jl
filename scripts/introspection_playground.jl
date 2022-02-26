using Revise
Revise.revise()

using Term
import Term: AbstractRenderable

# ------------------------------- inspect types ------------------------------ #
# inspect(Panel; max_n_methods=2) 
# inspect(AbstractRenderable)
# println("inspect(Number)")
# inspect(String)

# ----------------------------- inspect variables ---------------------------- #
# inspect("test")
# inspect(1)


# ------------------------------ inspect methods ----------------------------- #
inspect(print)