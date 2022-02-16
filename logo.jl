import IterTools: product as ×

import Term: Segment

function make_circle(style, r=24)
    mag(x) = sqrt((x[1] * .72)^2 + (x[2]*.95)^2)

    p = collect(1:r)
    points = collect(p × p)
    
    line = " "^(r*2)
    circle = [line for i in 1:r]

    for point in points
        shifted = [point[1]-r/2, point[2]-r/2]
        if mag(shifted) < (r/2)-4
            x, y = point
            line = circle[y]
            ln = line[1:x-1] * "X" * line[x+1:end]
            circle[y] = ln
        end
    end
    # return join(circle, "\n")
    return Segment(join(circle, "\n"), style)
end

print("\n\n\n")
circle = make_circle("bold red")
print(circle)

