using Revise
Revise.revise()

using Term
import Term: AbstractRenderable

# ------------------------------- inspect types ------------------------------ #
# inspect(Panel) 
# inspect(AbstractRenderable;)
# inspect(String; width=300)

# ----------------------------- inspect variables ---------------------------- #
# inspect("test")
# inspect(1)

# ------------------------------ inspect methods ----------------------------- #
inspect(print)