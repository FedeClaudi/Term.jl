using Revise
Revise.revise()

using Term
import Term: AbstractRenderable
import Term: install_stacktrace

install_stacktrace()

# ------------------------------- inspect types ------------------------------ #
inspect(Panel)
inspect(AbstractRenderable;)
inspect(String;)

# ----------------------------- inspect variables ---------------------------- #
inspect("test")
inspect(1)

# ------------------------------ inspect methods ----------------------------- #
# inspect(print)
inspect(inspect)
