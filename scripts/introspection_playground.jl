using Revise
Revise.revise()

using Term
import Term: AbstractRenderable

# ------------------------------- inspect types ------------------------------ #
# inspect(Panel) 
# inspect(AbstractRenderable;)
# inspect(String;)

# ----------------------------- inspect variables ---------------------------- #
# inspect("test")
# inspect(1)

# ------------------------------ inspect methods ----------------------------- #
# inspect(print)
inspect(inspect; width=100)